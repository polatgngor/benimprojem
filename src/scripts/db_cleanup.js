const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
    host: process.env.DB_HOST || '127.0.0.1',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || '',
    database: process.env.DB_NAME || 'taksibu',
    port: process.env.DB_PORT || 3306,
};

async function cleanupIndexes() {
    console.log('🧹 Starting Database Index Cleanup...');
    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);
        console.log('✅ Connected to database.');

        // 1. Get all indexes for 'users' table
        const [rows] = await connection.execute(`SHOW INDEX FROM users`);

        // Filter indexes related to 'phone'
        // We want to KEEP 'PRIMARY' and maybe one 'phone' index if it's correct, 
        // but safest is to drop ALL non-primary 'phone' related indexes and let Sequelize recreate the correct one.
        const phoneIndexes = rows.filter(row => row.Column_name === 'phone' && row.Key_name !== 'PRIMARY');

        console.log(`Found ${phoneIndexes.length} indexes on 'phone' column.`);

        if (phoneIndexes.length === 0) {
            console.log('No indexes to clean up.');
            return;
        }

        // Deduplicate by Key_name (since one index might have multiple rows if composite, but here likely single)
        const uniqueIndexNames = [...new Set(phoneIndexes.map(r => r.Key_name))];

        console.log(`Unique Index Names to DROP:`, uniqueIndexNames);

        for (const indexName of uniqueIndexNames) {
            try {
                console.log(`Dropping index: ${indexName}...`);
                await connection.execute(`DROP INDEX \`${indexName}\` ON users`);
                console.log(`✅ Dropped ${indexName}`);
            } catch (err) {
                console.error(`❌ Failed to drop ${indexName}:`, err.message);
            }
        }

        console.log('🎉 Cleanup complete! Now restart your server.');

    } catch (error) {
        console.error('❌ Fatal Error:', error);
    } finally {
        if (connection) await connection.end();
    }
}

cleanupIndexes();
