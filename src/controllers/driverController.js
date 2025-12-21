const { Driver, Ride, Wallet, WalletTransaction, User, sequelize } = require('../models');
const { Op } = require('sequelize');

async function updatePlate(req, res) {
  try {
    const userId = req.user.userId;
    const { vehicle_plate } = req.body;
    if (!vehicle_plate) return res.status(400).json({ message: 'vehicle_plate required' });
    const driver = await Driver.findOne({ where: { user_id: userId } });
    if (!driver) return res.status(404).json({ message: 'Driver record not found' });
    driver.vehicle_plate = vehicle_plate;
    await driver.save();
    return res.json({ ok: true, driver });
  } catch (err) {
    console.error('updatePlate err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

/**
 * GET /api/driver/earnings?from=YYYY-MM-DD&to=YYYY-MM-DD
 * returns sum of fare_actual for completed rides where driver_id = userId
 */
async function getEarnings(req, res) {
  try {
    const userId = req.user.userId;
    // Log request params
    console.log('[getEarnings] Request for user:', userId, 'Query:', req.query);

    // Fix: Force UTC if 'Z' is missing to prevent local time interpretation
    const parseDate = (d) => {
      if (!d) return null;
      if (!d.endsWith('Z')) return new Date(d + 'Z');
      return new Date(d);
    };

    let from = parseDate(req.query.from);
    let to = parseDate(req.query.to);
    const period = req.query.period; // 'daily', 'weekly', 'monthly'

    // Server-side Date Calculation (Turkey Time: UTC+3)
    if (period) {
      const now = new Date();
      // Add 3 hours to get Turkey time, then truncate to start of period, then subtract 3 hours to get UTC again
      // Or cleaner: Work with UTC dates but aligning to Turkey day boundaries if needed.
      // Easiest: Just use standard UTC days for now, but ensure 'daily' means 'from 00:00 UTC today'.

      // Let's settle for simple UTC based calculation which is consistent for Server
      // Ideally, we should use libraries like 'moment-timezone' but we don't have it installed.
      // We will do a manual offset of +3 hours for "Turkey Day Start".

      const offsetMs = 3 * 60 * 60 * 1000;
      const turkeyTime = new Date(now.getTime() + offsetMs);

      if (period === 'daily') {
        // Start of Turkey Day: yyyy-mm-dd 00:00:00
        turkeyTime.setUTCHours(0, 0, 0, 0);
        from = new Date(turkeyTime.getTime() - offsetMs); // Back to UTC
        to = new Date(); // Now
      } else if (period === 'weekly') {
        const day = turkeyTime.getUTCDay(); // 0 (Sun) to 6 (Sat)
        const diff = turkeyTime.getUTCDate() - day + (day === 0 ? -6 : 1); // Adjust to get Monday
        turkeyTime.setUTCDate(diff);
        turkeyTime.setUTCHours(0, 0, 0, 0);
        from = new Date(turkeyTime.getTime() - offsetMs);
        to = new Date();
      } else if (period === 'monthly') {
        turkeyTime.setUTCDate(1);
        turkeyTime.setUTCHours(0, 0, 0, 0);
        from = new Date(turkeyTime.getTime() - offsetMs);
        to = new Date();
      }
    }

    const where = { driver_id: userId, status: 'completed' };
    if (from || to) {
      where.created_at = {};
      if (from) where.created_at[Op.gte] = from;
      if (to) where.created_at[Op.lte] = to;
    }

    console.log('[getEarnings] Constructed Where:', JSON.stringify(where, null, 2));

    console.log('[getEarnings] Constructed Where:', JSON.stringify(where, null, 2));

    // Parallel Fetching: Rides, User Stats, Rating
    const [rides, user, ratingData] = await Promise.all([
      Ride.findAll({
        where,
        attributes: ['id', 'created_at', 'fare_actual', 'start_address', 'end_address', 'payment_method'],
        order: [['created_at', 'DESC']]
      }),
      User.findByPk(userId, { attributes: ['ref_count', 'level', 'role'] }),
      Rating.findOne({
        where: { rated_id: userId },
        attributes: [[sequelize.fn('AVG', sequelize.col('stars')), 'avg_rating']]
      })
    ]);

    console.log('[getEarnings] Found rides count:', rides.length);

    // if driver, include driver details
    let driver = null;
    if (user.role === 'driver') {
      // Parallel Fetch: Driver Details + Wallet
      const [driverRecord, wallet] = await Promise.all([
        Driver.findOne({
          where: { user_id: userId },
          attributes: ['vehicle_plate', 'vehicle_type', 'status', 'is_available'],
          raw: true
        }),
        Wallet.findOne({ where: { user_id: userId }, raw: true })
      ]);

      if (driverRecord) {
        driver = driverRecord;
        driver.wallet_balance = wallet ? wallet.balance : 0.00;
      }
    }
    const total = rides.reduce((s, r) => s + (parseFloat(r.fare_actual || 0) || 0), 0);
    const count = rides.length;
    const avgRating = ratingData ? parseFloat(ratingData.dataValues.avg_rating || 0).toFixed(1) : "5.0";

    // Turkey Time Offset (UTC+3)
    const { formatTurkeyDate } = require('../utils/dateUtils');

    const ridesFormatted = rides.map(r => {
      const plain = r.toJSON();
      plain.date_formatted = formatTurkeyDate(r.created_at);
      return plain;
    });

    return res.json({
      total,
      count,
      rides: ridesFormatted,
      ref_count: user ? user.ref_count : 0,
      level: user ? user.level : 1,
      rating: avgRating
    });
  } catch (err) {
    console.error('getEarnings err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

module.exports = { updatePlate, getEarnings };