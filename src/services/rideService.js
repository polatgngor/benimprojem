const { Ride, RideRequest, RideMessage, Rating, User, UserDevice, Driver, Wallet, WalletTransaction, sequelize } = require('../models');
const { rideTimeoutQueue } = require('../queues/rideTimeoutQueue');
const { Op } = require('sequelize');
const { emitRideRequest } = require('./matchService');
const { getPassengerRadiusKmByLevel } = require('./levelService');
const { getRouteDistanceMeters, computeFareEstimate } = require('./fareService');
const { assignRideAtomic } = require('./assignService');
const { sendPushToTokens } = require('../lib/fcm');
const socketProvider = require('../lib/socketProvider');
const Redis = require('ioredis');

// Specific Redis instance or reuse one execution context if passed?
// Ideally services should use a shared redis client or create their own.
// Since we used 'ioredis' directly in controller, let's use the one from utils if possible, or create new.
// The controller used:
// const redis = new Redis({ ...params });
// Let's use src/utils/redisClient.js to be consistent (Standardization!)
const redis = require('../utils/redisClient');

const { VEHICLE_TYPES } = require('../config/constants');

function generate4Code() {
    return Math.floor(1000 + Math.random() * 9000).toString();
}

function geoKeyForVehicle(vehicleType) {
    return `drivers:geo:${vehicleType}`;
}

/**
 * Service: Create a new ride
 */
async function createRide(payload) {
    const {
        userId,
        start_lat,
        start_lng,
        start_address,
        end_lat,
        end_lng,
        end_address,
        vehicle_type,
        options,
        payment_method
    } = payload;

    const validVehicleTypes = VEHICLE_TYPES || ['sari', 'turkuaz', 'siyah', '8+1'];
    if (!validVehicleTypes.includes(vehicle_type)) {
        throw new Error('Invalid vehicle_type');
    }

    const t = await sequelize.transaction();

    try {
        const code4 = generate4Code();
        let fare_estimate = null;
        let routeDetails = null;

        if (end_lat && end_lng) {
            try {
                routeDetails = await getRouteDistanceMeters(
                    start_lat,
                    start_lng,
                    end_lat,
                    end_lng
                );

                if (routeDetails) {
                    const { distanceMeters } = routeDetails;
                    if (distanceMeters != null) {
                        fare_estimate = computeFareEstimate(vehicle_type, distanceMeters);
                    }
                }
            } catch (e) {
                console.warn('[RideService] fare_estimate calculation failed:', e.message);
            }
        }

        const ride = await Ride.create({
            passenger_id: userId,
            start_lat,
            start_lng,
            start_address: start_address || null,
            end_lat: end_lat || null,
            end_lng: end_lng || null,
            end_address: end_address || null,
            vehicle_type,
            options: options || {},
            payment_method,
            status: 'requested',
            code4,
            fare_estimate
        }, { transaction: t });

        // Fetch Passenger for Level/Radius
        const passenger = await User.findByPk(userId, {
            attributes: ['id', 'first_name', 'last_name', 'phone', 'level'],
            transaction: t
        });

        if (!passenger) {
            throw new Error('Passenger not found');
        }

        const radiusKm = getPassengerRadiusKmByLevel(passenger.level || 1);
        const passenger_info = {
            id: passenger.id,
            first_name: passenger.first_name,
            last_name: passenger.last_name,
            phone: passenger.phone,
            level: passenger.level
        };

        await t.commit();

        // Async Match (Fire and Forget or Return status)
        // We return the ride immediately, but trigger matching.
        let sentDriversCount = 0;
        try {
            const sentList = await emitRideRequest(ride, {
                startLat: ride.start_lat,
                startLng: ride.start_lng,
                passenger_info,
                radiusKm,
                distanceMeters: routeDetails ? routeDetails.distanceMeters : null,
                durationSeconds: routeDetails ? routeDetails.durationSeconds : null,
                polyline: routeDetails ? routeDetails.polyline : null
            });
            sentDriversCount = sentList.length;
        } catch (msgErr) {
            console.error('[RideService] emitRideRequest failed', msgErr);
        }

        return { ride, sentDriversCount };

    } catch (err) {
        await t.rollback();
        throw err;
    }
}

