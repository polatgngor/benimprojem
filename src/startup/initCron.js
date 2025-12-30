const cleanupStaleDrivers = require('../cron/cleanupDrivers');
const logger = require('../lib/logger');

module.exports = function initCron() {
    logger.info('Initializing Cron Jobs...');

    // Cleanup Job (Every 1 minute)
    setInterval(() => {
        cleanupStaleDrivers();
    }, 60 * 1000);

    // Monthly Level Reset (requires 'node-cron')
    // Runs at 00:00 on the 1st day of every month
    try {
        const cron = require('node-cron');
        const resetMonthlyLevels = require('../cron/monthlyLevelReset');

        cron.schedule('0 0 1 * *', () => {
            resetMonthlyLevels();
        });
        logger.info('📅 Monthly Level Reset Job Scheduled (0 0 1 * *)');
    } catch (e) {
        logger.warn('⚠️ node-cron not found. Monthly reset job NOT scheduled. Run "npm install node-cron"');
    }
};
