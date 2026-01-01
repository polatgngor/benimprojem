const { Ride, RideMessage, Rating, User, Driver, sequelize } = require('../models');
const { Op } = require('sequelize');
const { getRouteDistanceMeters, computeFareEstimate } = require('../services/fareService');
const rideService = require('../services/rideService');
const { VEHICLE_TYPES } = require('../config/constants');

/*
* POST /api/rides
* Ride oluşturma
*/
async function createRide(req, res) {
  try {
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

    if (!start_lat || !start_lng || !vehicle_type || !payment_method) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const { ride, sentDriversCount } = await rideService.createRide({
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
    });

    return res.status(201).json({
      ride,
      code4: ride.code4,
      sentDriversCount
    });

  } catch (err) {
    console.error('createRide err', err);
    if (err.message === 'Invalid vehicle_type') return res.status(400).json({ message: 'Invalid vehicle_type' });
    if (err.message === 'Passenger not found') return res.status(404).json({ message: 'Passenger not found' });
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

    // Fetch rating explicitly
    const RatingModel = require('../models').Rating;
    const myRating = await RatingModel.findOne({
      where: {
        ride_id: ride.id,
        rater_id: user.userId
      }
    });

    const { formatTurkeyDate } = require('../utils/dateUtils');
    const plain = ride.toJSON();
    plain.formatted_date = formatTurkeyDate(ride.created_at);

    // Attach rating
    plain.my_rating = myRating ? myRating.toJSON() : null;

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

    if (req.query.status) {
      where.status = req.query.status;
    } else {
      // Default: Exclude auto_rejected and cancelled (unless explicitly requested)
      where.status = {
        [Op.notIn]: ['auto_rejected', 'cancelled']
      };
    }

    const rides = await Ride.findAll({
      where,
      order: [['created_at', 'DESC']],
      limit,
      offset,
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

    // Fetched basic rides. Now need to attach "my_rating" to each.
    // Efficient way: Fetch all ratings by this user for these ride IDs.
    const rideIds = rides.map(r => r.id);
    const RatingModel = require('../models').Rating;
    const myRatings = await RatingModel.findAll({
      where: {
        rater_id: user.userId,
        ride_id: { [Op.in]: rideIds }
      }
    });

    // Map ride_id -> rating
    const ratingMap = {};
    myRatings.forEach(r => {
      ratingMap[r.ride_id] = r.toJSON();
    });

    // Turkey Time Offset (UTC+3)
    const { formatTurkeyDate } = require('../utils/dateUtils');

    const ridesFormatted = rides.map(r => {
      const plain = r.toJSON();
      plain.formatted_date = formatTurkeyDate(r.created_at);
      // Backward Compatibility
      if (plain.passenger) plain.passenger.profile_photo = plain.passenger.profile_picture;
      if (plain.driver) plain.driver.profile_photo = plain.driver.profile_picture;

      // Attach my_rating
      plain.my_rating = ratingMap[plain.id] || null;

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
  try {
    const user = req.user;
    const rideId = req.params.id;
    const { reason } = req.body || {};

    const result = await rideService.cancelRide(rideId, user.userId, user.role, reason);

    return res.json({ ok: true, ride_id: result.rideId });
  } catch (err) {
    console.error('cancelRide err', err);
    if (err.message === 'Ride not found') return res.status(404).json({ message: 'Ride not found' });
    if (err.message === 'Forbidden') return res.status(403).json({ message: 'Forbidden' });
    if (err.message.includes('Cannot cancel ride')) return res.status(400).json({ message: err.message });

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

    const rating = await rideService.rateRide(rideId, user.userId, stars, comment);

    return res.status(201).json({ ok: true, rating });
  } catch (err) {
    console.error('rateRide err', err);
    if (err.message === 'Invalid stars') return res.status(400).json({ message: 'Invalid stars' });
    if (err.message === 'Ride not found') return res.status(404).json({ message: 'Ride not found' });
    if (err.message === 'Forbidden') return res.status(403).json({ message: 'Forbidden' });
    if (err.message === 'No driver to rate') return res.status(400).json({ message: 'No driver to rate' });
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