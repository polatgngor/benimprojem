'use strict';

/**
 * E2E FCM + Socket test script for Taksibu backend
 *
 * Bu script aşağıdaki akışı test eder:
 * - Passenger ve driver register + login
 * - Admin register + login
 * - Admin driver'ı onaylar
 * - Driver için user_devices'e TEST_DRIVER_FCM_TOKEN, passenger için TEST_PASSENGER_FCM_TOKEN eklenir
 * - Driver Socket.IO ile bağlanır, availability set edilir
 * - Passenger Socket.IO ile bağlanır
 * - Passenger REST ile ride oluşturur (POST /api/rides)
 *   => Driver sokette 'request:incoming' almalı
 *   => DRIVER cihazında FCM 'request_incoming' tipi gelmeli
 * - Driver soketten 'driver:accept_request' ile çağrıyı kabul eder
 *   => Passenger sokette 'ride:assigned' almalı
 *   => PASSENGER cihazında FCM 'ride_assigned' gelmeli (assignService.js)
 * - Driver 'driver:arrived' gönderir
 *   => Passenger sokette 'driver:arrived' alır
 *   => PASSENGER cihazında FCM 'driver_arrived' gelmeli
 * - Chat: driver 'ride:message' gönderir
 *   => Passenger sokette 'ride:message' alır
 *   => PASSENGER FCM'de 'ride_chat_message' alır
 *
 * Kullanım:
 * 1) Sunucuyu başlat: node server.js
 * 2) Gerekliyse test bağımlılıkları: npm install axios socket.io-client mysql2
 * 3) Bu dosyada DRIVER/PASSENGER tokenlerini kontrol et.
 * 4) Çalıştır: node test/e2e_fcm_push_test.js
 */

const axios = require('axios');
const { io } = require('socket.io-client');
const mysql = require('mysql2/promise');

const SERVER_URL = process.env.SERVER_URL || 'http://localhost:3000';
const MYSQL_HOST = process.env.DB_HOST || '127.0.0.1';
const MYSQL_PORT = process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 3306;
const MYSQL_USER = process.env.DB_USER || 'root';
const MYSQL_PASS = process.env.DB_PASS || '';
const MYSQL_DB = process.env.DB_NAME || 'taksibu';

// Senin verdiğin tokenler
const DRIVER_FCM_TOKEN =
  'fJhPAAD6Q-ux778WffxiwY:APA91bFYQ7AU8O-cp_JZ7Jyu2db_kj4rhgDSyehj_V2MjDR9sIX2kvqQcD00jJVVnspLpUxgJPnDuKE76advMnjufwLzWNo-hjDZebIN7h4sj_xJAasEPQs';
const PASSENGER_FCM_TOKEN =
  'ea6WdNQfSMWKBXNnlmeupT:APA91bEff9jepjJItOJgxbZUHlmFTHa55tnlL0eMis_Wy1yysRfDkzWkU0L0PSDmmiSdzNXtzM9obved4c7zAFg_GgsAakbFjHmMRZBqwA7hOSWG44hS0yI';

function now() {
  return new Date().toISOString();
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function mysqlQuery(sql, params = []) {
  const conn = await mysql.createConnection({
    host: MYSQL_HOST,
    port: MYSQL_PORT,
    user: MYSQL_USER,
    password: MYSQL_PASS,
    database: MYSQL_DB
  });
  try {
    const [rows] = await conn.execute(sql, params);
    return rows;
  } finally {
    await conn.end();
  }
}

async function httpPost(path, data, token) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await axios.post(`${SERVER_URL}${path}`, data, { headers });
  return res.data;
}

async function httpGet(path, token) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await axios.get(`${SERVER_URL}${path}`, { headers });
  return res.data;
}

