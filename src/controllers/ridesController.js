const { Ride, RideRequest, RideMessage, Rating, User, UserDevice, Driver, sequelize } = require('../models');
const { rideTimeoutQueue } = require('../queues/rideTimeoutQueue');
const { Op } = require('sequelize');
const { emitRideRequest } = require('../services/matchService');
const { getPassengerRadiusKmByLevel } = require('../services/levelService');
const { getRouteDistanceMeters, computeFareEstimate } = require('../services/fareService');
const { sendPushToTokens } = require('../lib/fcm');
const socketProvider = require('../lib/socketProvider');
const Redis = require('ioredis');

// Shared Redis instance for the controller
const redis = new Redis({
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
  password: process.env.REDIS_PASSWORD || undefined
});

const { VEHICLE_TYPES } = require('../config/constants');

function generate4Code() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

/*
* POST /api/rides
* Ride oluşturma
*/
async function createRide(req, res) {
  const userId = req.user.userId;
  const {
    start_lat,
    start_lng,
    start_address,
    end_lat,
    end_lng,
    end_address,
    vehicle_type,
    options,
    payment_method
  } = req.body;

  // console.log('[createRide] vehicle_type payload:', vehicle_type);

  if (!start_lat || !start_lng || !vehicle_type || !payment_method) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const validVehicleTypes = VEHICLE_TYPES;
  if (!validVehicleTypes.includes(vehicle_type)) {
    return res.status(400).json({ message: 'Invalid vehicle_type' });
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
          const { distanceMeters, durationSeconds } = routeDetails;
          if (distanceMeters != null) {
            fare_estimate = computeFareEstimate(vehicle_type, distanceMeters);
          }
        }
      } catch (e) {
        console.warn('[createRide] fare_estimate hesaplanamadı:', e.message || e);
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

    // Passenger'ı çek, level'ine göre radius hesapla
    const passenger = await User.findByPk(userId, {
      attributes: ['id', 'first_name', 'last_name', 'phone', 'level'],
      transaction: t
    });

    if (!passenger) {
      await t.rollback();
      return res.status(404).json({ message: 'Passenger not found' });
    }

    const radiusKm = getPassengerRadiusKmByLevel(passenger.level || 1);

    const passenger_info = {
      id: passenger.id,
      first_name: passenger.first_name,
      last_name: passenger.last_name,
      phone: passenger.phone,
      level: passenger.level
    };

    // Commit the DB structure first so the Ride is visible to others
    await t.commit();

    // Non-blocking asynchronous tasks (Redis/FCM)
    // We run this AFTER commit because emitRideRequest might trigger listeners that query the DB.
    // If we run it before commit, they won't find the ride.
    // But we lose the "rollback if emit fails" guarantee.
    // Actually, emitRideRequest might write to Redis.
    // Valid Strategy: Commit first. If emit fails, we have a requested ride that no one sees. 
    // We should technically monitor this. For now, this is safer than locking forever.

    let sentDrivers = [];
    try {
      sentDrivers = await emitRideRequest(ride, {
        startLat: ride.start_lat,
        startLng: ride.start_lng,
        passenger_info,
        radiusKm,
        distanceMeters: routeDetails ? routeDetails.distanceMeters : null,
        durationSeconds: routeDetails ? routeDetails.durationSeconds : null,
        polyline: routeDetails ? routeDetails.polyline : null
      });
    } catch (emitErr) {
      console.error('Emit ride failed after commit', emitErr);
      // We could technically mark ride as 'failed' here if we wanted to be super robust.
    }

    return res.status(201).json({
      ride,
      code4,
      sentDriversCount: sentDrivers.length
    });
  } catch (err) {
    await t.rollback();
    console.error('createRide err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * POST /api/rides/estimate
 * Calculates fare estimates for all vehicle types
 */
async function estimateRide(req, res) {
  try {
    const { start_lat, start_lng, end_lat, end_lng } = req.body;

    if (!start_lat || !start_lng || !end_lat || !end_lng) {
      return res.status(400).json({ message: 'Missing coordinates' });
    }

    const routeDetails = await getRouteDistanceMeters(
      start_lat,
      start_lng,
      end_lat,
      end_lng
    );

    if (!routeDetails || routeDetails.distanceMeters == null) {
      return res.status(400).json({ message: 'Route could not be calculated' });
    }

    const { distanceMeters, durationSeconds } = routeDetails;

    // Calculate for all types
    const estimates = {};
    const types = VEHICLE_TYPES;

    types.forEach(type => {
      estimates[type] = computeFareEstimate(type, distanceMeters);
    });

    return res.json({
      distance_meters: distanceMeters,
      duration_seconds: durationSeconds,
      estimates
    });

  } catch (err) {
    console.error('estimateRide err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}


/**
 * GET /api/rides/:id
 * Sadece ride'ın passenger'ı, driver'ı veya admin görebilir
 */
async function getRide(req, res) {
  try {
    const user = req.user;
    const ride = await Ride.findByPk(req.params.id);
    if (!ride) return res.status(404).json({ message: 'Ride not found' });

    if (
      user.role !== 'admin' &&
      Number(ride.passenger_id) !== Number(user.userId) &&
      Number(ride.driver_id) !== Number(user.userId)
    ) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const { formatTurkeyDate } = require('../utils/dateUtils');
    const plain = ride.toJSON();
    plain.formatted_date = formatTurkeyDate(ride.created_at);

    return res.json({ ride: plain });
  } catch (err) {
    console.error('getRide err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * GET /api/rides (history)
 * Supports pagination and optional ?status=
 */
async function getRides(req, res) {
  try {
    const user = req.user;
    const page = parseInt(req.query.page || '1', 10);
    const limit = parseInt(req.query.limit || '20', 10);
    const offset = (page - 1) * limit;
    const where = {};

    if (user.role === 'passenger') where.passenger_id = user.userId;
    if (user.role === 'driver') where.driver_id = user.userId;
    if (req.query.status) where.status = req.query.status;

    const rides = await Ride.findAll({
      where,
      order: [['created_at', 'DESC']],
      limit,
      offset,
      // Removed raw: true due to crash. 
      // Sequelize raw mode with deep includes can be tricky or break virtual getters.
      include: [
        {
          model: User,
          as: 'passenger',
          attributes: ['id', 'first_name', 'last_name', 'profile_picture', 'level']
        },
        {
          model: User,
          as: 'driver',
          attributes: ['id', 'first_name', 'last_name', 'profile_picture', 'level'],
          include: [
            {
              model: Driver,
              as: 'driver',
              attributes: ['vehicle_plate', 'vehicle_type']
            }
          ]
        }
      ]
    });

    // Turkey Time Offset (UTC+3)
    const { formatTurkeyDate } = require('../utils/dateUtils');

    const ridesFormatted = rides.map(r => {
      const plain = r.toJSON();
      plain.formatted_date = formatTurkeyDate(r.created_at);
      // Backward Compatibility
      if (plain.passenger) plain.passenger.profile_photo = plain.passenger.profile_picture;
      if (plain.driver) plain.driver.profile_photo = plain.driver.profile_picture;
      return plain;
    });

    return res.json({ rides: ridesFormatted });
  } catch (err) {
    console.error('getRides err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/*
* POST /api/rides/:id/cancel
*/
async function cancelRide(req, res) {
  const t = await sequelize.transaction();
  try {
    const user = req.user;
    const rideId = req.params.id;
    const { reason } = req.body || {};

    // Use lock to prevent race conditions during cancellation
    const ride = await Ride.findByPk(rideId, {
      transaction: t,
      lock: t.LOCK.UPDATE
    });

    if (!ride) {
      await t.rollback();
      return res.status(404).json({ message: 'Ride not found' });
    }

    // Only allow cancel if ride is requested or assigned
    if (!['requested', 'assigned'].includes(ride.status)) {
      await t.rollback();
      return res.status(400).json({ message: 'Cannot cancel ride in status ' + ride.status });
    }

    // Check role: passenger can cancel their own ride; driver can cancel if assigned to them
    if (user.role === 'passenger' && Number(ride.passenger_id) !== Number(user.userId)) {
      await t.rollback();
      return res.status(403).json({ message: 'Forbidden' });
    }
    if (user.role === 'driver' && Number(ride.driver_id) !== Number(user.userId)) {
      await t.rollback();
      return res.status(403).json({ message: 'Forbidden' });
    }

    ride.status = 'cancelled';
    ride.cancel_reason = reason || null;
    await ride.save({ transaction: t });

    // Release driver if assigned
    if (ride.driver_id) {
      await Driver.update(
        { is_available: true },
        { where: { user_id: ride.driver_id }, transaction: t }
      );
    }

    // Commit early so DB state is finalized before sockets
    await t.commit();

    // 4. Parallelize Post-Commit Actions (Redis update, Queue, Socket, FCM)

    // We can fire-and-forget these or await them in parallel. Since they don't affect HTTP response structure (just side effects),
    // awaiting them in parallel is good practice to ensure they trigger before response returns, or we can just not await.
    // For reliability, we await Promise.all.

    Promise.all([
      // 1. Reset Redis Availability
      ride.driver_id ? redis.hset(`driver:${ride.driver_id}:meta`, 'available', '1').catch(e => console.warn('Redis avail reset failed', e)) : Promise.resolve(),

      // 2. Remove Timeout Job
      rideTimeoutQueue.remove('ride_timeout_' + rideId).catch(e => { }),

      // 3. Notifications (Socket & FCM)
      (async () => {
        const io = socketProvider.getIO();
        let targetUserId = null;
        let notificationTitle = 'Yolculuk İptal Edildi';
        let notificationBody = '';
        const roomName = 'ride:' + ride.id;

        // ... (Logic to determine target) ...
        // Simplified logic for brevity in parallel block, reusing existing variables

        // Notify Initiator
        const initiatorMeta = await redis.hgetall((user.role === 'driver' ? 'driver:' : 'user:') + user.userId + ':meta');
        if (initiatorMeta && initiatorMeta.socketId && io) {
          io.to(initiatorMeta.socketId).emit('ride:cancelled', { ride_id: ride.id, by: 'self', reason });
          const s = io.sockets.sockets.get(initiatorMeta.socketId);
          if (s) s.leave(roomName);
        }

        // Notify Pending Drivers if ride was still 'requested'
        if (ride.status === 'requested' || ride.status === 'cancelled') {
          const { RideRequest } = require('../models');
          const pending = await RideRequest.findAll({
            where: { ride_id: ride.id, driver_response: 'no_response' }
          });

          for (const req of pending) {
            const driverMeta = await redis.hgetall('driver:' + req.driver_id + ':meta');
            if (driverMeta && driverMeta.socketId && io) {
              io.to(driverMeta.socketId).emit('request:cancelled', { ride_id: ride.id });
            }
          }
        }

        if (user.role === 'passenger') {
          targetUserId = ride.driver_id;
          notificationBody = 'Yolcu yolculuğu iptal etti.';
          if (ride.driver_id) {
            const driverMeta = await redis.hgetall('driver:' + ride.driver_id + ':meta');
            if (driverMeta && driverMeta.socketId && io) {
              io.to(driverMeta.socketId).emit('ride:cancelled', { ride_id: ride.id, by: 'passenger', reason });
              const s = io.sockets.sockets.get(driverMeta.socketId);
              if (s) s.leave(roomName);
            }
          }
        } else { // driver
          targetUserId = ride.passenger_id;
          notificationBody = 'Sürücü yolculuğu iptal etti.';
          const passengerMeta = await redis.hgetall('user:' + ride.passenger_id + ':meta');
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
            await sendPushToTokens(tokens, { title: notificationTitle, body: notificationBody }, { type: 'ride_cancelled', ride_id: String(ride.id), reason: reason || '' });
          }
        }
      })()
    ]).catch(err => console.error('Post-cancel parallel actions failed', err));

    return res.json({ ok: true, ride_id: ride.id });
  } catch (err) {
    await t.rollback();
    console.error('cancelRide err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * POST /api/rides/:id/rate
 */
async function rateRide(req, res) {
  try {
    const user = req.user;
    const rideId = req.params.id;
    const { stars, comment } = req.body;
    if (!stars || stars < 1 || stars > 5) return res.status(400).json({ message: 'Invalid stars' });

    const ride = await Ride.findByPk(rideId);
    if (!ride) return res.status(404).json({ message: 'Ride not found' });

    // determine counterpart
    let ratedId = null;
    if (user.userId === Number(ride.passenger_id)) {
      // passenger rating driver
      if (!ride.driver_id) return res.status(400).json({ message: 'No driver to rate' });
      ratedId = ride.driver_id;
    } else if (user.userId === Number(ride.driver_id)) {
      // driver rating passenger
      ratedId = ride.passenger_id;
    } else {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const rating = await Rating.create({
      ride_id: ride.id,
      rater_id: user.userId,
      rated_id: ratedId,
      stars,
      comment: comment || null
    });

    return res.status(201).json({ ok: true, rating });
  } catch (err) {
    console.error('rateRide err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * GET /api/rides/:id/messages
 */
async function getMessages(req, res) {
  try {
    const user = req.user;
    const rideId = req.params.id;
    const ride = await Ride.findByPk(rideId);
    if (!ride) return res.status(404).json({ message: 'Ride not found' });

    // only participant can read
    if (user.userId !== Number(ride.passenger_id) && user.userId !== Number(ride.driver_id)) {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const messages = await RideMessage.findAll({
      where: { ride_id: rideId },
      order: [['created_at', 'ASC']]
    });
    const { formatTurkeyDate } = require('../utils/dateUtils');
    const messagesFormatted = messages.map(m => {
      const plain = m.toJSON();
      plain.formatted_date = formatTurkeyDate(m.created_at);
      return plain;
    });

    return res.json({ messages: messagesFormatted });
  } catch (err) {
    console.error('getMessages err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * GET /api/rides/active
 * Returns the current active ride for the user (passenger or driver)
 */
async function getActiveRide(req, res) {
  try {
    const user = req.user;
    const where = {
      status: {
        [Op.notIn]: ['completed', 'cancelled']
      }
    };

    if (user.role === 'passenger') {
      where.passenger_id = user.userId;
    } else if (user.role === 'driver') {
      where.driver_id = user.userId;
    }

    const ride = await Ride.findOne({
      where,
      order: [['created_at', 'DESC']],
      include: [
        {
          model: User,
          as: 'driver',
          attributes: ['id', 'first_name', 'last_name', 'phone', 'profile_picture', 'level', 'ref_count']
        },
        {
          model: User,
          as: 'passenger',
          attributes: ['id', 'first_name', 'last_name', 'phone', 'profile_picture', 'level']
        }
      ]
    });

    if (!ride) {
      return res.json({ active: false });
    }

    // If driver is assigned, fetch vehicle info
    let driverInfo = null;
    if (ride.driver) {
      // Parallelize fetches: Driver Details, Average Rating. 
      // Note: We cannot defer geo fetch properly in parallel if it depends on vehicle_type from driverDetails.
      // So detailed approach:
      const [driverDetails, ratingData] = await Promise.all([
        Driver.findOne({ where: { user_id: ride.driver.id } }),
        Rating.findOne({
          attributes: [[sequelize.fn('AVG', sequelize.col('stars')), 'avg_rating']],
          where: { rated_id: ride.driver.id }
        })
      ]);

      // redis.geopos moved after we have driverDetails (to know vehicle_type)

      // Re-fetch geo with correct key if needed is safer, but let's try parallel assuming ride.vehicle_type fits
      // Actually, driver vehicle type is what matters for the geo key.

      // Let's refactor: Fetch Driver & Rating parallel. Then Geo. still 2 steps instead of 3.

      const realRating = ratingData && ratingData.dataValues.avg_rating
        ? parseFloat(ratingData.dataValues.avg_rating).toFixed(1)
        : '5.0';

      driverInfo = {
        ...ride.driver.toJSON(),
        vehicle_plate: driverDetails ? driverDetails.vehicle_plate : null,
        vehicle_type: driverDetails ? driverDetails.vehicle_type : null,
        rating: realRating
      };

      // Now fetch Geo
      try {
        const vType = driverInfo.vehicle_type || 'sari';
        const geoKey = `drivers:geo:${vType}`;
        const geoPos = await redis.geopos(geoKey, String(ride.driver.id));
        if (geoPos && geoPos.length > 0 && geoPos[0]) {
          driverInfo.driver_lng = geoPos[0][0];
          driverInfo.driver_lat = geoPos[0][1];
        }
      } catch (geoErr) { }
    }

    const { formatTurkeyDate } = require('../utils/dateUtils');
    const plainRide = ride.toJSON();
    plainRide.formatted_date = formatTurkeyDate(ride.created_at);

    return res.json({
      active: true,
      ride: { ...plainRide, passenger: plainRide.passenger ? { ...plainRide.passenger, profile_photo: plainRide.passenger.profile_picture } : null, driver: plainRide.driver ? { ...plainRide.driver, profile_photo: plainRide.driver.profile_picture } : null },
      driver: driverInfo ? { ...driverInfo, profile_photo: driverInfo.profile_picture } : null
    });

  } catch (err) {
    console.error('getActiveRide err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

module.exports = {
  createRide,
  getRide,
  getRides,
  cancelRide,
  rateRide,
  getMessages,
  getActiveRide,
  estimateRide
};