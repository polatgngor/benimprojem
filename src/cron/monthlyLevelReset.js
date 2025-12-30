const { sequelize } = require('../../models');
const logger = require('../lib/logger');

async function resetMonthlyLevels() {
    const t = await sequelize.transaction();
    try {
        logger.info('🔄 Starting Monthly Level Reset...');

        // Reset ref_count to 0 and level to 'standard' for ALL users
        // Assuming we want to reset everyone.

        await sequelize.query(
            "UPDATE users SET ref_count = 0, level = 'standard' WHERE role = 'passenger' OR role = 'driver'",
            { transaction: t }
        );

        await t.commit();
        logger.info('✅ Monthly Level Reset Completed Successfully.');
    } catch (error) {
        await t.rollback();
        logger.error({ err: error }, '❌ Monthly Level Reset Failed');
    }
}

module.exports = resetMonthlyLevels;
