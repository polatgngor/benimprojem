const express = require('express');
const router = express.Router();
const ridesController = require('../controllers/ridesController');
const auth = require('../middlewares/auth');

// List / history (passenger or driver)
router.get('/', auth, ridesController.getRides);

// Estimate ride fare
router.post('/estimate', auth, ridesController.estimateRide);

// Create a ride (passenger)
router.post('/', auth, ridesController.createRide);

// Get active ride
router.get('/active', auth, ridesController.getActiveRide);

// Get ride details
router.get('/:id', auth, ridesController.getRide);

// Cancel ride
router.post('/:id/cancel', auth, ridesController.cancelRide);

// Rate ride
router.post('/:id/rate', auth, ridesController.rateRide);

// Get messages
router.get('/:id/messages', auth, ridesController.getMessages);

module.exports = router;