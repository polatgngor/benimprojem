'use strict';

/**
 * Taksibu backend level / referral / radius / driver priority / account delete testi
 *
 * Koşullar:
 * - Server http://localhost:3000 üzerinde çalışıyor
 * - MySQL ve Redis erişilebilir
 * - users tablosunda ref_code, referrer_id, ref_count, level alanları mevcut
 */

const axios = require('axios');
const Redis = require('ioredis');
const mysql = require('mysql2/promise');

const SERVER_URL = process.env.SERVER_URL || 'http://localhost:3000';
const MYSQL_HOST = process.env.DB_HOST || '127.0.0.1';
const MYSQL_PORT = process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 3306;
const MYSQL_USER = process.env.DB_USER || 'root';
const MYSQL_PASSWORD = process.env.DB_PASSWORD || '';
const MYSQL_DB = process.env.DB_NAME || 'taksibu';

const redis = new Redis({
  host: process.env.REDIS_HOST || '127.0.0.1',
  port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
  password: process.env.REDIS_PASSWORD || undefined
});

function now() {
  return new Date().toISOString();
}

async function httpGet(path, token) {
  return axios.get(`${SERVER_URL}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {}
  });
}

async function httpPost(path, body, token) {
  return axios.post(`${SERVER_URL}${path}`, body, {
    headers: token ? { Authorization: `Bearer ${token}` } : {}
  });
}

async function run() {
  console.log(`[${now()}] Starting level/referral test against ${SERVER_URL}`);

  const conn = await mysql.createConnection({
    host: MYSQL_HOST,
    port: MYSQL_PORT,
    user: MYSQL_USER,
    password: MYSQL_PASSWORD,
    database: MYSQL_DB
  });

  try {
    // 1) Health & metrics
    console.log(`[${now()}] Checking /health`);
    const health = await httpGet('/health');
    console.log('[health]', health.data);

    console.log(`[${now()}] Checking /metrics`);
    const metricsResp = await httpGet('/metrics');
    const hasDb = /taksibu_db_up 1/.test(metricsResp.data);
    const hasRedis = /taksibu_redis_up 1/.test(metricsResp.data);
    console.log(`[metrics] taksibu_db_up=${hasDb} taksibu_redis_up=${hasRedis}`);

    // 2) DB'de users tablosu level alanları var mı?
    console.log(`[${now()}] Verifying users table has level / ref columns`);
    const [rows] = await conn.query('SHOW COLUMNS FROM users');
    const cols = rows.map((r) => r.Field);
    const needed = ['ref_code', 'referrer_id', 'ref_count', 'level'];
    for (const c of needed) {
      if (!cols.includes(c)) {
        throw new Error(`users table missing column: ${c}`);
      }
    }
    console.log(`[${now()}] users table has all referral/level columns:`, needed.join(', '));

    // 3) Referrer user yarat (passenger)
    const refPhone = `+90${Math.floor(Math.random() * 900000000 + 100000000)}`;
    console.log(`[${now()}] Registering referrer passenger ${refPhone}`);
    const regRef = await httpPost('/api/auth/register', {
      first_name: 'Ref',
      last_name: 'User',
      phone: refPhone,
      password: 'Test1234',
      role: 'passenger'
    });
    const refUser = regRef.data.user;
    console.log(`[${now()}] Referrer created id=${refUser.id}, level=${refUser.level}, ref_code=${refUser.ref_code}`);

    // 4) 30 tane referanslı kayıt yap (referrer standard -> silver olmalı)
    const targetRefCount = 30;
    console.log(`[${now()}] Creating ${targetRefCount} referred passengers using ref_code=${refUser.ref_code}`);
    for (let i = 0; i < targetRefCount; i++) {
      const phone = `+90${Math.floor(Math.random() * 900000000 + 100000000)}`;
      await httpPost('/api/auth/register', {
        first_name: 'Refed',
        last_name: `User${i}`,
        phone,
        password: 'Test1234',
        role: 'passenger',
        ref_code: refUser.ref_code
      });
      if ((i + 1) % 5 === 0) {
        console.log(`[${now()}]   referred count: ${i + 1}`);
      }
    }

    // Referrer'ın level/ref_count son hali
    const [refRow] = await conn.query('SELECT id, ref_count, level FROM users WHERE id = ?', [refUser.id]);
    console.log(`[${now()}] Referrer DB row:`, refRow[0]);
    if (refRow[0].ref_count < 25 || refRow[0].level !== 'silver') {
      console.warn(
        `[WARN] referrer level expected= silver (>=25 referrals), got level=${refRow[0].level}, ref_count=${refRow[0].ref_count}`
      );
    }

    // 5) Referrer ile login ol (ride açmak için)
    console.log(`[${now()}] Logging in referrer to get token`);
    const loginRef = await httpPost('/api/auth/login', {
      phone: refPhone,
      password: 'Test1234'
    });
    const refToken = loginRef.data.accessToken;
    console.log(`[${now()}] Referrer login ok, token length=${refToken.length}`);

    // 6) Driver'lar: standard, gold, platinum seviyelerinde 3 driver
    console.log(`[${now()}] Creating 3 drivers with different levels`);

    async function registerDriverWithLevel(level) {
      const phone = `+90${Math.floor(Math.random() * 900000000 + 100000000)}`;
      const reg = await httpPost('/api/auth/register', {
        first_name: level.toUpperCase(),
        last_name: 'Driver',
        phone,
        password: 'Test1234',
        role: 'driver'
      });
      const user = reg.data.user;

      // DB'de level'ini set edelim (normalde ref_count ile gelir, burada direkt override ediyoruz)
      await conn.query('UPDATE users SET level = ? WHERE id = ?', [level, user.id]);

      console.log(`[${now()}] Driver created id=${user.id}, phone=${phone}, level=${level}`);
      return { id: user.id, phone };
    }

    const standardDriver = await registerDriverWithLevel('standard');
    const goldDriver = await registerDriverWithLevel('gold');
    const platinumDriver = await registerDriverWithLevel('platinum');

    // 7) Bu driver'ları Redis GEO'ya ekle ve available yap
    const GEO_KEY = 'drivers:geo:sari';
    const DRIVER_POSITION = { lat: 41.015137, lng: 28.97953 }; // Taksim civarı

    async function setupDriverInRedis(driver) {
      await redis.geoadd(GEO_KEY, DRIVER_POSITION.lng, DRIVER_POSITION.lat, String(driver.id));
      await redis.hset(`driver:${driver.id}:meta`, 'available', '1');
      // socketId normalde socket.io bağlantısıyla gelir, bu testte yok; önemli olan sıralama log'unu görmek
      console.log(`[${now()}] Driver ${driver.id} added to GEO and marked available`);
    }

    await setupDriverInRedis(standardDriver);
    await setupDriverInRedis(goldDriver);
    await setupDriverInRedis(platinumDriver);

    // 8) Referrer (silver passenger) ile ride aç
    console.log(`[${now()}] Creating ride as referrer passenger (should use silver radius=2.5km)`);
    const rideResp = await httpPost(
      '/api/rides',
      {
        start_lat: DRIVER_POSITION.lat,
        start_lng: DRIVER_POSITION.lng,
        start_address: 'Test Start',
        end_lat: DRIVER_POSITION.lat + 0.01,
        end_lng: DRIVER_POSITION.lng + 0.01,
        end_address: 'Test End',
        vehicle_type: 'sari',
        payment_method: 'nakit',
        options: {}
      },
      refToken
    );
    const ride = rideResp.data.ride;
    console.log(`[${now()}] Ride created id=${ride.id}, status=${ride.status}`);
    console.log(
      `[${now()}] Check server logs for [matchService] ride ${ride.id} nearby candidates and prioritized drivers output`
    );
    console.log(
      `[${now()}] Expect prioritized order: platinum (${platinumDriver.id}) > gold (${goldDriver.id}) > standard (${standardDriver.id})`
    );

    // 9) Hesap silme testi: referrer hesabını sil
    console.log(`[${now()}] Deleting referrer account via DELETE /api/profile/account`);
    await axios.delete(`${SERVER_URL}/api/profile/account`, {
      headers: { Authorization: `Bearer ${refToken}` }
    });
    console.log(`[${now()}] Account delete request finished`);

    // DB'de is_active durumu
    const [refAfterDelete] = await conn.query('SELECT id, is_active FROM users WHERE id = ?', [refUser.id]);
    console.log(`[${now()}] Referrer after delete:`, refAfterDelete[0]);

    // Silinen hesapla tekrar login denemesi (muhtemelen başarısız olmalı, ama şu an login is_active'e bakmıyorsa yine de dönebilir)
    console.log(`[${now()}] Trying to login deleted user again (just to see behavior)`);
    try {
      await httpPost('/api/auth/login', {
        phone: refPhone,
        password: 'Test1234'
      });
      console.warn(
        `[WARN] Deleted user could still login. Eğer istemiyorsan logincontroller'da is_active kontrolü eklemeliyiz.`
      );
    } catch (e) {
      console.log(`[${now()}] Login failed for deleted user as expected:`, e.response && e.response.data);
    }

    console.log(`[${now()}] Level / referral / radius / driver priority / account delete test finished.`);
  } catch (err) {
    console.error(`[${now()}] TEST FAILED`, err && err.response ? err.response.data || err.response.statusText : err);
  } finally {
    await conn.end();
    await redis.quit();
  }
}

run().catch((e) => {
  console.error('Fatal error in test script', e);
  process.exit(1);
});