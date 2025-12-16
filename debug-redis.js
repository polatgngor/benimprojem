const Redis = require('ioredis');
const redis = new Redis({
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
    password: process.env.REDIS_PASSWORD || undefined
});

async function debugRedis() {
    console.log('--- REDIS DEBUG START ---');

    // 1. Scan for all driver meta keys
    const keys = await redis.keys('driver:*:meta');
    console.log(`Found ${keys.length} driver meta keys.`);

    for (const key of keys) {
        const meta = await redis.hgetall(key);
        const driverId = key.split(':')[1];
        console.log(`\nDriver ${driverId}:`);
        console.log('  Meta:', meta);

        // 2. Check GEO index for this driver
        // Assuming 'sari' for now, but should check all types if possible or infer from somewhere
        const geoPos = await redis.geopos('drivers:geo:sari', driverId);
        console.log('  Geo (sari):', geoPos);

        const geoPosTurkuaz = await redis.geopos('drivers:geo:turkuaz', driverId);
        if (geoPosTurkuaz && geoPosTurkuaz[0]) console.log('  Geo (turkuaz):', geoPosTurkuaz);

        const geoPosSiyah = await redis.geopos('drivers:geo:siyah', driverId);
        if (geoPosSiyah && geoPosSiyah[0]) console.log('  Geo (siyah):', geoPosSiyah);
    }

    console.log('\n--- REDIS DEBUG END ---');
    redis.disconnect();
}

debugRedis().catch(console.error);
