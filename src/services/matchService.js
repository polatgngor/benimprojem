const Redis = require('ioredis');
const redis = new Redis({
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
  password: process.env.REDIS_PASSWORD || undefined
});
const socketProvider = require('../lib/socketProvider');
const { rideTimeoutQueue } = require('../queues/rideTimeoutQueue');
const { User, UserDevice, RideRequest } = require('../models');
const { sendPushToTokens } = require('../lib/fcm');
const { getDriverPrioritySeconds } = require('../services/levelService');

// config
const DEFAULT_RADIUS_KM = 3;
const MAX_CANDIDATES = 10;
const BROADCAST_BATCH = 5;
const ACCEPT_TIMEOUT_SECONDS = parseInt(process.env.RIDE_ACCEPT_TIMEOUT_SECONDS || '20'); // seconds

function geoKeyForVehicle(vt) {
  return `drivers:geo:${vt || 'sari'}`;
}

async function findNearbyDrivers(vehicle_type, lat, lng, radiusKm = DEFAULT_RADIUS_KM, limit = MAX_CANDIDATES) {
  const key = geoKeyForVehicle(vehicle_type);
  // console.log(`[findNearbyDrivers] searching key:${key} lat:${lat} lng:${lng} radius:${radiusKm} limit:${limit}`);

  const raw = await redis.georadius(key, lng, lat, radiusKm, 'km', 'WITHDIST', 'ASC', 'COUNT', limit);
  if (!raw) return [];
  return raw.map((item) => {
    if (Array.isArray(item) && item.length > 0) {
      return String(item[0]);
    }
    return String(item);
  });
}

// Helper: Determine region from coordinates (approximate)
function getRegion(lat, lng) {
  // Istanbul longitude split approx 29.0
  // < 29.0 => Avrupa
  // >= 29.0 => Anadolu
  if (!lng) return null;
  return lng < 29.0 ? 'Avrupa' : 'Anadolu';
}

/**
 * Emit ride request to provided drivers (driverIds order assumed).
 * Also schedules the single timeout job (no second wave).
 * Returns array of driverIds that were actually sent to.
 *
 * Passenger tarafında radius level'e göre ayarlanıyor,
 * burada da sürücü level'ına göre çağrı düşme zamanı ayarlanıyor:
 *   platinum  -> 0 sn
 *   gold      -> 1 sn
 *   silver    -> 2 sn
 *   standard  -> 3 sn
 * 
 * NEW: Return Home Priority (Dönüş Önceliği)
 * If current time is 06:00-09:00 or 17:00-21:00
 * AND driver is in Opposite Region (e.g. Anadolu driver in Avrupa)
 * AND ride destination is Driver's Home Region (e.g. going to Anadolu)
 * THEN prioritySeconds = 0 (ignore level)
 */
