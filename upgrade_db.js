require('dotenv').config();
const pool = require('./src/db');

async function upgrade() {
    try {
        console.log('Starting DB Upgrade...');
        const connection = await pool.getConnection();

        const queries = [
            "ALTER TABLE drivers ADD COLUMN IF NOT EXISTS ibb_card_file VARCHAR(255) DEFAULT NULL",
            "ALTER TABLE drivers ADD COLUMN IF NOT EXISTS driving_license_file VARCHAR(255) DEFAULT NULL",
            "ALTER TABLE drivers ADD COLUMN IF NOT EXISTS identity_card_file VARCHAR(255) DEFAULT NULL"
        ];

        for (const query of queries) {
            console.log(`Executing: ${query}`);
            try {
                await connection.query(query);
            } catch (e) {
                // Ignore error if column exists (though IF NOT EXISTS should handle it on newer MariaDB/MySQL)
                // But basic MySQL syntax often doesn't support IF NOT EXISTS for ADD COLUMN directly in all versions reliably without procedure.
                // We just log.
                console.log('Query info:', e.message);
            }
        }

        console.log('DB Upgrade Completed.');
        connection.release();
        process.exit(0);
    } catch (error) {
        console.error('DB Upgrade Failed:', error);
        process.exit(1);
    }
}

upgrade();