async function main() {
  console.log(`[${now()}] E2E FCM + Socket test starting...`);

  // 1) Admin, passenger, driver register + login
  console.log(`[${now()}] Registering passenger, driver, admin...`);

  const passengerPhone = `+90${Math.floor(5000000000 + Math.random() * 4000000000)}`;
  const driverPhone = `+90${Math.floor(5000000000 + Math.random() * 4000000000)}`;
  const adminPhone = `+90${Math.floor(5000000000 + Math.random() * 4000000000)}`;

  // Passenger register
  const passengerReg = await httpPost('/api/auth/register', {
    first_name: 'FCMTest',
    last_name: 'Passenger',
    phone: passengerPhone,
    password: 'Test1234',
    role: 'passenger'
  });
  const passenger = passengerReg.user;
  console.log(`[${now()}] Passenger registered id=${passenger.id}, phone=${passenger.phone}`);

  // Driver register
  const driverReg = await httpPost('/api/auth/register', {
    first_name: 'FCMTest',
    last_name: 'Driver',
    phone: driverPhone,
    password: 'Test1234',
    role: 'driver'
  });
  const driver = driverReg.user;
  console.log(`[${now()}] Driver registered id=${driver.id}, phone=${driver.phone}`);

  // Admin register
  const adminReg = await httpPost('/api/auth/register', {
    first_name: 'FCMTest',
    last_name: 'Admin',
    phone: adminPhone,
    password: 'Test1234',
    role: 'admin'
  });
  const adminUser = adminReg.user;
  console.log(`[${now()}] Admin registered id=${adminUser.id}, phone=${adminUser.phone}`);

  // Login passenger, driver, admin
  const passengerLogin = await httpPost('/api/auth/login', {
    phone: passengerPhone,
    password: 'Test1234'
  });
  const passengerToken = passengerLogin.accessToken;

  const driverLogin = await httpPost('/api/auth/login', {
    phone: driverPhone,
    password: 'Test1234'
  });
  const driverToken = driverLogin.accessToken;

  const adminLogin = await httpPost('/api/auth/login', {
    phone: adminPhone,
    password: 'Test1234'
  });
  const adminToken = adminLogin.accessToken;

  console.log(
    `[${now()}] Login OK: passengerToken=${passengerToken.length}, driverToken=${driverToken.length}, adminToken=${adminToken.length}`
  );

  // 2) Admin driver'ı approve etsin
  console.log(`[${now()}] Approving driver by admin...`);
  await httpPost(`/api/admin/drivers/${driver.id}/approve`, {}, adminToken);
  console.log(`[${now()}] Driver approved.`);

  // 3) user_devices'e FCM token ekle
  console.log(`[${now()}] Inserting FCM tokens into user_devices...`);
  await mysqlQuery(
    'INSERT INTO user_devices (user_id, device_token, platform, created_at) VALUES (?, ?, ?, NOW()), (?, ?, ?, NOW())',
    [driver.id, DRIVER_FCM_TOKEN, 'android', passenger.id, PASSENGER_FCM_TOKEN, 'android']
  );
  console.log(
    `[${now()}] FCM tokens inserted for driver=${driver.id} (driver token), passenger=${passenger.id} (passenger token)`
  );

  // 4) Socket.IO bağlantıları: passenger & driver
  console.log(`[${now()}] Connecting sockets...`);

  const driverSocket = io(SERVER_URL, {
    autoConnect: false,
    transports: ['websocket'],
    auth: { token: driverToken }
  });

  const passengerSocket = io(SERVER_URL, {
    autoConnect: false,
    transports: ['websocket'],
    auth: { token: passengerToken }
  });

  // Event log'ları
  driverSocket.on('connect', () => {
    console.log(`[${now()}] DRIVER socket connected: id=${driverSocket.id}`);
  });
  driverSocket.on('disconnect', () => {
    console.log(`[${now()}] DRIVER socket disconnected`);
  });

  passengerSocket.on('connect', () => {
    console.log(`[${now()}] PASSENGER socket connected: id=${passengerSocket.id}`);
  });
  passengerSocket.on('disconnect', () => {
    console.log(`[${now()}] PASSENGER socket disconnected`);
  });

  // Dinlenecek önemli event'ler
  driverSocket.on('request:incoming', (payload) => {
    console.log(`[${now()}] DRIVER received request:incoming`, payload && { ride_id: payload.ride_id });
  });

  driverSocket.on('request:accepted_confirm', (payload) => {
    console.log(`[${now()}] DRIVER received request:accepted_confirm`, payload);
  });

  passengerSocket.on('ride:assigned', (payload) => {
    console.log(`[${now()}] PASSENGER received ride:assigned`, payload);
  });

  passengerSocket.on('driver:arrived', (payload) => {
    console.log(`[${now()}] PASSENGER received driver:arrived`, payload);
  });

  passengerSocket.on('ride:message', (payload) => {
    console.log(`[${now()}] PASSENGER received ride:message`, payload);
  });

  driverSocket.on('ride:message', (payload) => {
    console.log(`[${now()}] DRIVER received ride:message`, payload);
  });

  driverSocket.on('error', (e) => {
    console.log(`[${now()}] DRIVER socket error`, e);
  });
  passengerSocket.on('error', (e) => {
    console.log(`[${now()}] PASSENGER socket error`, e);
  });

  driverSocket.connect();
  passengerSocket.connect();

  await sleep(2000);

  // 5) Driver availability set
  console.log(`[${now()}] Setting driver availability...`);
  driverSocket.emit('driver:set_availability', {
    available: true,
    lat: 41.015137,
    lng: 28.97953,
    vehicle_type: 'sari'
  });

  await sleep(2000);

  // 6) Passenger REST ile ride oluştursun
  console.log(`[${now()}] Passenger creating ride via REST...`);
  const rideCreate = await httpPost(
    '/api/rides',
    {
      start_lat: 41.015137,
      start_lng: 28.97953,
      start_address: 'Test Start',
      end_lat: 41.02,
      end_lng: 28.98,
      end_address: 'Test End',
      vehicle_type: 'sari',
      options: { meterOn: true },
      payment_method: 'nakit'
    },
    passengerToken
  );

  const ride = rideCreate.ride;
  console.log(
    `[${now()}] Ride created id=${ride.id}, sentDriversCount=${rideCreate.sentDriversCount} (driver:incoming request için bekle)`
  );

  console.log(`[${now()}] 5 saniye içinde DRIVER cihazında 'request_incoming' FCM görünüyor mu kontrol et.`);
  await sleep(5000);

  // 7) Driver çağrıyı kabul etsin
  console.log(`[${now()}] DRIVER accepting request via driver:accept_request...`);
  driverSocket.emit('driver:accept_request', { ride_id: ride.id });

  console.log(
    `[${now()}] 5-10 saniye içinde PASSENGER cihazında 'ride_assigned' FCM görünüyor mu kontrol et (assignService).`
  );
  await sleep(8000);

  // 8) Driver 'arrived' göndersin
  console.log(`[${now()}] DRIVER sending driver:arrived...`);
  driverSocket.emit('driver:arrived', { ride_id: ride.id });

  console.log(
    `[${now()}] 5-10 saniye içinde PASSENGER cihazında 'driver_arrived' FCM görünüyor mu kontrol et.`
  );
  await sleep(8000);

  // 9) Chat: driver passenger'a mesaj atsın
  console.log(`[${now()}] DRIVER sending ride:message (chat)...`);
  driverSocket.emit('ride:message', {
    ride_id: ride.id,
    text: 'Merhaba, birazdan yanınızdayım.'
  });

  console.log(
    `[${now()}] 5-10 saniye içinde PASSENGER cihazında 'ride_chat_message' FCM görünüyor mu kontrol et.`
  );
  await sleep(10000);

  console.log(`[${now()}] Test akışı tamamlandı. Socket'leri kapatıyorum...`);
  driverSocket.disconnect();
  passengerSocket.disconnect();

  console.log(`[${now()}] E2E FCM + Socket test finished.`);
}

main()
  .catch((err) => {
    console.error(`[${now()}] Test failed with error:`, err && err.stack ? err.stack : err);
    process.exit(1);
  })
  .then(() => {
    console.log(`[${now()}] Script exiting.`);
    process.exit(0);
  });