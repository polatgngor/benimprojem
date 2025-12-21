const express = require('express');
const router = express.Router();
const { updatePlate, getEarnings } = require('../controllers/driverController');
const auth = require('../middlewares/auth');

router.put('/plate', auth, updatePlate);
router.get('/earnings', auth, getEarnings);

module.exports = router;