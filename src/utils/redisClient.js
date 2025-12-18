const IORedis = require('ioredis');

const redis = new IORedis({
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  connectTimeout: 10000, // 10 seconds
  maxRetriesPerRequest: 3 // Fail request if disconnected after 3 attempts
});

redis.on('connect', () => {
  console.log('Redis connected successfully');
});

redis.on('error', (err) => {
  console.error('Redis connection error:', err);
});

module.exports = redis;
