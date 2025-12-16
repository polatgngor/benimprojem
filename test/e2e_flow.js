/**
 * E2E test for Taksibu updated flow:
 * - register/login passenger & driver
 * - driver connects via socket.io, sets availability
 * - passenger creates ride
 * - driver receives 'request:incoming' and accepts
 * - driver starts ride with 4-digit code (driver:start_ride)
 * - driver sends location updates and a chat message (ride:update_location, ride:message)
 * - driver ends ride with fare (driver:end_ride)
 * - passenger & driver rate each other via REST (POST /api/rides/:id/rate)
 * - verify DB states for ride status/fare, ride_requests accepted, messages persisted, ratings persisted
 * - create a complaint (POST /api/complaints)
 *
 * Usage:
 * 1) Ensure server is running (node server.js)
 * 2) Install test deps: npm install axios socket.io-client ioredis mysql2
 * 3) Run: node test/e2e_flow.js
 */

'use strict';

const axios = require('axios');
const { io } = require('socket.io-client');
const IORedis = require('ioredis');
const mysql = require('mysql2/promise');

const SERVER_URL = process.env.SERVER_URL || 'http://localhost:3000';
const REDIS_HOST = process.env.REDIS_HOST || '127.0.0.1';
const REDIS_PORT = process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379;
const MYSQL_HOST = process.env.DB_HOST || '127.0.0.1';
const MYSQL_PORT = process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 3306;
const MYSQL_USER = process.env.DB_USER || 'root';
const MYSQL_PASS = process.env.DB_PASS || '';
const MYSQL_DB = process.env.DB_NAME || 'taksibu';

