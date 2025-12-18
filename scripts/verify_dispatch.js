const Redis = require('ioredis');
require('dotenv').config({ path: '../.env' }); // Adjust path if needed

const redis = new Redis({
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
    password: process.env.REDIS_PASSWORD || undefined
});

const TEST_LAT = 41.0082;
const TEST_LNG = 28.9784;
const DRIVER_ID = '99999';
const TYPE = 'sari'; // Lowercase confirmed

async function runTest() {
    console.log('--- STARTING DISPATCH VERIFICATION ---');

    // 1. Clean up potential old test data
    await redis.zrem(`drivers:geo:${TYPE}`, DRIVER_ID);

    // 2. Add Test Driver to Redis
    console.log(`1. Adding Test Driver ${DRIVER_ID} at ${TEST_LAT}, ${TEST_LNG} (Type: ${TYPE})`);
    await redis.geoadd(`drivers:geo:${TYPE}`, TEST_LNG, TEST_LAT, DRIVER_ID);

    // 3. Verify Driver is in Redis
    const distCheck = await redis.geopos(`drivers:geo:${TYPE}`, DRIVER_ID);
    console.log('2. Verification - Driver Position in Redis:', distCheck);

    if (!distCheck || !distCheck[0]) {
        console.error('❌ FATAL: Driver could not be added to Redis GEO index!');
        process.exit(1);
    } else {
        console.log('✅ Driver correctly indexed.');
    }

    // 4. Simulate Match Service Search (Radius 5km)
    console.log('3. Searching for drivers within 5km...');
    const results = await redis.georadius(
        `drivers:geo:${TYPE}`,
        TEST_LNG,
        TEST_LAT,
        5,
        'km',
        'WITHDIST',
        'ASC'
    );

    console.log('4. RAW Redis Results:', JSON.stringify(results));

    const found = results.find(r => r[0] === DRIVER_ID);
    if (found) {
        console.log(`✅ SUCCESS: Driver found! Distance: ${found[1]}km`);
    } else {
        console.log('❌ FAILURE: Driver NOT found in search results.');
    }

    // Cleanup
    await redis.zrem(`drivers:geo:${TYPE}`, DRIVER_ID);
    redis.disconnect();
}

runTest();