/**
 * Service: Cancel a ride
 */
async function cancelRide(rideId, userId, userRole, reason) {
    const t = await sequelize.transaction();
    try {
        const ride = await Ride.findByPk(rideId, {
            transaction: t,
            lock: t.LOCK.UPDATE
        });

        if (!ride) throw new Error('Ride not found');

        if (!['requested', 'assigned', 'started'].includes(ride.status)) {
            throw new Error(`Cannot cancel ride in status ${ride.status}`);
        }

        // Role Check
        if (userRole === 'passenger' && Number(ride.passenger_id) !== Number(userId)) {
            throw new Error('Forbidden');
        }
        if (userRole === 'driver' && Number(ride.driver_id) !== Number(userId)) {
            throw new Error('Forbidden');
        }

        ride.status = 'cancelled';
        ride.cancel_reason = reason || null;
        await ride.save({ transaction: t });

        if (ride.driver_id) {
            await Driver.update(
                { is_available: true },
                { where: { user_id: ride.driver_id }, transaction: t }
            );
        }

        await t.commit();

        // Post-Cancel Async Logic
        handlePostCancel(ride, userId, userRole, reason).catch(err => {
            console.error('[RideService] Post-cancel actions failed', err);
        });

        return { success: true, rideId: ride.id };
    } catch (err) {
        await t.rollback();
        throw err;
    }
}

// Separate function for Side Effects (Redis, Notifications)
async function handlePostCancel(ride, actorId, actorRole, reason) {
    // 1. Reset Redis Availability
    if (ride.driver_id) {
        await redis.hset(`driver:${ride.driver_id}:meta`, 'available', '1');
    }

    // 2. Remove Timeout Job
    rideTimeoutQueue.remove(`ride_timeout_${ride.id}`).catch(() => { });

    // 3. Notifications
    const io = socketProvider.getIO();
    const roomName = `ride:${ride.id}`;

    // Initiator Notification (Self)
    const initiatorMeta = await redis.hgetall(`${actorRole === 'driver' ? 'driver' : 'user'}:${actorId}:meta`);
    if (initiatorMeta && initiatorMeta.socketId && io) {
        io.to(initiatorMeta.socketId).emit('ride:cancelled', { ride_id: ride.id, by: 'self', reason });
        const s = io.sockets.sockets.get(initiatorMeta.socketId);
        if (s) s.leave(roomName);
    }

    // Notify Pending Drivers
    if (ride.status === 'requested' || (ride.status === 'cancelled' && !ride.driver_id)) {
        const pending = await RideRequest.findAll({
            where: { ride_id: ride.id, driver_response: 'no_response' }
        });
        for (const req of pending) {
            io && io.to(`driver:${req.driver_id}`).emit('request:cancelled', { ride_id: ride.id });
        }
    }

    // Notify Other Party
    let targetUserId = null;
    let title = 'Yolculuk İptal Edildi';
    let body = '';

    if (actorRole === 'passenger') {
        targetUserId = ride.driver_id;
        body = 'Yolcu yolculuğu iptal etti.';
        // Notify driver
        if (targetUserId) {
            const driverMeta = await redis.hgetall(`driver:${targetUserId}:meta`);
            if (driverMeta && driverMeta.socketId && io) {
                io.to(driverMeta.socketId).emit('ride:cancelled', { ride_id: ride.id, by: 'passenger', reason });
                const s = io.sockets.sockets.get(driverMeta.socketId);
                if (s) s.leave(roomName);
            }
        }
    } else { // driver
        targetUserId = ride.passenger_id;
        body = 'Sürücü yolculuğu iptal etti.';
        // Notify passenger
        const passengerMeta = await redis.hgetall(`user:${targetUserId}:meta`);
        if (passengerMeta && passengerMeta.socketId && io) {
            io.to(passengerMeta.socketId).emit('ride:cancelled', { ride_id: ride.id, by: 'driver', reason });
            const s = io.sockets.sockets.get(passengerMeta.socketId);
            if (s) s.leave(roomName);
        }
    }

    // FCM
    if (targetUserId) {
        const devices = await UserDevice.findAll({ where: { user_id: targetUserId } });
        const tokens = devices.map(d => d.device_token);
        if (tokens.length > 0) {
            await sendPushToTokens(tokens, { title, body }, { type: 'ride_cancelled', ride_id: String(ride.id), reason: reason || '' });
        }
    }
}


