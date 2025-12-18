require('dotenv').config();
const http = require('http');
const app = require('./src/app');
const { sequelize } = require('./src/models');
const initSockets = require('./src/sockets');
const logger = require('./src/lib/logger');
const { rideTimeoutQueue } = require('./src/queues/rideTimeoutQueue');
const metrics = require('./src/metrics');
const Redis = require('ioredis');

// start worker (side-effect require)
require('./src/workers/rideTimeoutWorker');
const cleanupStaleDrivers = require('./src/cron/cleanupDrivers');


const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

const redis = new Redis({
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
  password: process.env.REDIS_PASSWORD || undefined
});

async function start() {
  try {
    await sequelize.authenticate();
    logger.info('✅ MySQL connected (Sequelize).');
    await sequelize.sync({ alter: false });
    logger.info('✅ Sequelize models synced.');

    // Init Socket.IO (attaches to server)
    initSockets(server);
    server.listen(PORT, () => {
      logger.info(`🚀 Server listening on http://localhost:${PORT}`);
    });

    // Periodic health/queue polling for metrics
    setInterval(async () => {
      try {
        // queue counts
        const counts = await rideTimeoutQueue.getJobCounts('waiting', 'active', 'completed', 'failed', 'delayed');
        metrics.queueWaiting.set({ queue: 'ride-timeout-queue' }, counts.waiting || 0);
        metrics.queueActive.set({ queue: 'ride-timeout-queue' }, counts.active || 0);
        metrics.queueDelayed.set({ queue: 'ride-timeout-queue' }, counts.delayed || 0);
        metrics.queueFailed.set({ queue: 'ride-timeout-queue' }, counts.failed || 0);
        metrics.queueCompleted.set({ queue: 'ride-timeout-queue' }, counts.completed || 0);
      } catch (e) {
        logger.warn({ err: e }, 'Could not fetch queue counts');
      }

      try {
        // redis connectivity
        const pong = await redis.ping();
        metrics.redisUp.set(pong === 'PONG' ? 1 : 0);
      } catch (e) {
        metrics.redisUp.set(0);
        logger.error({ err: e }, 'Redis health check failed');
      }

      try {
        // db connectivity
        await sequelize.authenticate();
        metrics.dbUp.set(1);
      } catch (e) {
        metrics.dbUp.set(0);
        logger.error({ err: e }, 'DB health check failed');
      }
    }, parseInt(process.env.METRICS_POLL_INTERVAL_MS || '5000', 10));

    // Cleanup Job (Every 1 minute)
    setInterval(() => {
      cleanupStaleDrivers();
    }, 60 * 1000);

  } catch (err) {
    logger.error('Startup error:', err && err.stack ? err.stack : err);
    process.exit(1);
  }
}

start();