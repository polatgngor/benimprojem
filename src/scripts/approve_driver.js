require('dotenv').config();
const { sequelize, Driver, User } = require('../models');
const logger = require('../lib/logger');

async function approveDriver() {
    // Expected usage: npm run driver:approve -- --phone 905xxxxxxxxx
    // Or just argument: node src/scripts/approve_driver.js 905xxxxxxxxx

    let phone = process.argv[2];
    if (phone === '--') {
        phone = process.argv[3];
    }

    if (!phone) {
        logger.error('❌ Usage: npm run driver:approve -- <PHONE_NUMBER>');
        logger.error('Example: npm run driver:approve -- 905072051616');
        process.exit(1);
    }

    // Clean phone number (similar to smsService logic)
    phone = phone.replace(/\D/g, '');
    if (phone.length <= 10 && phone.startsWith('5')) {
        phone = '90' + phone;
    }

    try {
        const user = await User.findOne({ where: { phone } });
        if (!user) {
            logger.error(`❌ User not found with phone: ${phone}`);
            process.exit(1);
        }

        if (user.role !== 'driver') {
            logger.error(`❌ User ${phone} is NOT a driver (Role: ${user.role})`);
            process.exit(1);
        }

        const driver = await Driver.findOne({ where: { user_id: user.id } });
        if (!driver) {
            logger.error(`❌ Driver profile not found for user ID: ${user.id}`);
            process.exit(1);
        }

        if (driver.status === 'approved') {
            logger.info(`✅ Driver ${phone} is ALREADY approved.`);
            process.exit(0);
        }

        // Approve
        driver.status = 'approved';
        driver.is_available = false; // Start as offline
        await driver.save();

        logger.info(`
        🎉 SUCCESS!
        -------------------------------------------
        Driver Approved: ${user.first_name} ${user.last_name}
        Phone:           ${user.phone}
        Vehicle Type:    ${driver.vehicle_type}
        New Status:      ${driver.status.toUpperCase()}
        -------------------------------------------
        `);

        process.exit(0);

    } catch (error) {
        logger.error('❌ FATAL ERROR:', error);
        process.exit(1);
    }
}

approveDriver();