/**
 * Service: Accept Ride request
 */
async function acceptRide(rideId, driverId) {
    // 1. Atomic DB Assign
    const result = await assignRideAtomic(rideId, driverId);
    if (!result.success) {
        throw new Error(result.error || 'Assign failed');
    }

    const ride = result.ride;

    // 2. Fetch Driver Info for Response
    const driverUser = await User.findByPk(driverId);
    const driverDetails = await Driver.findOne({ where: { user_id: driverId } });
    const driverRatings = await Rating.findAll({ where: { rated_id: driverId } });

    let driverRatingAvg = 5.0;
    if (driverRatings.length > 0) {
        driverRatingAvg = driverRatings.reduce((a, b) => a + b.stars, 0) / driverRatings.length;
    }

    const driverInfo = {
        id: driverId,
        first_name: driverUser.first_name,
        last_name: driverUser.last_name,
        phone: driverUser.phone,
        profile_picture: driverUser.profile_picture,
        profile_photo: driverUser.profile_picture,
        rating: parseFloat(driverRatingAvg.toFixed(1)),
        vehicle: {
            plate: driverDetails ? driverDetails.vehicle_plate : '',
            type: driverDetails ? driverDetails.vehicle_type : 'sari'
        }
    };

    // 3. Side Effects (Socket/FCM)
    // We can do this here or let Controller/Handler do it. Service doing it encapsulates logic better.
    const io = socketProvider.getIO();
    const room = `ride:${ride.id}`;

    if (io) {
        // Notify passenger
        const passengerMeta = await redis.hgetall(`user:${ride.passenger_id}:meta`);
        if (passengerMeta && passengerMeta.socketId) {
            io.to(passengerMeta.socketId).emit('ride:assigned', {
                ride_id: ride.id,
                driver: driverInfo,
                code4: ride.code4,
                eta: null // TODO: Calculate ETA
            });
            const ps = io.sockets.sockets.get(passengerMeta.socketId);
            if (ps) ps.join(room);
        }
    }

    // FCM
    try {
        const { censorName } = require('../utils/formatters');
        const devices = await UserDevice.findAll({ where: { user_id: ride.passenger_id } });
        const tokens = devices.map(d => d.device_token);
        if (tokens.length > 0) {
            const censoredDriverName = censorName(driverInfo.first_name, driverInfo.last_name);
            await sendPushToTokens(tokens,
                { title: 'Sürücü yola çıktı', body: `${censoredDriverName} kabul etti.` },
                { type: 'ride_assigned', ride_id: String(ride.id) }
            );
        }
    } catch (e) {
        console.error('[RideService] FCM accept failed', e);
    }

    return { ride, driverInfo };
}

/**
 * Service: Start Ride
 */
async function startRide(rideId, driverId, code) {
    const ride = await Ride.findByPk(rideId);
    if (!ride) throw new Error('Ride not found');

    if (String(ride.code4) !== String(code)) throw new Error('Invalid code');
    if (ride.status !== 'assigned') throw new Error('Ride not in assigned status');
    if (Number(ride.driver_id) !== Number(driverId)) throw new Error('Not your ride');

    ride.status = 'started';
    await ride.save();

    // Notify
    const io = socketProvider.getIO();
    if (io) {
        io.to(`ride:${ride.id}`).emit('ride:started', { ride_id: ride.id });
    }

    // FCM
    try {
        const devices = await UserDevice.findAll({ where: { user_id: ride.passenger_id } });
        const tokens = devices.map(d => d.device_token);
        if (tokens.length) {
            await sendPushToTokens(tokens, { title: 'Yolculuk Başladı', body: 'İyi yolculuklar!' }, { type: 'ride_started', ride_id: String(ride.id) });
        }
    } catch (e) { }

    return ride;
}

