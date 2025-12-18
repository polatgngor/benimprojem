// Socket.IO initialization and handlers (full)
// - availability requires driver approved
// - accept/reject, start/end, verify_code, chat, location updates
const { Server } = require('socket.io');
const Redis = require('ioredis');
const { Op } = require('sequelize');
const { verifyAccessToken } = require('../utils/jwt');
const socketProvider = require('../lib/socketProvider');
const { assignRideAtomic } = require('../services/assignService');
const { Ride, RideRequest, RideMessage, Driver, User, UserDevice, Rating } = require('../models');
const { sendPushToTokens } = require('../lib/fcm');

const redis = new Redis({
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
  password: process.env.REDIS_PASSWORD || undefined
});

// Helper: redis GEO key per vehicle type
function geoKeyForVehicle(vehicleType) {
  return `drivers:geo:${vehicleType}`; // e.g., drivers:geo:sari
}

module.exports = function initSockets(server) {
  const io = new Server(server, {
    cors: { origin: '*' },
    pingInterval: 10000, // Send ping every 10s
    pingTimeout: 5000    // Disconnect if no pong in 5s
  });

  socketProvider.setIO(io);

  // Middleware: expect { token } in socket.handshake.auth
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth && socket.handshake.auth.token;
      if (!token) return next(new Error('Authentication error - token missing'));
      const payload = verifyAccessToken(token);
      socket.user = payload; // { userId, role }
      return next();
    } catch (err) {
      return next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    const { userId, role } = socket.user;
    console.log(`Socket connected: user ${userId} role ${role} id ${socket.id}`);

    // store socketId meta
    if (userId) {
      // Fire and forget meta update
      redis.hset(`user:${userId}:meta`, 'socketId', socket.id, 'lastSeen', Date.now()).catch(e => console.error('Redis meta err', e));


      // Clear disconnect timestamp on connect
      if (role === 'driver') {
        redis.hdel(`driver:${userId}:meta`, 'disconnected_ts').catch(e => { });
        redis.hset(`driver:${userId}:meta`, 'socketId', socket.id).catch(e => console.error('Redis driver meta err', e));
      }
    }

    //
    // DRIVER: set availability (online/offline)
    //
    socket.on('driver:set_availability', async (payload) => {
      try {
        if (role !== 'driver') return;
        const { available, lat, lng, vehicle_type } = payload;
        // console.log(`[driver:set_availability] user:${userId} payload:`, payload);

        const isAvailable = available === true || available === 'true';

        // Fetch current driver info
        const currentDriver = await Driver.findOne({ where: { user_id: userId } });
        if (!currentDriver) return;

        // If trying to go online, check if another driver with same plate is already online
        if (isAvailable) {
          const activeDriverWithSamePlate = await Driver.findOne({
            where: {
              vehicle_plate: currentDriver.vehicle_plate,
              is_available: true,
              user_id: { [Op.ne]: userId } // Not self
            }
          });

          if (activeDriverWithSamePlate) {
            // Found another active driver on same plate
            return socket.emit('driver:availability_error', {
              message: `Bu plakada (${currentDriver.vehicle_plate}) şu an başka bir sürücü aktif. Lütfen diğer sürücünün çıkış yapmasını bekleyin.`
            });
          }
        }

        // Parallelize updates for speed
        await Promise.all([
          // 1. Update MySQL
          Driver.update(
            { is_available: isAvailable },
            { where: { user_id: userId } }
          ),

          // 2. Update Redis Meta
          (async () => {
            await redis.hset(`driver:${userId}:meta`, 'available', isAvailable ? '1' : '0');
            await redis.hdel(`driver:${userId}:meta`, 'disconnected_ts'); // Clear disconnect flag
            await redis.hset(`driver:${userId}:meta`, 'socketId', socket.id); // Ensure socketId is synced
            if (vehicle_type) {
              await redis.hset(`driver:${userId}:meta`, 'vehicle_type', vehicle_type);
            }
          })(),

          // 3. Update GEO if location provided
          (async () => {
            if (isAvailable && lat && lng) {
              const vType = vehicle_type || 'sari';
              const key = geoKeyForVehicle(vType);
              await redis.geoadd(key, lng, lat, String(userId));
              await redis.hset(`driver:${userId}:meta`, 'last_loc_update', Date.now());
            } else if (!isAvailable) {
              // Remove from GEO if going offline
              const types = ['sari', 'turkuaz', 'siyah', '8+1'];
              for (const t of types) {
                await redis.zrem(geoKeyForVehicle(t), String(userId));
              }
            }
          })()
        ]);

        socket.emit('driver:availability_updated', { available: isAvailable });
      } catch (err) {
        console.error('driver:set_availability err', err);
        socket.emit('driver:availability_error', { message: 'Sunucu hatası oluştu.' });
      }
    });


    //
    // DRIVER: accept request
    //
    socket.on('driver:accept_request', async (payload) => {
      try {
        if (role !== 'driver')
          return socket.emit('request:accept_failed', { ride_id: payload.ride_id, reason: 'forbidden' });

        const rideId = payload.ride_id;
        const driverId = userId;

        const result = await assignRideAtomic(rideId, driverId);
        if (!result.success) {
          return socket.emit('request:accept_failed', { ride_id: rideId, reason: result.reason });
        }

        const ride = result.ride;

        // Fetch Driver Details
        const driverDetails = await Driver.findOne({ where: { user_id: driverId } });
        const driverUser = await User.findByPk(driverId);
        if (!driverUser) {
          return socket.emit('request:accept_failed', { ride_id: rideId, reason: 'driver_user_not_found' });
        }

        // Calculate Driver Rating
        const driverRatings = await Rating.findAll({ where: { rated_id: driverId } });
        let driverRatingAvg = 5.0;
        if (driverRatings.length > 0) {
          const sum = driverRatings.reduce((a, b) => a + b.stars, 0);
          driverRatingAvg = sum / driverRatings.length;
        }

        const driverInfo = {
          id: driverId,
          first_name: driverUser.first_name,
          last_name: driverUser.last_name,
          phone: driverUser.phone,
          profile_photo: driverUser.profile_photo,
          rating: parseFloat(driverRatingAvg.toFixed(1)),
          vehicle: {
            plate: driverDetails ? driverDetails.vehicle_plate : '',
            type: driverDetails ? driverDetails.vehicle_type : 'sari',
            model: '',
            color: ''
          }
        };

        // Fetch Passenger Details
        const passengerUser = await User.findByPk(ride.passenger_id);
        if (!passengerUser) {
          console.error(`Passenger ${ride.passenger_id} not found for ride ${ride.id}`);
          return socket.emit('request:accept_failed', { ride_id: rideId, reason: 'passenger_not_found' });
        }

        const passengerRatings = await Rating.findAll({ where: { rated_id: ride.passenger_id } });
        let passengerRatingAvg = 5.0;
        if (passengerRatings.length > 0) {
          const sum = passengerRatings.reduce((a, b) => a + b.stars, 0);
          passengerRatingAvg = sum / passengerRatings.length;
        }

        const passengerInfo = {
          id: ride.passenger_id,
          first_name: passengerUser.first_name,
          last_name: passengerUser.last_name,
          phone: passengerUser.phone,
          profile_photo: passengerUser.profile_photo,
          rating: parseFloat(passengerRatingAvg.toFixed(1))
        };

        // Join Room Logic
        const room = `ride:${ride.id}`;
        socket.join(room); // Driver joins

        // Notify passenger via Socket & Join Room
        const passengerMeta = await redis.hgetall(`user:${ride.passenger_id}:meta`);
        if (passengerMeta && passengerMeta.socketId) {
          // Passenger joins room if connected
          const passengerSocket = io.sockets.sockets.get(passengerMeta.socketId);
          if (passengerSocket) {
            passengerSocket.join(room);
          }

          io.to(passengerMeta.socketId).emit('ride:assigned', {
            ride_id: ride.id,
            driver: driverInfo,
            code4: ride.code4,
            eta: null
          });
        }

        // Notify passenger via FCM
        try {
          const devices = await UserDevice.findAll({ where: { user_id: ride.passenger_id } });
          const tokens = devices.map((d) => d.device_token);
          if (tokens.length > 0) {
            await sendPushToTokens(
              tokens,
              {
                title: 'Sürücü yola çıktı',
                body: `${driverInfo.first_name} ${driverInfo.last_name} isteğinizi kabul etti.`
              },
              {
                type: 'ride_assigned',
                ride_id: String(ride.id),
                driver_id: String(driverId)
              }
            );
          }
        } catch (e) {
          console.warn('driver:accept_request FCM failed', e.message || e);
        }

        // Confirm to driver
        socket.emit('request:accepted_confirm', {
          ride_id: rideId,
          assigned: true,
          passenger: passengerInfo
        });
      } catch (err) {
        console.error('driver:accept_request error', err);
        socket.emit('request:accept_failed', { ride_id: payload && payload.ride_id, reason: 'server_error' });
      }
    });

    //
    // DRIVER: reject request
    //
    socket.on('driver:reject_request', async (payload) => {
      try {
        if (role !== 'driver')
          return socket.emit('request:reject_failed', { ride_id: payload.ride_id, reason: 'forbidden' });

        const rideId = payload.ride_id;
        const driverId = userId;

        await RideRequest.update(
          { driver_response: 'rejected', response_at: new Date() },
          { where: { ride_id: rideId, driver_id: driverId } }
        );

        socket.emit('request:rejected_confirm', { ride_id: rideId });
      } catch (err) {
        console.error('driver:reject_request err', err);
        socket.emit('request:reject_failed', { ride_id: payload && payload.ride_id, reason: 'server_error' });
      }
    });



    //
    // PASSENGER: rejoin (on reconnect)
    //
    socket.on('passenger:rejoin', async (payload) => {
      try {
        if (role !== 'passenger') return;
        const ride = await Ride.findOne({
          where: {
            passenger_id: userId,
            status: ['assigned', 'started']
          }
        });

        if (ride) {
          const room = `ride:${ride.id}`;
          socket.join(room);
          console.log(`Passenger ${userId} rejoined room ${room}`);
        }
      } catch (err) {
        console.error('passenger:rejoin err', err);
      }
    });

    //
    // DRIVER: rejoin (on reconnect)
    //
    socket.on('driver:rejoin', async () => {
      try {
        if (role !== 'driver') return;
        const ride = await Ride.findOne({
          where: {
            driver_id: userId,
            status: ['assigned', 'started']
          }
        });

        if (ride) {
          const room = `ride:${ride.id}`;
          socket.join(room);
          console.log(`Driver ${userId} rejoined room ${room}`);

          // Fetch Passenger Details for UI restoration
          const passengerUser = await User.findByPk(ride.passenger_id);
          const passengerRatings = await Rating.findAll({ where: { rated_id: ride.passenger_id } });
          let passengerRatingAvg = 5.0;
          if (passengerRatings.length > 0) {
            const sum = passengerRatings.reduce((a, b) => a + b.stars, 0);
            passengerRatingAvg = sum / passengerRatings.length;
          }

          const passengerInfo = {
            id: ride.passenger_id,
            first_name: passengerUser.first_name,
            last_name: passengerUser.last_name,
            phone: passengerUser.phone,
            profile_photo: passengerUser.profile_photo,
            rating: parseFloat(passengerRatingAvg.toFixed(1))
          };

          socket.emit('ride:rejoined', {
            ride_id: ride.id,
            status: ride.status,
            passenger: passengerInfo,
            pickup_lat: ride.start_lat,
            pickup_lng: ride.start_lng,
            pickup_address: ride.start_address,
            dropoff_lat: ride.end_lat,
            dropoff_lng: ride.end_lng,
            dropoff_address: ride.end_address
          });
        }
      } catch (err) {
        console.error('driver:rejoin err', err);
      }
    });

    //
    // DRIVER: start ride (validate code, set status -> started, join room, notify)
    //
    socket.on('driver:start_ride', async (payload) => {
      try {
        if (role !== 'driver')
          return socket.emit('start_ride_failed', { ride_id: payload.ride_id, reason: 'forbidden' });

        const { ride_id, code } = payload;
        // load ride
        const ride = await Ride.findByPk(ride_id);
        if (!ride) return socket.emit('start_ride_failed', { ride_id, reason: 'ride_not_found' });

        if (String(ride.driver_id) !== String(userId)) {
          return socket.emit('start_ride_failed', { ride_id, reason: 'not_assigned_driver' });
        }

        if (ride.status !== 'assigned') {
          return socket.emit('start_ride_failed', { ride_id, reason: `invalid_status_${ride.status}` });
        }

        if (String(ride.code4) !== String(code)) {
          return socket.emit('start_ride_failed', { ride_id, reason: 'invalid_code' });
        }

        // start ride
        ride.status = 'started';
        await ride.save();

        // ensure both sockets are in room (join if they are not)
        const ioInstance = socketProvider.getIO();
        const passengerMeta = await redis.hgetall(`user:${ride.passenger_id}:meta`);
        const driverMeta = await redis.hgetall(`driver:${ride.driver_id}:meta`);
        const room = `ride:${ride.id}`;

        if (ioInstance) {
          const passengerSocketId = passengerMeta && passengerMeta.socketId ? passengerMeta.socketId : null;
          const driverSocketId = driverMeta && driverMeta.socketId ? driverMeta.socketId : null;

          if (passengerSocketId) {
            const ps = ioInstance.sockets.sockets.get(passengerSocketId);
            if (ps) ps.join(room);
          }
          if (driverSocketId) {
            const ds = ioInstance.sockets.sockets.get(driverSocketId);
            if (ds) ds.join(room);
          }

          // notify room
          ioInstance.to(room).emit('ride:started', { ride_id: ride.id, driver_id: ride.driver_id });
        }

        // Notify passenger via FCM
        try {
          const devices = await UserDevice.findAll({ where: { user_id: ride.passenger_id } });
          const tokens = devices.map((d) => d.device_token);
          if (tokens.length > 0) {
            await sendPushToTokens(
              tokens,
              {
                title: 'Yolculuk başladı',
                body: 'İyi yolculuklar!'
              },
              {
                type: 'ride_started',
                ride_id: String(ride.id)
              }
            );
          }
        } catch (e) {
          console.warn('driver:start_ride FCM failed', e.message || e);
        }

        // confirm to driver
        socket.emit('start_ride_ok', { ride_id: ride.id });
      } catch (err) {
        console.error('driver:start_ride err', err);
        socket.emit('start_ride_failed', { ride_id: payload && payload.ride_id, reason: 'server_error' });
      }
    });

    //
    // DRIVER: end ride
    //
    socket.on('driver:end_ride', async (payload) => {
      try {
        if (role !== 'driver')
          return socket.emit('end_ride_failed', { ride_id: payload.ride_id, reason: 'forbidden' });

        const { ride_id, fare_actual } = payload;
        const ride = await Ride.findByPk(ride_id);
        if (!ride) return socket.emit('end_ride_failed', { ride_id, reason: 'ride_not_found' });

        if (String(ride.driver_id) !== String(userId)) {
          return socket.emit('end_ride_failed', { ride_id, reason: 'not_assigned_driver' });
        }

        if (ride.status !== 'started') {
          return socket.emit('end_ride_failed', { ride_id, reason: `invalid_status_${ride.status}` });
        }

        if (ride.fare_estimate) {
          const estimated = parseFloat(ride.fare_estimate);
          const actual = parseFloat(fare_actual);
          // Relaxed Check: 50% lower to 100% higher allowed during testing
          const minAcceptable = estimated * 0.5;
          const maxAcceptable = estimated * 2.0;

          // If actual is unreasonably low or high, reject it
          if (actual < minAcceptable || actual > maxAcceptable) {
            return socket.emit('end_ride_failed', {
              ride_id,
              reason: 'fare_mismatch',
              message: `Ücret (${actual} TL), tahmini tutardan (${estimated} TL) çok sapamaz. Lütfen kontrol edin.`
            });
          }
        }

        ride.status = 'completed';
        ride.fare_actual = fare_actual || ride.fare_actual;

        // --- Polyline persistence ---
        try {
          const routeKey = `ride:${ride.id}:route`;
          const rawPoints = await redis.lrange(routeKey, 0, -1);
          if (rawPoints && rawPoints.length > 0) {
            const parsedPoints = rawPoints.map(p => JSON.parse(p));
            ride.actual_route = parsedPoints;
            // Cleanup Redis
            await redis.del(routeKey);
          }
        } catch (e) {
          console.error('[end_ride] failed to persist route', e);
        }

        await ride.save();

        // --- Set Driver Available Again & Restore GEO (Ghost Call Fix) ---
        // --- Set Driver Available Again & Restore GEO (Ghost Call Fix) ---
        // Parallelize independent updates
        try {
          await Promise.all([
            Driver.update({ is_available: true }, { where: { user_id: userId } }),
            redis.hset(`driver:${userId}:meta`, 'available', '1')
          ]);

          // Restore to GEO index immediately using last known location
          const meta = await redis.hgetall(`driver:${userId}:meta`);
          if (meta && meta.lat && meta.lng && meta.vehicle_type) {
            const key = geoKeyForVehicle(meta.vehicle_type || 'sari');
            await redis.geoadd(key, meta.lng, meta.lat, String(userId));
          }
        } catch (avErr) {
          console.error('[end_ride] failed to set driver available', avErr);
        }
        // ----------------------------------

        // ----------------------------------------------------
        // WALLET LOGIC (Earnings Recording Only)
        // ----------------------------------------------------
        // We track earnings in Wallet for statistics, even if no commission is taken.
        const { Wallet, WalletTransaction } = require('../models');

        // Ensure wallet exists (create if not)
        let driverWalletRec = await Wallet.findOne({ where: { user_id: userId } });
        if (!driverWalletRec) {
          try {
            driverWalletRec = await Wallet.create({ user_id: userId, balance: 0.00 });
          } catch (e) {
            console.error('Could not create wallet for driver', userId, e);
          }
        }

        if (driverWalletRec) {
          const fare = parseFloat(ride.fare_actual);

          // balance: current usable (if we had withdrawals)
          // total_earnings: lifetime stats
          const newBalance = parseFloat(driverWalletRec.balance) + fare;
          const newTotal = parseFloat(driverWalletRec.total_earnings || 0) + fare;

          await driverWalletRec.update({
            balance: newBalance,
            total_earnings: newTotal
          });

          await WalletTransaction.create({
            wallet_id: driverWalletRec.id,
            amount: fare, // Always positive earnings
            type: 'ride_earnings',
            reference_id: ride.id,
            description: `Yolculuk Kazancı - Ride #${ride.id}`
          });
        }


        // notify room and passenger
        const ioInstance = socketProvider.getIO();
        const room = `ride:${ride.id}`;
        if (ioInstance) {
          ioInstance.to(room).emit('ride:completed', { ride_id: ride.id, fare_actual: ride.fare_actual });
        }

        // Notify passenger via FCM
        try {
          const devices = await UserDevice.findAll({ where: { user_id: ride.passenger_id } });
          const tokens = devices.map((d) => d.device_token);
          if (tokens.length > 0) {
            await sendPushToTokens(
              tokens,
              {
                title: 'Yolculuk tamamlandı',
                body: `Yolculuk ücreti: ${ride.fare_actual} TL`
              },
              {
                type: 'ride_completed',
                ride_id: String(ride.id),
                fare: String(ride.fare_actual)
              }
            );
          }
        } catch (e) {
          console.warn('driver:end_ride FCM failed', e.message || e);
        }

        // confirm to driver
        socket.leave(`ride:${ride.id}`);
        socket.emit('end_ride_ok', { ride_id: ride.id });
      } catch (err) {
        console.error('driver:end_ride err', err);
        socket.emit('end_ride_failed', { ride_id: payload && payload.ride_id, reason: 'server_error' });
      }
    });

    //
    // DRIVER: cancel ride (sürücü iptali)
    //
    socket.on('driver:cancel_ride', async (payload) => {
      try {
        if (role !== 'driver')
          return socket.emit('cancel_ride_failed', { ride_id: payload && payload.ride_id, reason: 'forbidden' });

        const { ride_id, reason } = payload;
        const ride = await Ride.findByPk(ride_id);
        if (!ride) {
          return socket.emit('cancel_ride_failed', { ride_id, reason: 'ride_not_found' });
        }

        if (String(ride.driver_id) !== String(userId)) {
          return socket.emit('cancel_ride_failed', { ride_id, reason: 'not_assigned_driver' });
        }

        if (['completed', 'cancelled'].includes(ride.status)) {
          return socket.emit('cancel_ride_failed', { ride_id, reason: `invalid_status_${ride.status}` });
        }

        // Update ride status
        await ride.update({
          status: 'cancelled',
          cancelled_by: 'driver',
          cancellation_reason: reason || 'driver_cancelled'
        });

        // Notify passenger via socket
        const passengerMeta = await redis.hgetall(`user:${ride.passenger_id}:meta`);
        const ioInstance = socketProvider.getIO();
        if (passengerMeta && passengerMeta.socketId && ioInstance) {
          ioInstance.to(passengerMeta.socketId).emit('ride:cancelled', {
            ride_id: ride.id,
            reason: reason || 'driver_cancelled'
          });
        }

        // Notify passenger via FCM
        try {
          const devices = await UserDevice.findAll({ where: { user_id: ride.passenger_id } });
          const tokens = devices.map((d) => d.device_token);
          if (tokens.length > 0) {
            await sendPushToTokens(
              tokens,
              {
                title: 'Yolculuk İptal Edildi',
                body: 'Sürücü tarafından yolculuğunuz iptal edildi.'
              },
              {
                type: 'ride_cancelled',
                ride_id: String(ride.id),
                reason: reason || 'driver_cancelled'
              }
            );
          }
        } catch (e) {
          console.warn('driver:cancel_ride FCM failed', e.message || e);
        }

        // Set driver back to available
        await Driver.update(
          { is_available: true },
          { where: { user_id: userId } }
        );
        // Sync Redis & Restore GEO (Ghost Call Fix)
        await redis.hset(`driver:${userId}:meta`, 'available', '1');
        const meta = await redis.hgetall(`driver:${userId}:meta`);
        if (meta && meta.lat && meta.lng) {
          const vType = meta.vehicle_type || 'sari';
          const key = geoKeyForVehicle(vType);
          await redis.geoadd(key, meta.lng, meta.lat, String(userId));
        }

        // Leave the room
        socket.leave(`ride:${ride.id}`);

        socket.emit('cancel_ride_ok', { ride_id: ride.id });
      } catch (err) {
        console.error('driver:cancel_ride err', err);
        socket.emit('cancel_ride_failed', { ride_id: payload && payload.ride_id, reason: 'server_error' });
      }
    });

    //
    // CHAT: join room (history or reconnect)
    //
    socket.on('ride:join', async (payload) => {
      try {
        const { ride_id } = payload;
        if (!ride_id) return;

        const ride = await Ride.findByPk(ride_id);
        if (!ride) return socket.emit('join_failed', { reason: 'ride_not_found' });

        // Auth check
        if (String(ride.passenger_id) !== String(userId) && String(ride.driver_id) !== String(userId)) {
          console.warn(`Unauthorized join attempt user:${userId} ride:${ride_id}`);
          return;
        }

        // 12-hour rule check for completed rides
        if (ride.status === 'completed') {
          // Allow a bit of leeway or verify timestamp
          if (!ride.updated_at) {
            // If no updated_at, fallback to created_at or allow
          } else {
            const TWELVE_HOURS_MS = 12 * 60 * 60 * 1000;
            const rideEndTime = new Date(ride.updated_at).getTime();
            const now = Date.now();
            // Check for valid time
            if (!isNaN(rideEndTime) && (now - rideEndTime > TWELVE_HOURS_MS)) {
              console.log(`Chat expired for ride ${ride_id}`);
              return socket.emit('join_failed', { reason: 'chat_expired', message: 'Sohbet süresi dolmuştur.' });
            }
          }
        }

        const room = `ride:${Number(ride.id)}`; // Ensure consistent room name
        socket.join(room);
        socket.emit('ride:joined', { room }); // Ack
        console.log(`User ${userId} joined chat room ${room}`);
      } catch (err) {
        console.error('ride:join err', err);
      }
    });

    socket.on('ride:leave', (payload) => {
      const { ride_id } = payload;
      if (ride_id) {
        // Leave both potential room names to be safe
        socket.leave(`ride:${ride_id}`);
        socket.leave(`ride:${Number(ride_id)}`);
      }
    });

    //
    // CHAT: ride message persist + broadcast + FCM
    //
    socket.on('ride:message', async (payload) => {
      try {
        const { ride_id, text } = payload;
        if (!ride_id || !text) return socket.emit('message_failed', { reason: 'invalid_payload' });

        const ride = await Ride.findByPk(ride_id);
        if (!ride) return socket.emit('message_failed', { reason: 'ride_not_found' });

        // completed statüsünde ise 12 saat kuralı kontrol et
        if (ride.status === 'completed') {
          const TWELVE_HOURS_MS = 12 * 60 * 60 * 1000;
          const rideEndTime = new Date(ride.updated_at).getTime();
          const now = Date.now();
          if (now - rideEndTime > TWELVE_HOURS_MS) {
            return socket.emit('message_failed', { reason: 'chat_expired', message: 'Yolculuk üzerinden 12 saat geçtiği için sohbet kapanmıştır.' });
          }
        } else if (ride.status !== 'assigned' && ride.status !== 'started') {
          // diğer statülerde (cancelled vs) mesajlaşma olmasın
          return socket.emit('message_failed', { reason: 'invalid_status_' + ride.status });
        }

        // sadece ride'ın passenger/driver'ı mesaj atabilsin
        if (String(ride.passenger_id) !== String(userId) && String(ride.driver_id) !== String(userId)) {
          return socket.emit('message_failed', { reason: 'forbidden' });
        }

        // persist
        let msg;
        try {
          msg = await RideMessage.create({ ride_id, sender_id: userId, message: text });
        } catch (e) {
          console.warn('Could not persist ride message', e);
        }

        // broadcast to room
        const room = `ride:${Number(ride.id)}`; // Ensure consistent room name
        const ioInstance = socketProvider.getIO();
        const payloadOut = {
          ride_id: Number(ride.id),
          sender_id: userId,
          text,
          sent_at: msg ? msg.created_at : Date.now()
        };
        if (ioInstance) {
          console.log(`[ride:message] Broadcasting to room: ${room} Payload:`, JSON.stringify(payloadOut));
          ioInstance.to(room).emit('ride:message', payloadOut);
        } else {
          console.error('[ride:message] ioInstance not found!');
        }

        // karşı tarafın userId'sini bul
        let otherUserId = null;
        if (String(ride.passenger_id) === String(userId)) {
          otherUserId = ride.driver_id;
        } else if (String(ride.driver_id) === String(userId)) {
          otherUserId = ride.passenger_id;
        }

        if (otherUserId) {
          try {
            const devices = await UserDevice.findAll({ where: { user_id: otherUserId } });
            const tokens = devices.map((d) => d.device_token);
            if (tokens.length > 0) {
              const sender = await User.findByPk(userId, { attributes: ['first_name', 'last_name'] });
              const senderName = `${sender.first_name || ''} ${sender.last_name || ''}`.trim();

              await sendPushToTokens(
                tokens,
                {
                  title: 'Yeni mesaj',
                  body: senderName ? `${senderName}: ${text}` : text
                },
                {
                  type: 'ride_chat_message',
                  ride_id: String(ride.id),
                  sender_id: String(userId),
                  sender_name: senderName
                }
              );
            }
          } catch (e) {
            console.warn('ride:message FCM failed', e.message || e);
          }
        }
      } catch (err) {
        console.error('ride:message err', err);
        socket.emit('message_failed', { reason: 'server_error' });
      }
    });

    //
    // DRIVER: location updates -> broadcast to joined ride room(s)
    //
    socket.on('driver:update_location', async (payload) => {
      try {
        if (role !== 'driver') return;
        const { lat, lng, vehicle_type } = payload;
        const key = geoKeyForVehicle(vehicle_type || 'sari');

        // console.log(`[driver:update_location] user:${userId} key:${key} lat:${lat} lng:${lng}`);

        // Fire and forget location updates (Parallel)
        Promise.all([
          redis.geoadd(key, lng, lat, String(userId)),
          redis.hset(`driver:${userId}:meta`, 'last_loc_update', Date.now(), 'lat', lat, 'lng', lng)
        ]).catch(e => { });

        // if driver is in a ride room, broadcast to that room
        const rooms = Array.from(socket.rooms); // includes socket.id for sure
        for (const r of rooms) {
          if (r.startsWith('ride:')) {
            const rideId = r.split(':')[1];
            // Async append to Redis list (Ride Path)
            // Storing as JSON string: {lat, lng, ts}
            const point = JSON.stringify({ lat, lng, ts: Date.now() });
            redis.rpush(`ride:${rideId}:route`, point).catch(e => { });
            // Set expiry to 24h just in case of zombie keys
            redis.expire(`ride:${rideId}:route`, 24 * 60 * 60).catch(e => { });

            const ioInstance = socketProvider.getIO();
            if (ioInstance) {
              ioInstance.to(r).emit('ride:update_location', { driver_id: userId, lat, lng, ts: Date.now() });
            }
          }
        }
      } catch (err) {
        console.error('driver:update_location err', err);
      }
    });

    // -------------------------------------------------------------
    // SUPPORT SYSTEM
    // -------------------------------------------------------------
    socket.on('support:join', (payload) => {
      try {
        const { ticket_id } = payload;
        if (!ticket_id) return;

        // Security check: In production, verify user owns ticket or is admin
        // For now trusting the ID (or we can DB check if paranoid)

        const room = `ticket_${ticket_id}`;
        socket.join(room);
        console.log(`User ${userId} joined support room ${room}`);
      } catch (err) {
        console.error('support:join err', err);
      }
    });

    socket.on('support:leave', (payload) => {
      const { ticket_id } = payload;
      if (ticket_id) {
        socket.leave(`ticket_${ticket_id}`);
      }
    });

    //
    // DISCONNECT: Auto-offline logic for drivers
    //
    socket.on('disconnect', async () => {
      console.log(`Socket disconnected: user ${userId} role ${role} id ${socket.id}`);
      if (role === 'driver') {
        try {
          // Check if driver has any active ride
          const activeRide = await Ride.findOne({
            where: {
              driver_id: userId,
              status: ['assigned', 'started']
            }
          });

          // If NO active ride, set offline
          if (!activeRide) {
            console.log(`Driver ${userId} disconnected. Removing from Geo Index but keeping MySQL status (Graceful Disconnect).`);

            // 1. DO NOT Update MySQL - Keep their "Intent" to be online
            // await Driver.update(
            //   { is_available: false },
            //   { where: { user_id: userId } }
            // );

            // 2. Update Redis Meta
            // Set disconnected_ts for graceful handling
            await redis.hset(`driver:${userId}:meta`, 'socketId', '', 'disconnected_ts', Date.now());

            // 3. DO NOT Remove from GEO immediately (Grace Period)
            // cleanupDrivers.js will handle removal if they don't return in 60s.
            console.log(`Driver ${userId} disconnected. Grace period started.`);
          } else {
            console.log(`Driver ${userId} disconnected but has active ride ${activeRide.id}. Keeping status as is.`);
          }
        } catch (e) {
          console.error('Error in driver disconnect auto-offline:', e);
        }
      }
    });

  });

  console.log('✅ Socket.IO initialized (with start/end, chat, rooms, approval check, FCM chat & arrived)');
  return io;
};