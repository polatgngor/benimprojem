require('dotenv').config();
const Redis = require('ioredis');
const { sequelize } = require('./src/models');

const redis = new Redis({
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
    password: process.env.REDIS_PASSWORD || undefined
});

async function cleanRedis() {
    console.log('--- REDIS CLEANUP START ---');

    try {
        // 1. Get all valid driver IDs from MySQL
        const [results] = await sequelize.query("SELECT id FROM users WHERE role = 'driver'");
        const validDriverIds = new Set(results.map(r => String(r.id)));
        console.log(`Found ${validDriverIds.size} valid drivers in DB.`);

        // 2. Scan Redis GEO keys
        const vehicleTypes = ['sari', 'turkuaz', 'siyah'];
        for (const type of vehicleTypes) {
            const key = `drivers:geo:${type}`;
            const members = await redis.zrange(key, 0, -1);
            console.log(`Checking ${key}: found ${members.length} members.`);

            for (const member of members) {
                if (!validDriverIds.has(member)) {
                    console.log(`  Removing stale driver ${member} from ${key}`);
                    await redis.zrem(key, member);
                    await redis.del(`driver:${member}:meta`);
                }
            }
        }

        // 3. Scan for orphaned meta keys
        const metaKeys = await redis.keys('driver:*:meta');
        for (const key of metaKeys) {
            const driverId = key.split(':')[1];
            if (!validDriverIds.has(driverId)) {
                console.log(`  Removing orphaned meta key ${key}`);
                await redis.del(key);
            }
        }

    } catch (err) {
        console.error('Error during cleanup:', err);
    } finally {
        await sequelize.close();
        redis.disconnect();
        console.log('--- REDIS CLEANUP END ---');
    }
}

cleanRedis();
