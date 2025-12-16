/**
 * E2E test: Timeout / auto_reject scenario
 *
 * Flow:
 * - register/login passenger, driver, admin
 * - admin approve driver
 * - driver connects and sets availability (but DOES NOT accept requests)
 * - passenger connects socket and creates ride
 * - wait RIDE_ACCEPT_TIMEOUT_SECONDS + buffer
 * - assert ride.status == 'auto_rejected' and passenger socket got 'ride:auto_rejected'
 *
 * Usage:
 * npm install axios socket.io-client ioredis mysql2
 * Set RIDE_ACCEPT_TIMEOUT_SECONDS in .env if you changed it, default is 20
 * node test/e2e_timeout.js
 */

'use strict';

const axios = require('axios');
const { io } = require('socket.io-client');
const mysql = require('mysql2/promise');

const SERVER_URL = process.env.SERVER_URL || 'http://localhost:3000';
const MYSQL_HOST = process.env.DB_HOST || '127.0.0.1';
const MYSQL_PORT = process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 3306;
const MYSQL_USER = process.env.DB_USER || 'root';
const MYSQL_PASS = process.env.DB_PASS || '';
const MYSQL_DB = process.env.DB_NAME || 'taksibu';

const ACCEPT_TIMEOUT_SECONDS = parseInt(process.env.RIDE_ACCEPT_TIMEOUT_SECONDS || '20', 10);
const WAIT_MS = (ACCEPT_TIMEOUT_SECONDS + 4) * 1000; // buffer

async function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function main() {
  console.log('Starting E2E timeout test...');

  // create unique phones
  const passengerPhone = `+90${Math.floor(5000000000 + Math.random()*4000000000)}`;
  const driverPhone = `+90${Math.floor(5000000000 + Math.random()*4000000000)}`;
  const adminPhone = `+90${Math.floor(5000000000 + Math.random()*4000000000)}`;

  // 1) register + login passenger
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'T', last_name: 'P', phone: passengerPhone, password: 'pass', role: 'passenger' });
  const plogin = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: passengerPhone, password: 'pass' });
  const passengerToken = plogin.data.accessToken;

  // 2) register + login driver
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'T', last_name: 'D', phone: driverPhone, password: 'pass', role: 'driver' });
  const dlogin = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: driverPhone, password: 'pass' });
  const driverToken = dlogin.data.accessToken;
  const driverUser = dlogin.data.user;

  // 3) register + login admin
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'Admin', last_name: 'User', phone: adminPhone, password: 'pass', role: 'admin' });
  const alogin = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: adminPhone, password: 'pass' });
  const adminToken = alogin.data.accessToken;

  // 4) admin approves driver
  // driver user id is driverUser.id
  await axios.post(`${SERVER_URL}/api/admin/drivers/${driverUser.id}/approve`, {}, { headers: { Authorization: `Bearer ${adminToken}` } });
  console.log('Admin approved driver:', driverUser.id);

  // 5) connect driver socket and set availability (driver will NOT accept)
  const driverSocket = io(SERVER_URL, { auth: { token: driverToken }, transports: ['websocket'], reconnection: false });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('driver socket connect timeout')), 8000);
    driverSocket.on('connect', () => { clearTimeout(t); resolve(); });
    driverSocket.on('connect_error', (err) => { clearTimeout(t); reject(err); });
  });
  // set availability
  await new Promise((resolve) => {
    driverSocket.once('driver:availability_set', (d) => { console.log('driver availability ack'); resolve(); });
    driverSocket.emit('driver:set_availability', { available: true, lat: 41.0151, lng: 28.9795, vehicle_type: 'sari' });
  });

  // IMPORTANT: DO NOT attach request:incoming handler that accepts -> driver will NOT accept

  // 6) connect passenger socket to listen for auto_reject
  const passengerSocket = io(SERVER_URL, { auth: { token: passengerToken }, transports: ['websocket'], reconnection: false });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('passenger socket connect timeout')), 8000);
    passengerSocket.on('connect', () => { clearTimeout(t); resolve(); });
    passengerSocket.on('connect_error', (err) => { clearTimeout(t); reject(err); });
  });

  let gotAutoReject = false;
  passengerSocket.on('ride:auto_rejected', (p) => {
    console.log('Passenger received ride:auto_rejected', p);
    gotAutoReject = true;
  });

  // 7) passenger creates ride
  const rideResp = await axios.post(`${SERVER_URL}/api/rides`, {
    start: { lat: 41.0152, lng: 28.9796, address: 'Start' },
    end: { lat: 41.02, lng: 28.98, address: 'End' },
    vehicle_type: 'sari',
    options: {},
    payment_method: 'nakit'
  }, { headers: { Authorization: `Bearer ${passengerToken}` } });

  const ride = rideResp.data.ride;
  console.log('Ride created id', ride.id, 'wait for auto-reject...');

  // wait for timeout + buffer
  await sleep(WAIT_MS);

  // 8) check DB for ride.status == auto_rejected
  const conn = await mysql.createConnection({ host: MYSQL_HOST, port: MYSQL_PORT, user: MYSQL_USER, password: MYSQL_PASS, database: MYSQL_DB });
  const [rows] = await conn.execute('SELECT id, status FROM rides WHERE id = ?', [ride.id]);
  if (!rows || rows.length === 0) {
    console.error('Ride not found in DB');
    process.exit(1);
  }
  const rideRow = rows[0];
  console.log('Ride row status:', rideRow.status);

  if (rideRow.status !== 'auto_rejected') {
    console.error('FAIL: expected ride to be auto_rejected');
    process.exit(1);
  }
  if (!gotAutoReject) {
    console.error('FAIL: passenger did not receive ride:auto_rejected event');
    process.exit(1);
  }

  console.log('Timeout/auto_reject E2E test passed.');

  // cleanup
  driverSocket.disconnect();
  passengerSocket.disconnect();
  await conn.end();
  process.exit(0);
}

main().catch((e) => { console.error('E2E timeout test failed', e && e.stack ? e.stack : e); process.exit(1); });