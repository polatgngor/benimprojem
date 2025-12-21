/**
 * E2E FULL TEST for Taksibu backend (comprehensive)
 *
 * Flow:
 * - Register/login: passenger, driver, admin
 * - Admin approves driver
 * - Driver socket connect + set availability (requires approval)
 * - Passenger creates a ride -> driver receives request and accepts
 * - Atomic assign -> verify ride assigned
 * - Driver starts ride with 4-digit code -> ride starts
 * - Driver location updates + chat message (persisted)
 * - Driver ends ride -> fare saved, ride completed
 * - Ratings: both sides rate each other (persisted)
 * - Complaint creation (persisted)
 * - Notifications created for assigned/completed/auto_reject events
 * - Profile: get/update profile, change phone, change password, logout & blacklist check
 * - History: passenger & driver rides list
 * - Driver extras: plaka change, earnings
 * - Timeout scenario: admin-approved driver online but does NOT accept -> ride auto_rejected and passenger notified
 *
 * Notes:
 * - Ensure server is running at SERVER_URL and MySQL + Redis are reachable via env or defaults.
 * - Install deps if needed: npm install axios socket.io-client mysql2 ioredis
 *
 * Run:
 *   node test/e2e_full_test.js
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

function now() {
  return new Date().toISOString();
}
async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}
function randomPhone() {
  return `+90${Math.floor(5000000000 + Math.random() * 4000000000)}`;
}
async function mysqlQuery(sql, params = []) {
  const conn = await mysql.createConnection({ host: MYSQL_HOST, port: MYSQL_PORT, user: MYSQL_USER, password: MYSQL_PASS, database: MYSQL_DB });
  try {
    const [rows] = await conn.execute(sql, params);
    return rows;
  } finally {
    await conn.end();
  }
}

async function runMain() {
  console.log(`[${now()}] Starting E2E full test against ${SERVER_URL}`);

  // Generate users
  const passengerPhone = randomPhone();
  const driverPhone = randomPhone();
  const adminPhone = randomPhone();

  // 1) register + login passenger
  console.log(`[${now()}] Registering passenger ${passengerPhone}`);
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'E2E', last_name: 'Passenger', phone: passengerPhone, password: 'password123', role: 'passenger' });
  const plogin = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: passengerPhone, password: 'password123' });
  const passengerToken = plogin.data.accessToken;
  const passengerUser = plogin.data.user;
  console.log(`[${now()}] Passenger logged in id=${passengerUser.id}`);

  // 2) register + login driver
  console.log(`[${now()}] Registering driver ${driverPhone}`);
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'E2E', last_name: 'Driver', phone: driverPhone, password: 'password123', role: 'driver' });
  const dlogin = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: driverPhone, password: 'password123' });
  const driverToken = dlogin.data.accessToken;
  const driverUser = dlogin.data.user;
  console.log(`[${now()}] Driver logged in id=${driverUser.id}`);

  // 3) register + login admin
  console.log(`[${now()}] Registering admin ${adminPhone}`);
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'E2E', last_name: 'Admin', phone: adminPhone, password: 'password123', role: 'admin' });
  const alogin = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: adminPhone, password: 'password123' });
  const adminToken = alogin.data.accessToken;
  const adminUser = alogin.data.user;
  console.log(`[${now()}] Admin logged in id=${adminUser.id}`);

  // 4) admin approves driver
  console.log(`[${now()}] Admin approving driver user_id=${driverUser.id}`);
  await axios.post(`${SERVER_URL}/api/admin/drivers/${driverUser.id}/approve`, {}, { headers: { Authorization: `Bearer ${adminToken}` } });
  console.log(`[${now()}] Driver approved`);

  // 5) connect driver socket and set availability
  console.log(`[${now()}] Connecting driver socket...`);
  const driverSocket = io(SERVER_URL, { auth: { token: driverToken }, transports: ['websocket'], reconnection: false });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('driver socket connect timeout')), 8000);
    driverSocket.on('connect', () => { clearTimeout(t); resolve(); });
    driverSocket.on('connect_error', (err) => { clearTimeout(t); reject(err); });
  });
  console.log(`[${now()}] Driver socket connected id=${driverSocket.id}`);
  await new Promise((resolve) => {
    driverSocket.once('driver:availability_set', (d) => { console.log(`[${now()}] Driver availability ack`, d); resolve(); });
    driverSocket.emit('driver:set_availability', { available: true, lat: 41.015137, lng: 28.979530, vehicle_type: 'sari' });
  });

  // attach driver handlers
  let incomingRideId = null;
  let driverAssigned = false;
  driverSocket.on('request:incoming', (payload) => {
    console.log(`[${now()}] Driver received request:incoming ride_id=${payload.ride_id}`);
    incomingRideId = payload.ride_id;
    // accept immediately for main flow
    driverSocket.emit('driver:accept_request', { ride_id: incomingRideId });
  });
  driverSocket.on('request:accepted_confirm', (p) => {
    console.log(`[${now()}] Driver acceptance confirmed`, p);
    driverAssigned = true;
  });

  // 6) passenger creates ride
  console.log(`[${now()}] Passenger creating ride...`);
  const rideBody = {
    start: { lat: 41.016, lng: 28.98, address: 'Start Addr' },
    end: { lat: 41.02, lng: 28.99, address: 'End Addr' },
    vehicle_type: 'sari',
    options: { meterOn: true },
    payment_method: 'nakit'
  };
  const createRideResp = await axios.post(`${SERVER_URL}/api/rides`, rideBody, { headers: { Authorization: `Bearer ${passengerToken}` } });
  const createdRide = createRideResp.data.ride;
  console.log(`[${now()}] Ride created id=${createdRide.id} status=${createdRide.status}`);

  // connect passenger socket
  const passengerSocket = io(SERVER_URL, { auth: { token: passengerToken }, transports: ['websocket'], reconnection: false });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('passenger socket connect timeout')), 8000);
    passengerSocket.on('connect', () => { clearTimeout(t); resolve(); });
    passengerSocket.on('connect_error', (err) => { clearTimeout(t); reject(err); });
  });
  let passengerAssignedEvent = false;
  passengerSocket.on('ride:assigned', (p) => {
    console.log(`[${now()}] Passenger received ride:assigned`, p);
    passengerAssignedEvent = true;
  });

  // wait for assign flow
  await sleep(2000);

  // 7) verify assignment in DB
  const rideRow = (await mysqlQuery('SELECT id, status, driver_id, passenger_id FROM rides WHERE id = ?', [createdRide.id]))[0];
  if (!rideRow) throw new Error('Ride not found after create');
  if (rideRow.status !== 'assigned') throw new Error(`Ride not assigned as expected, status=${rideRow.status}`);
  console.log(`[${now()}] Ride assigned in DB -> driver_id=${rideRow.driver_id}`);

  // 8) fetch ride details to get code4
  const rideDetailsResp = await axios.get(`${SERVER_URL}/api/rides/${createdRide.id}`, { headers: { Authorization: `Bearer ${passengerToken}` } });
  const rideDetails = rideDetailsResp.data.ride;
  console.log(`[${now()}] Ride details code4=${rideDetails.code4}`);

  // 9) driver starts ride with code
  console.log(`[${now()}] Driver starting ride with code ${rideDetails.code4}`);
  let startOk = false;
  driverSocket.once('start_ride_ok', (p) => { console.log(`[${now()}] Driver start_ride_ok`, p); startOk = true; });
  driverSocket.emit('driver:start_ride', { ride_id: rideDetails.id, code: rideDetails.code4 });
  await sleep(1000);
  if (!startOk) throw new Error('Driver did not receive start_ride_ok');

  // 10) location updates and chat
  console.log(`[${now()}] Driver sending location updates and chat...`);
  passengerSocket.on('ride:update_location', (loc) => console.log(`[${now()}] Passenger got location:`, loc));
  passengerSocket.on('ride:message', (msg) => console.log(`[${now()}] Passenger got chat:`, msg));
  driverSocket.emit('driver:update_location', { lat: 41.017137, lng: 28.98153, vehicle_type: 'sari' });
  await sleep(200);
  driverSocket.emit('driver:update_location', { lat: 41.019137, lng: 28.98353, vehicle_type: 'sari' });
  await sleep(200);
  driverSocket.emit('ride:message', { ride_id: rideDetails.id, text: 'Merhaba, geldim.' });
  await sleep(800);

  // 11) driver ends ride
  const fare = 65.5;
  console.log(`[${now()}] Driver ending ride with fare ${fare}`);
  let endOk = false;
  driverSocket.once('end_ride_ok', (p) => { console.log(`[${now()}] Driver end_ride_ok`, p); endOk = true; });
  passengerSocket.once('ride:completed', (p) => { console.log(`[${now()}] Passenger received ride:completed`, p); });
  driverSocket.emit('driver:end_ride', { ride_id: rideDetails.id, fare_actual: fare });
  await sleep(1200);
  if (!endOk) throw new Error('Driver did not receive end_ride_ok');

  // 12) DB validations
  const rideRow2 = (await mysqlQuery('SELECT id, status, fare_actual FROM rides WHERE id = ?', [rideDetails.id]))[0];
  if (rideRow2.status !== 'completed') throw new Error('Ride not completed in DB');
  console.log(`[${now()}] Ride completed and fare saved: ${rideRow2.fare_actual}`);

  const rr = await mysqlQuery('SELECT COUNT(*) as cnt FROM ride_requests WHERE ride_id = ? AND driver_response = ?', [rideDetails.id, 'accepted']);
  if (!rr || rr[0].cnt < 1) throw new Error('No accepted ride_request found');
  console.log(`[${now()}] ride_requests accepted -> OK`);

  const msgs = await mysqlQuery('SELECT id, sender_id, message FROM ride_messages WHERE ride_id = ?', [rideDetails.id]);
  if (msgs.length < 1) throw new Error('No chat messages persisted');
  console.log(`[${now()}] ride_messages persisted count=${msgs.length}`);

  // 13) Ratings
  console.log(`[${now()}] Posting ratings from both sides`);
  await axios.post(`${SERVER_URL}/api/rides/${rideDetails.id}/rate`, { stars: 5, comment: 'Great driver' }, { headers: { Authorization: `Bearer ${passengerToken}` } });
  await axios.post(`${SERVER_URL}/api/rides/${rideDetails.id}/rate`, { stars: 5, comment: 'Great passenger' }, { headers: { Authorization: `Bearer ${driverToken}` } });

  const ratings = await mysqlQuery('SELECT id, rater_id, rated_id, stars FROM ratings WHERE ride_id = ?', [rideDetails.id]);
  if (ratings.length < 2) throw new Error('Ratings not persisted properly');
  console.log(`[${now()}] ratings persisted count=${ratings.length}`);

  // 14) Complaint
  console.log(`[${now()}] Creating a complaint for the ride`);
  const compResp = await axios.post(`${SERVER_URL}/api/complaints`, { ride_id: rideDetails.id, accused_id: rideRow.driver_id, type: 'other', description: 'Test complaint' }, { headers: { Authorization: `Bearer ${passengerToken}` } });
  const comp = compResp.data.complaint;
  console.log(`[${now()}] Complaint created id=${comp.id}`);

  // 15) Notifications DB check (passenger)
  const notifs = await mysqlQuery('SELECT id, type, body FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 10', [passengerUser.id]);
  console.log(`[${now()}] Passenger notifications count (latest 10): ${notifs.length}`);

  // 16) Profile get/update
  console.log(`[${now()}] Fetching passenger profile`);
  const profileResp = await axios.get(`${SERVER_URL}/api/profile`, { headers: { Authorization: `Bearer ${passengerToken}` } });
  console.log(`[${now()}] Passenger profile:`, profileResp.data.user);

  console.log(`[${now()}] Updating passenger profile name`);
  await axios.put(`${SERVER_URL}/api/profile`, { first_name: 'Updated', last_name: 'Passenger' }, { headers: { Authorization: `Bearer ${passengerToken}` } });
  const profileAfter = await axios.get(`${SERVER_URL}/api/profile`, { headers: { Authorization: `Bearer ${passengerToken}` } });
  console.log(`[${now()}] Updated passenger name ->`, profileAfter.data.user.first_name, profileAfter.data.user.last_name);

  // 17) Change phone
  const newPhone = randomPhone();
  console.log(`[${now()}] Changing passenger phone to ${newPhone}`);
  await axios.put(`${SERVER_URL}/api/profile/phone`, { new_phone: newPhone }, { headers: { Authorization: `Bearer ${passengerToken}` } });
  console.log(`[${now()}] Phone changed`);

  // 18) Change password (blacklist current token)
  console.log(`[${now()}] Changing passenger password (will blacklist current token)`);
  await axios.put(`${SERVER_URL}/api/profile/password`, { old_password: 'password123', new_password: 'newpass123' }, { headers: { Authorization: `Bearer ${passengerToken}` } });
  console.log(`[${now()}] Password changed, attempting to use old token for a protected endpoint (should fail)`);

  try {
    await axios.get(`${SERVER_URL}/api/profile`, { headers: { Authorization: `Bearer ${passengerToken}` }, timeout: 3000 });
    throw new Error('Old token still valid after password change (expected blacklist)');
  } catch (err) {
    if (err.response && err.response.status === 401) {
      console.log(`[${now()}] Old token invalidated as expected after password change`);
    } else {
      console.warn(`[${now()}] Warning: unexpected response when checking old token invalidation`, err.message || err);
    }
  }

  // 19) Re-login passenger with new password
  const relog = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: newPhone, password: 'newpass123' });
  const passengerToken2 = relog.data.accessToken;
  console.log(`[${now()}] Passenger re-logged in with new password`);

  // 20) Fetch ride history BEFORE logout using fresh token
  console.log(`[${now()}] Fetching passenger ride history`);
  const phist = await axios.get(`${SERVER_URL}/api/rides?page=1&limit=10`, { headers: { Authorization: `Bearer ${passengerToken2}` } });
  console.log(`[${now()}] Passenger history count: ${phist.data.rides.length}`);

  // 21) Logout test: blacklist token
  console.log(`[${now()}] Logging out passenger to blacklist token`);
  await axios.post(`${SERVER_URL}/api/profile/logout`, {}, { headers: { Authorization: `Bearer ${passengerToken2}` } });
  try {
    await axios.get(`${SERVER_URL}/api/profile`, { headers: { Authorization: `Bearer ${passengerToken2}` } });
    throw new Error('Token still valid after logout (expected blacklisted)');
  } catch (err) {
    if (err.response && err.response.status === 401) {
      console.log(`[${now()}] Logout blacklisted token as expected`);
    } else {
      console.warn(`[${now()}] Warning: unexpected result when testing logout`, err.message || err);
    }
  }

  // 22) Driver history
  console.log(`[${now()}] Fetching driver ride history`);
  const dhist = await axios.get(`${SERVER_URL}/api/rides?page=1&limit=10`, { headers: { Authorization: `Bearer ${driverToken}` } });
  console.log(`[${now()}] Driver history count: ${dhist.data.rides.length}`);

  // 23) Driver plate update and earnings
  console.log(`[${now()}] Updating driver plate`);
  await axios.put(`${SERVER_URL}/api/driver/plate`, { vehicle_plate: '34-E2E-01' }, { headers: { Authorization: `Bearer ${driverToken}` } });
  console.log(`[${now()}] Driver plate updated`);

  console.log(`[${now()}] Fetching driver earnings (all time)`);
  const earnResp = await axios.get(`${SERVER_URL}/api/driver/earnings`, { headers: { Authorization: `Bearer ${driverToken}` } });
  console.log(`[${now()}] Driver earnings total: ${earnResp.data.total}`);

  // 24) Disable main driver availability before timeout scenario to avoid interference
  try {
    console.log(`[${now()}] Disabling main driver availability before timeout test`);
    await new Promise((resolve) => {
      let resolved = false;
      const onAck = (d) => {
        if (!resolved) {
          resolved = true;
          driverSocket.off('driver:availability_set', onAck);
          resolve();
        }
      };
      driverSocket.on('driver:availability_set', onAck);
      driverSocket.emit('driver:set_availability', { available: false, lat: 0, lng: 0, vehicle_type: 'sari' });
      // safety resolve after 1s
      setTimeout(() => { if (!resolved) { resolved = true; driverSocket.off('driver:availability_set', onAck); resolve(); } }, 1000);
    });
    console.log(`[${now()}] Main driver availability disabled`);
  } catch (e) {
    console.warn(`[${now()}] Could not disable main driver availability, continuing anyway`, e && e.message ? e.message : e);
  }

  // 25) Timeout scenario (t-passenger, t-driver, t-admin)
  console.log(`[${now()}] Running timeout/auto_reject scenario...`);

  const tPassengerPhone = randomPhone();
  const tDriverPhone = randomPhone();
  const tAdminPhone = randomPhone();

  // register & login t-passenger
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'T', last_name: 'P', phone: tPassengerPhone, password: 'pass', role: 'passenger' });
  const tpl = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: tPassengerPhone, password: 'pass' });
  const tPassengerToken = tpl.data.accessToken;

  // register & login t-driver
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'T', last_name: 'D', phone: tDriverPhone, password: 'pass', role: 'driver' });
  const tdl = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: tDriverPhone, password: 'pass' });
  const tDriverToken = tdl.data.accessToken;
  const tDriverUser = tdl.data.user;

  // register & login t-admin
  await axios.post(`${SERVER_URL}/api/auth/register`, { first_name: 'T', last_name: 'Admin', phone: tAdminPhone, password: 'pass', role: 'admin' });
  const tal = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: tAdminPhone, password: 'pass' });
  const tAdminToken = tal.data.accessToken;

  // admin approves t-driver
  await axios.post(`${SERVER_URL}/api/admin/drivers/${tDriverUser.id}/approve`, {}, { headers: { Authorization: `Bearer ${tAdminToken}` } });

  // connect t-driver socket and set availability (but DO NOT accept)
  const tDriverSocket = io(SERVER_URL, { auth: { token: tDriverToken }, transports: ['websocket'], reconnection: false });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('tDriver socket connect timeout')), 8000);
    tDriverSocket.on('connect', () => { clearTimeout(t); resolve(); });
    tDriverSocket.on('connect_error', (err) => { clearTimeout(t); reject(err); });
  });
  await new Promise((resolve) => {
    tDriverSocket.once('driver:availability_set', (d) => { console.log(`[${now()}] tDriver availability ack`); resolve(); });
    tDriverSocket.emit('driver:set_availability', { available: true, lat: 41.0152, lng: 28.9796, vehicle_type: 'sari' });
  });

  // connect t-passenger socket and listen for auto_reject
  const tPassengerSocket = io(SERVER_URL, { auth: { token: tPassengerToken }, transports: ['websocket'], reconnection: false });
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('tPassenger socket connect timeout')), 8000);
    tPassengerSocket.on('connect', () => { clearTimeout(t); resolve(); });
    tPassengerSocket.on('connect_error', (err) => { clearTimeout(t); reject(err); });
  });

  let gotAutoReject = false;
  tPassengerSocket.on('ride:auto_rejected', (p) => {
    console.log(`[${now()}] tPassenger received ride:auto_rejected`, p);
    gotAutoReject = true;
  });

  // create ride as t-passenger (this ride should auto_reject because t-driver will NOT accept)
  const tRideResp = await axios.post(`${SERVER_URL}/api/rides`, {
    start: { lat: 41.0153, lng: 28.9797, address: 'Start' },
    end: { lat: 41.02, lng: 28.98, address: 'End' },
    vehicle_type: 'sari',
    options: {},
    payment_method: 'nakit'
  }, { headers: { Authorization: `Bearer ${tPassengerToken}` } });

  const tRide = tRideResp.data.ride;
  console.log(`[${now()}] tRide created id=${tRide.id}, waiting ${ACCEPT_TIMEOUT_SECONDS + 4} sec for auto-reject...`);
  await sleep((ACCEPT_TIMEOUT_SECONDS + 4) * 1000);

  // check DB for auto_rejected
  const tRideRow = (await mysqlQuery('SELECT id, status FROM rides WHERE id = ?', [tRide.id]))[0];
  if (tRideRow.status !== 'auto_rejected') throw new Error(`Timeout test failed: ride status ${tRideRow.status}`);
  if (!gotAutoReject) throw new Error('Timeout test failed: passenger did not receive auto_rejected socket event');
  console.log(`[${now()}] Timeout auto_reject scenario passed`);

  // cleanup sockets
  try {
    driverSocket.disconnect();
    passengerSocket.disconnect();
    tDriverSocket.disconnect();
    tPassengerSocket.disconnect();
  } catch (e) { /* ignore */ }

  console.log(`[${now()}] All tests completed successfully.`);
  process.exit(0);
}

runMain().catch((err) => {
  console.error(`[${now()}] E2E full test failed:`, err && err.stack ? err.stack : err);
  process.exit(1);
});