async function emitRideRequest(ride, opts = {}) {
  const vehicle_type = ride.vehicle_type;
  const lat = opts.startLat;
  const lng = opts.startLng;
  const passenger_info = opts.passenger_info || {};
  const radiusKm = opts.radiusKm || DEFAULT_RADIUS_KM;

  let nearby = opts.driverIds;
  if (!nearby) {
    nearby = await findNearbyDrivers(vehicle_type, lat, lng, radiusKm, MAX_CANDIDATES);
  }

  try {
    // console.log(`[matchService] ride ${ride.id} nearby candidates:`, nearby);
  } catch (e) { }

  if (!nearby || nearby.length === 0) {
    console.log(`[matchService] ride ${ride.id} - no nearby drivers found`);
  }

  const io = socketProvider.getIO();
  const sentDrivers = [];

  const payloadBase = {
    ride_id: ride.id,
    start: { lat: ride.start_lat, lng: ride.start_lng, address: ride.start_address },
    end: { lat: ride.end_lat, lng: ride.end_lng, address: ride.end_address },
    vehicle_type: vehicle_type,
    options: ride.options || {},
    fare_estimate: ride.fare_estimate || null,
    passenger: passenger_info,
    distance: opts.distanceMeters,
    duration: opts.durationSeconds,
    polyline: opts.polyline,
    payment_method: ride.payment_method
  };

  // Check Time Window for Priority
  const now = new Date();
  const hour = now.getHours();
  const isMorningPeak = (hour >= 6 && hour < 9);
  const isEveningPeak = (hour >= 17 && hour < 21);
  const isPeakHour = isMorningPeak || isEveningPeak;

  // Determine Ride Destination Region
  const rideDestRegion = getRegion(ride.end_lat, ride.end_lng);

  // Driver'ların level'larını ve working_region'larını çek
  let driversWithLevel = [];
  if (nearby && nearby.length > 0) {
    // We need Driver table for working_region
    const { Driver } = require('../models'); // Lazy load to avoid circular dep if any

    const users = await User.findAll({
      where: { id: nearby },
      attributes: ['id', 'level']
    });

    const driversDetails = await Driver.findAll({
      where: { user_id: nearby },
      attributes: ['user_id', 'working_region']
    });

    const levelMap = new Map();
    for (const u of users) {
      levelMap.set(String(u.id), u.level || 'standard');
    }

    const regionMap = new Map();
    for (const d of driversDetails) {
      regionMap.set(String(d.user_id), d.working_region);
    }

    driversWithLevel = nearby.map((driverId) => {
      const level = levelMap.get(String(driverId)) || 'standard';
      let prioritySeconds = getDriverPrioritySeconds(level); // platinum 0, gold 1, silver 2, standard 3

      // PRIORITY LOGIC
      if (isPeakHour && rideDestRegion) {
        const driverHomeRegion = regionMap.get(String(driverId));
        // We need driver's current location to know if they are in opposite region.
        // But here we only have 'nearby' list which came from GEO search around START point.
        // So we can assume driver is near START point.
        const driverCurrentRegion = getRegion(lat, lng);

        // Condition: Driver is NOT in their home region AND Ride is going TO their home region
        if (driverHomeRegion && driverCurrentRegion && driverHomeRegion !== driverCurrentRegion) {
          if (rideDestRegion === driverHomeRegion) {
            // BINGO! Return Home Priority
            console.log(`[matchService] Priority Boost for driver ${driverId} (Home: ${driverHomeRegion}, Current: ${driverCurrentRegion}) -> Dest: ${rideDestRegion}`);
            prioritySeconds = 0;
          }
        }
      }

      return {
        driverId: String(driverId),
        level,
        prioritySeconds
      };
    });

    // Küçük prioritySeconds olan (platinum veya priority boost) önce işlenir
    driversWithLevel.sort((a, b) => a.prioritySeconds - b.prioritySeconds);
  }

  let count = 0;
  for (const d of driversWithLevel) {
    if (count >= BROADCAST_BATCH) break;

    const { driverId, level, prioritySeconds } = d;
    const meta = await redis.hgetall(`driver:${driverId}:meta`);

    if (!meta || !meta.available || meta.available !== '1') {
      console.log(`[matchService] Skipping driver:${driverId} - not available or meta missing`);
      continue;
    }

    const socketId = meta.socketId;
    const delayMs = prioritySeconds * 1000;

    setTimeout(async () => {
      try {
        if (socketId && io && io.to) {
          console.log(`[matchService] emitting request:incoming to driver:${driverId} socket:${socketId}`);
          io.to(socketId).emit('request:incoming', {
            ...payloadBase,
            sent_at: Date.now()
          });
        }

        try {
          const devices = await UserDevice.findAll({ where: { user_id: driverId } });
          const tokens = devices.map((d) => d.device_token);
          if (tokens.length > 0) {
            await sendPushToTokens(
              tokens,
              {
                title: 'Yeni taksi çağrısı',
                body: 'Yeni bir yolculuk isteği aldınız.'
              },
              {
                type: 'request_incoming',
                ride_id: String(ride.id),
                vehicle_type: vehicle_type
              }
            );
          }
        } catch (e) {
          console.warn('[matchService] driver push failed', driverId, e.message || e);
        }
      } catch (err) {
        console.warn('[matchService] emit to driver failed', driverId, err && err.message ? err.message : err);
      }
    }, delayMs);

    sentDrivers.push(driverId);
    count++;

    try {
      await RideRequest.create({
        ride_id: ride.id,
        driver_id: driverId,
        sent_at: new Date(),
        driver_response: 'no_response',
        timeout: false
      });
    } catch (e) {
      console.warn('[matchService] failed to create RideRequest record', e.message || e);
    }
  }

  try {
    console.log(
      `[matchService] ride ${ride.id} sentDrivers (with priority):`,
      driversWithLevel.slice(0, count)
    );
  } catch (e) { }

  const jobId = `ride_timeout_${ride.id}`;
  const timeoutDelayMs = Math.max(1000, ACCEPT_TIMEOUT_SECONDS * 1000);
  try {
    await rideTimeoutQueue.add(
      'ride-timeout',
      { rideId: ride.id },
      {
        jobId,
        delay: timeoutDelayMs,
        removeOnComplete: true,
        removeOnFail: true
      }
    );
    console.log(`[matchService] ride ${ride.id} scheduled timeout job ${jobId} delayMs=${timeoutDelayMs}`);
  } catch (e) {
    console.warn('[matchService] Could not schedule ride timeout job', e && e.message ? e.message : e);
  }

  return sentDrivers;
}

module.exports = { findNearbyDrivers, emitRideRequest };