function now() {
  return new Date().toISOString();
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  console.log(`[${now()}] Starting E2E updated flow test...`);

  // generate unique phones
  const passengerPhone = `+90${Math.floor(5000000000 + Math.random() * 4000000000)}`;
  const driverPhone = `+90${Math.floor(5000000000 + Math.random() * 4000000000)}`;

  const passengerData = {
    first_name: 'E2E',
    last_name: 'Passenger',
    phone: passengerPhone,
    password: 'password123',
    role: 'passenger'
  };

  const driverData = {
    first_name: 'E2E',
    last_name: 'Driver',
    phone: driverPhone,
    password: 'password123',
    role: 'driver'
  };

  // 1) Register & login passenger
  let passengerToken, passengerUser;
  try {
    console.log(`[${now()}] Registering passenger ${passengerPhone}`);
    await axios.post(`${SERVER_URL}/api/auth/register`, passengerData, { timeout: 5000 });
    const loginResp = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: passengerData.phone, password: passengerData.password });
    passengerToken = loginResp.data.accessToken;
    passengerUser = loginResp.data.user;
    console.log(`[${now()}] Passenger logged in (id=${passengerUser.id})`);
  } catch (err) {
    console.error('Passenger register/login failed', err.response && err.response.data ? err.response.data : err.message);
    process.exit(1);
  }

  // 2) Register & login driver
  let driverToken, driverUser;
  try {
    console.log(`[${now()}] Registering driver ${driverPhone}`);
    await axios.post(`${SERVER_URL}/api/auth/register`, driverData, { timeout: 5000 });
    const loginResp = await axios.post(`${SERVER_URL}/api/auth/login`, { phone: driverData.phone, password: driverData.password });
    driverToken = loginResp.data.accessToken;
    driverUser = loginResp.data.user;
    console.log(`[${now()}] Driver logged in (id=${driverUser.id})`);
  } catch (err) {
    console.error('Driver register/login failed', err.response && err.response.data ? err.response.data : err.message);
    process.exit(1);
  }

  // 3) Connect driver socket and set availability
  console.log(`[${now()}] Connecting driver socket...`);
  const driverSocket = io(SERVER_URL, {
    auth: { token: driverToken },
    reconnection: false,
    transports: ['websocket']
  });

  await new Promise((resolve, reject) => {
    const to = setTimeout(() => reject(new Error('Driver socket connect timeout')), 8000);
    driverSocket.on('connect', () => {
      clearTimeout(to);
      console.log(`[${now()}] Driver socket connected: ${driverSocket.id}`);
      resolve();
    });
    driverSocket.on('connect_error', (err) => {
      clearTimeout(to);
      reject(err);
    });
  });

  // set available at a central location
  const DRIVER_POSITION = { lat: 41.015137, lng: 28.979530 };
  const VEHICLE_TYPE = 'sari';

  await new Promise((resolve) => {
    driverSocket.once('driver:availability_set', (data) => {
      console.log(`[${now()}] Driver availability ack:`, data);
      resolve();
    });
    driverSocket.emit('driver:set_availability', {
      available: true,
      lat: DRIVER_POSITION.lat,
      lng: DRIVER_POSITION.lng,
      vehicle_type: VEHICLE_TYPE
    });
  });

  // Prepare driver listener: accept incoming requests
  let incomingRideId = null;
  let driverAssigned = false;
  driverSocket.on('request:incoming', (payload) => {
    console.log(`[${now()}] Driver received request:incoming`, payload.ride_id);
    incomingRideId = payload.ride_id;
    // accept immediately
    driverSocket.emit('driver:accept_request', { ride_id: incomingRideId });
  });

  driverSocket.on('request:accepted_confirm', (p) => {
    console.log(`[${now()}] Driver acceptance confirmed:`, p);
    driverAssigned = true;
  });

  // 4) Passenger create ride
  console.log(`[${now()}] Passenger creating ride...`);
  const rideBody = {
    start: { lat: DRIVER_POSITION.lat + 0.001, lng: DRIVER_POSITION.lng + 0.001, address: 'Start Addr' },
    end: { lat: DRIVER_POSITION.lat + 0.01, lng: DRIVER_POSITION.lng + 0.01, address: 'End Addr' },
    vehicle_type: VEHICLE_TYPE,
    options: { meterOn: true, pet: false },
    payment_method: 'nakit'
  };

  let createdRide;
  try {
    const resp = await axios.post(`${SERVER_URL}/api/rides`, rideBody, { headers: { Authorization: `Bearer ${passengerToken}` }, timeout: 5000 });
    createdRide = resp.data.ride;
    console.log(`[${now()}] Ride created:`, createdRide);
  } catch (err) {
    console.error('Ride create failed', err.response && err.response.data ? err.response.data : err.message);
    process.exit(1);
  }

  // 5) Connect passenger socket to listen events
  console.log(`[${now()}] Connecting passenger socket...`);
  const passengerSocket = io(SERVER_URL, {
    auth: { token: passengerToken },
    reconnection: false,
    transports: ['websocket']
  });

  await new Promise((resolve, reject) => {
    const to = setTimeout(() => reject(new Error('Passenger socket connect timeout')), 8000);
    passengerSocket.on('connect', () => {
      clearTimeout(to);
      console.log(`[${now()}] Passenger socket connected: ${passengerSocket.id}`);
      resolve();
    });
    passengerSocket.on('connect_error', (err) => {
      clearTimeout(to);
      reject(err);
    });
  });

  // listen for assigned event
  let assignedEventReceived = false;
  passengerSocket.on('ride:assigned', (payload) => {
    console.log(`[${now()}] Passenger received ride:assigned`, payload);
    assignedEventReceived = true;
  });

  // wait briefly for assignment to happen and DB updates
  await sleep(2500);

  // verify assignment happened
  if (!assignedEventReceived && !driverAssigned) {
    console.warn(`[${now()}] No immediate assignment event seen yet, waiting a bit more...`);
    await sleep(3000);
  }

  // GET ride details to obtain code (in real app passenger gives code to driver)
  let rideDetails;
  try {
    const resp = await axios.get(`${SERVER_URL}/api/rides/${createdRide.id}`, { headers: { Authorization: `Bearer ${passengerToken}` }, timeout: 5000 });
    rideDetails = resp.data.ride;
    console.log(`[${now()}] Ride details fetched: id=${rideDetails.id} status=${rideDetails.status} code4=${rideDetails.code4}`);
  } catch (err) {
    console.error('Could not fetch ride details', err.response && err.response.data ? err.response.data : err.message);
    process.exit(1);
  }

  // 6) Driver starts ride using code
  console.log(`[${now()}] Driver attempting to start ride with code...`);
  let startOk = false;
  driverSocket.once('start_ride_ok', (p) => {
    console.log(`[${now()}] Driver received start_ride_ok:`, p);
    startOk = true;
  });
  driverSocket.once('start_ride_failed', (p) => {
    console.error(`[${now()}] Driver start_ride_failed:`, p);
  });

  // Use passenger-known code to simulate passenger giving code to driver
  const codeToUse = rideDetails.code4;
  driverSocket.emit('driver:start_ride', { ride_id: rideDetails.id, code: codeToUse });

  // passenger listens for ride started and ride:room_joined
  let rideStartedEvent = false;
  passengerSocket.on('ride:room_joined', (p) => {
    console.log(`[${now()}] Passenger got ride:room_joined`, p);
  });
  passengerSocket.on('ride:started', (p) => {
    console.log(`[${now()}] Passenger received ride:started`, p);
    rideStartedEvent = true;
  });

  // wait for started
  await sleep(1500);
  if (!startOk && !rideStartedEvent) {
    console.error(`[${now()}] Ride did not start as expected`);
    // continue to fail later checks; but proceed to try to call start again
  }

  // 7) Driver sends location updates and a chat message into room
  console.log(`[${now()}] Driver sending a location update and chat message...`);
  // Listen for updates on passenger side
  passengerSocket.on('ride:update_location', (loc) => {
    console.log(`[${now()}] Passenger received location update:`, loc);
  });
  passengerSocket.on('ride:message', (msg) => {
    console.log(`[${now()}] Passenger received chat message:`, msg);
  });

  // Send a couple of location updates
  driverSocket.emit('driver:update_location', { lat: DRIVER_POSITION.lat + 0.002, lng: DRIVER_POSITION.lng + 0.002, vehicle_type: VEHICLE_TYPE });
  await sleep(300);
  driverSocket.emit('driver:update_location', { lat: DRIVER_POSITION.lat + 0.004, lng: DRIVER_POSITION.lng + 0.004, vehicle_type: VEHICLE_TYPE });
  await sleep(300);

  // Send chat message
  driverSocket.emit('ride:message', { ride_id: rideDetails.id, text: 'Merhaba, ben geldim. ' });

  // wait for events to propagate & DB to persist
  await sleep(800);

  // 8) Driver ends ride with fare
  const fare = 75.50;
  console.log(`[${now()}] Driver ending ride with fare ${fare}...`);
  let endOk = false;
  passengerSocket.once('ride:completed', (p) => {
    console.log(`[${now()}] Passenger received ride:completed`, p);
  });
  driverSocket.once('end_ride_ok', (p) => {
    console.log(`[${now()}] Driver received end_ride_ok`, p);
    endOk = true;
  });

  driverSocket.emit('driver:end_ride', { ride_id: rideDetails.id, fare_actual: fare });

  await sleep(1200);
  if (!endOk) {
    console.warn(`[${now()}] Driver end_ride did not confirm quickly`);
  }

  // 9) Validate DB: ride status = completed and fare_actual saved; ride_requests accepted present; messages present; ratings/complaints below
  console.log(`[${now()}] Validating DB state...`);
  let conn;
  try {
    conn = await mysql.createConnection({ host: MYSQL_HOST, port: MYSQL_PORT, user: MYSQL_USER, password: MYSQL_PASS, database: MYSQL_DB });
    // ride row
    const [rides] = await conn.execute('SELECT id, status, driver_id, passenger_id, fare_actual FROM rides WHERE id = ?', [rideDetails.id]);
    if (!rides || rides.length === 0) throw new Error('Ride not found in DB');
    const rideRow = rides[0];
    console.log(`[${now()}] DB ride row:`, rideRow);
    if (rideRow.status !== 'completed') {
      console.error(`[${now()}] FAIL: expected ride status completed but got ${rideRow.status}`);
      process.exit(1);
    }
    if (Number(rideRow.fare_actual) !== Number(fare)) {
      console.error(`[${now()}] FAIL: expected fare_actual ${fare} but got ${rideRow.fare_actual}`);
      process.exit(1);
    }

    // ride_requests accepted
    const [rrAccepted] = await conn.execute('SELECT driver_response FROM ride_requests WHERE ride_id = ? AND driver_response = ?', [rideDetails.id, 'accepted']);
    if (!rrAccepted || rrAccepted.length === 0) {
      console.error(`[${now()}] FAIL: no ride_request accepted record found`);
      process.exit(1);
    } else {
      console.log(`[${now()}] ride_request accepted -> OK`);
    }

    // messages persisted
    const [msgs] = await conn.execute('SELECT id, sender_id, message FROM ride_messages WHERE ride_id = ? ORDER BY id ASC', [rideDetails.id]);
    console.log(`[${now()}] ride_messages count: ${msgs.length}`);
    if (msgs.length === 0) {
      console.error(`[${now()}] FAIL: expected at least one chat message persisted`);
      process.exit(1);
    }

    // 10) Ratings: passenger rates driver, driver rates passenger
    console.log(`[${now()}] Posting ratings for both sides...`);
    // passenger rates driver
    await axios.post(`${SERVER_URL}/api/rides/${rideDetails.id}/rate`, { stars: 5, comment: 'Harika sürücü' }, { headers: { Authorization: `Bearer ${passengerToken}` } });
    // driver rates passenger
    await axios.post(`${SERVER_URL}/api/rides/${rideDetails.id}/rate`, { stars: 5, comment: 'Sorunsuz yolcu' }, { headers: { Authorization: `Bearer ${driverToken}` } });

    const [ratings] = await conn.execute('SELECT id, rater_id, rated_id, stars FROM ratings WHERE ride_id = ?', [rideDetails.id]);
    console.log(`[${now()}] ratings rows:`, ratings.length);
    if (ratings.length < 2) {
      console.error(`[${now()}] FAIL: expected 2 ratings, found ${ratings.length}`);
      process.exit(1);
    }

    // 11) Verify messages via API
    const messagesResp = await axios.get(`${SERVER_URL}/api/rides/${rideDetails.id}/messages`, { headers: { Authorization: `Bearer ${passengerToken}` } });
    console.log(`[${now()}] GET /api/rides/:id/messages returned ${messagesResp.data.messages.length} messages`);

    // 12) Create a complaint (passenger complains about driver)
    console.log(`[${now()}] Creating a complaint...`);
    const complaintResp = await axios.post(`${SERVER_URL}/api/complaints`, { ride_id: rideDetails.id, accused_id: rideRow.driver_id, type: 'behavior', description: 'Example complaint for test' }, { headers: { Authorization: `Bearer ${passengerToken}` } });
    console.log(`[${now()}] Complaint created id:`, complaintResp.data.complaint && complaintResp.data.complaint.id);

    // verify complaint exists in DB
    const [compls] = await conn.execute('SELECT id, complainer_id, accused_id, description FROM complaints WHERE ride_id = ?', [rideDetails.id]);
    console.log(`[${now()}] complaints rows for ride: ${compls.length}`);
    if (compls.length === 0) {
      console.error(`[${now()}] FAIL: complaint not found in DB`);
      process.exit(1);
    }

    console.log(`[${now()}] All validations passed. E2E updated flow succeeded.`);
  } catch (err) {
    console.error('Validation error', err && err.message ? err.message : err);
    process.exit(1);
  } finally {
    if (conn) await conn.end();
  }

  // cleanup
  driverSocket.disconnect();
  passengerSocket.disconnect();

  process.exit(0);
}

main().catch((err) => {
  console.error('E2E test failed', err && err.stack ? err.stack : err);
  process.exit(1);
});