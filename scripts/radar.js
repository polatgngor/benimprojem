const Redis = require('ioredis');
const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config({ path: '../.env' });

// Setup Redis
const redis = new Redis({
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
    password: process.env.REDIS_PASSWORD || undefined
});

// Setup DB (Minimal connection)
const sequelize = new Sequelize(
    process.env.DB_NAME,
    process.env.DB_USER,
    process.env.DB_PASS,
    {
        host: process.env.DB_HOST,
        dialect: 'mysql',
        logging: false,
        port: process.env.DB_PORT || 3306
    }
);

// Define Minimal Models
const RideRequest = sequelize.define('RideRequest', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    ride_id: DataTypes.INTEGER,
    driver_id: DataTypes.INTEGER,
    sent_at: DataTypes.DATE,
    driver_response: DataTypes.STRING
}, { tableName: 'RideRequests', timestamps: false });

const TYPES = ['sari', 'turkuaz', 'siyah', 'vip', '8+1'];

async function scan() {
    console.clear();
    console.log(`📡 TAKSIBU SYSTEM RADAR - ${new Date().toLocaleTimeString()} 📡`);
    console.log('====================================================');

    // 1. SCAN DRIVERS
    console.log('\n🚕 ONLINE DRIVERS (Redis GEO Index):');
    let totalOnline = 0;

    for (const type of TYPES) {
        const key = `drivers:geo:${type}`;
        const drivers = await redis.georadius(key, 28.97, 41.00, 200, 'km', 'WITHDIST'); // Wide search Istanbul

        if (drivers.length > 0) {
            // console.log(`   [${type.toUpperCase()}] Found: ${drivers.length}`);
            for (const d of drivers) {
                totalOnline++;
                const driverId = d[0];
                const dist = d[1];

                // Get Meta
                const meta = await redis.hgetall(`driver:${driverId}:meta`);
                const isAvail = meta.available === '1';
                const hasSocket = !!meta.socketId;
                const statusIcon = (isAvail && hasSocket) ? '✅ READY' : '⚠️ ISSUE';

                console.log(`   [${type}] Driver ${driverId.padEnd(5)} | ${statusIcon} | Socket: ${hasSocket ? 'OK' : 'MISSING'} | Avail: ${meta.available} | Dist to Center: ${dist}km`);
            }
        }
    }

    if (totalOnline === 0) {
        console.log('   ❌ NO DRIVERS FOUND ONLINE (Check Redis/App Config)');
    }

    // 2. SCAN RECENT REQUESTS
    console.log('\n📨 LAST 5 RIDE REQUESTS (DB):');
    try {
        const requests = await RideRequest.findAll({
            limit: 5,
            order: [['sent_at', 'DESC']]
        });

        if (requests.length === 0) {
            console.log('   (No requests found)');
        }

        requests.forEach(r => {
            const age = Math.round((Date.now() - new Date(r.sent_at).getTime()) / 1000);
            console.log(`   Ride ${r.ride_id} -> Driver ${r.driver_id} | Status: ${r.driver_response} | Age: ${age}s`);
        });
    } catch (e) {
        console.log('   (DB Error reading requests)', e.message);
    }

    console.log('\n----------------------------------------------------');
    console.log('Press Ctrl+C to exit. Refreshing every 2s...');
}

// Loop
async function start() {
    try {
        await sequelize.authenticate();
        setInterval(scan, 2000);
        scan();
    } catch (e) {
        console.error('Startup Failed:', e);
    }
}

start();
