const rideService = require('../../services/rideService');
const { Ride, RideRequest } = require('../../models');

module.exports = (io, socket) => {
    const { userId, role } = socket.user;

    // -------------------------
    // PASSENGER REJOIN
    // -------------------------
    socket.on('passenger:rejoin', async (payload) => {
        try {
            if (role !== 'passenger') return;
            const ride = await Ride.findOne({
                where: { passenger_id: userId, status: ['assigned', 'started'] }
            });
            if (ride) {
                const room = `ride:${ride.id}`;
                socket.join(room);
            }
        } catch (err) {
            console.error('passenger:rejoin err', err);
        }
    });

    // -------------------------
    // DRIVER: ACCEPT REQUEST
    // -------------------------
    socket.on('driver:accept_request', async (payload) => {
        try {
            if (role !== 'driver') return socket.emit('request:accept_failed', { ride_id: payload.ride_id, reason: 'forbidden' });

            const { ride, driverInfo } = await rideService.acceptRide(payload.ride_id, userId);

            const room = `ride:${ride.id}`;
            socket.join(room);

            // Confirm to driver
            socket.emit('request:accepted_confirm', {
                ride_id: ride.id,
                assigned: true,
                passenger: { id: ride.passenger_id } // Service could return this or we fetch it. Service "acceptRide" emits to others, but we must emit back to caller.
            });
            // Note: Service already handles notifying passenger & FCM.

        } catch (err) {
            console.error('accept_request error', err);
            socket.emit('request:accept_failed', { ride_id: payload && payload.ride_id, reason: err.message });
        }
    });

    // -------------------------
    // DRIVER: REJECT REQUEST
    // -------------------------
    socket.on('driver:reject_request', async (payload) => {
        try {
            if (role !== 'driver') return;
            const { ride_id } = payload;
            await RideRequest.update({ driver_response: 'rejected', response_at: new Date() }, { where: { ride_id, driver_id: userId } });
            socket.emit('request:rejected_confirm', { ride_id });
        } catch (e) { }
    });

    // -------------------------
    // DRIVER: START RIDE
    // -------------------------
    socket.on('driver:start_ride', async (payload) => {
        try {
            if (role !== 'driver') return;
            const { ride_id, code } = payload;

            const ride = await rideService.startRide(ride_id, userId, code);

            socket.emit('start_ride_ok', { ride_id: ride.id });
        } catch (e) {
            socket.emit('start_ride_failed', { reason: e.message || 'server_error' });
        }
    });

    // -------------------------
    // DRIVER: END RIDE
    // -------------------------
    socket.on('driver:end_ride', async (payload) => {
        try {
            if (role !== 'driver') return;
            const { ride_id, fare_actual } = payload;

            const ride = await rideService.completeRide(ride_id, userId, fare_actual);

            socket.leave(`ride:${ride.id}`);
            socket.emit('end_ride_ok', { ride_id });
        } catch (e) {
            // Handle specific errors for friendly UI messages if needed
            let msg = e.message;
            if (e.message.includes('Fare out of range')) {
                // Pass full message for UI to display (e.g. range info)
                return socket.emit('end_ride_failed', { ride_id, reason: 'fare_out_of_range', message: e.message });
            }
            socket.emit('end_ride_failed', { reason: 'server_error' });
        }
    });

    // -------------------------
    // DRIVER: CANCEL RIDE
    // -------------------------
    socket.on('driver:cancel_ride', async (payload) => {
        try {
            if (role !== 'driver') return;
            const { ride_id, reason } = payload;

            await rideService.cancelRide(ride_id, userId, role, reason);

            socket.leave(`ride:${ride_id}`);
            socket.emit('cancel_ride_ok', { ride_id });
        } catch (e) {
            socket.emit('cancel_ride_failed', { reason: e.message });
        }
    });
};
