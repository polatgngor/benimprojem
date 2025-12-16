const express = require('express');
const morgan = require('morgan');
const authRoutes = require('./routes/auth');
const ridesRoutes = require('./routes/rides');
const complaintsRoutes = require('./routes/complaints');
const adminRoutes = require('./routes/admin');
const profileRoutes = require('./routes/profile');
const notificationsRoutes = require('./routes/notifications');
const driverRoutes = require('./routes/driver');
const announcementsRoutes = require('./routes/announcements');
const savedPlacesRoutes = require('./routes/savedPlaces'); // NEW

const metrics = require('./metrics'); // prom-client metrics
const logger = require('./lib/logger');

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// HTTP logging - morgan (stdout) but use pino for structured logs elsewhere
app.use(morgan('combined'));

// Serve uploaded files
app.use('/uploads', express.static('uploads'));

// Prometheus HTTP metrics middleware
app.use((req, res, next) => {
  const end = metrics.httpRequestDuration.startTimer();
  // Use route path if available, otherwise use req.path
  // note: in Express route may be unknown before routing; use req.route?.path later if needed
  res.on('finish', () => {
    const route = req.route && req.route.path ? req.route.path : req.path;
    const labels = { method: req.method, route, status_code: String(res.statusCode) };
    metrics.httpRequestsTotal.inc(labels);
    end(labels);
  });
  next();
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/rides', ridesRoutes);
app.use('/api/complaints', complaintsRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/announcements', announcementsRoutes);
app.use('/api/saved-places', savedPlacesRoutes); // NEW
app.use('/api/support', require('./routes/support')); // Support System

// health
app.get('/health', (req, res) => res.json({ ok: true, ts: Date.now() }));

// prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', metrics.client.register.contentType);
    res.send(await metrics.client.register.metrics());
  } catch (err) {
    logger.error({ err }, 'Failed to collect metrics');
    res.status(500).send('Error collecting metrics');
  }
});

module.exports = app;