/**
 * Service: Complete Ride
 */
async function completeRide(rideId, driverId, fareActual) {
    const ride = await Ride.findByPk(rideId);
    if (!ride) throw new Error('Ride not found');
    if (ride.status !== 'started') throw new Error('Ride not started');
    if (Number(ride.driver_id) !== Number(driverId)) throw new Error('Not your ride');

    const estimate = parseFloat(ride.fare_estimate);
    const actual = parseFloat(fareActual);

    // Validate Fare
    if (!isNaN(estimate) && estimate > 0) {
        const minFare = estimate * 0.90;
        const maxFare = estimate * 1.25;
        if (actual < minFare || actual > maxFare) {
            throw new Error(`Fare out of range. Expected ${minFare.toFixed(2)} - ${maxFare.toFixed(2)}`);
        }
    } else {
        if (actual < 175 || actual > 50000) { // arbitrary limits from original code
            throw new Error('Fare out of reasonable range');
        }
    }

    ride.status = 'completed';
    ride.fare_actual = fareActual;

    // Persist Route
    try {
        const rawPoints = await redis.lrange(`ride:${ride.id}:route`, 0, -1);
        if (rawPoints.length) ride.actual_route = rawPoints.map(p => JSON.parse(p));
        await redis.del(`ride:${ride.id}:route`);
    } catch (e) { }

    await ride.save();

    // Wallet Logic
    let wallet = await Wallet.findOne({ where: { user_id: driverId } });
    if (!wallet) wallet = await Wallet.create({ user_id: driverId, balance: 0 });

    await wallet.update({
        balance: parseFloat(wallet.balance) + actual,
        total_earnings: parseFloat(wallet.total_earnings || 0) + actual
    });

    await WalletTransaction.create({
        wallet_id: wallet.id,
        amount: actual,
        type: 'ride_earnings',
        reference_id: ride.id,
        description: `Ride #${ride.id}`
    });

    // Restore Availability
    await Driver.update({ is_available: true }, { where: { user_id: driverId } });
    await redis.hset(`driver:${driverId}:meta`, 'available', '1');
    const meta = await redis.hgetall(`driver:${driverId}:meta`);

    if (meta.lat && meta.lng) {
        await redis.geoadd(geoKeyForVehicle(meta.vehicle_type || 'sari'), meta.lng, meta.lat, String(driverId));
    }

    // Notify
    const io = socketProvider.getIO();
    if (io) {
        io.to(`ride:${ride.id}`).emit('ride:completed', { ride_id: ride.id, fare_actual: actual });
    }

    return ride;
}

/**
 * Service: Rate Ride
 */
async function rateRide(ridingId, raterId, stars, comment) {
    if (!stars || stars < 1 || stars > 5) throw new Error('Invalid stars');

    const ride = await Ride.findByPk(ridingId);
    if (!ride) throw new Error('Ride not found');

    let ratedId = null;
    if (Number(raterId) === Number(ride.passenger_id)) {
        if (!ride.driver_id) throw new Error('No driver to rate');
        ratedId = ride.driver_id;
    } else if (Number(raterId) === Number(ride.driver_id)) {
        ratedId = ride.passenger_id;
    } else {
        throw new Error('Forbidden');
    }

    const rating = await Rating.create({
        ride_id: ride.id,
        rater_id: raterId,
        rated_id: ratedId,
        stars,
        comment: comment || null
    });

    return rating;
}

module.exports = {
    createRide,
    cancelRide,
    acceptRide,
    startRide,
    completeRide,
    rateRide
};
