const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const otpController = require('../controllers/otpController');
const authenticateToken = require('../middlewares/auth');
const rateLimiter = require('../middlewares/rateLimiter');

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure Multer for Registration Uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadDir = 'uploads/drivers/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        // We might not have userId yet, so use timestamp and random
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, 'driver-' + uniqueSuffix + ext);
    }
});

const upload = multer({ storage: storage });

const registerUploads = upload.fields([
    { name: 'photo', maxCount: 1 },
    { name: 'vehicle_license', maxCount: 1 },
    { name: 'ibb_card', maxCount: 1 },
    { name: 'driving_license', maxCount: 1 },
    { name: 'identity_card', maxCount: 1 }
]);

// OTP Routes
// Limit: 3 requests per 3 minutes (180000 ms)
router.post('/send-otp', rateLimiter({
    windowMs: 3 * 60 * 1000,
    max: 3,
    keyPrefix: 'rl:otp',
    message: 'Çok fazla SMS isteği gönderdiniz. Lütfen 3 dakika bekleyin.'
}), otpController.sendOtp);
router.post('/verify-otp', otpController.verifyOtp);

// Registration (after OTP verification for new users)
router.post('/register', registerUploads, authController.register);

// Secure routes
router.post('/device-token', authenticateToken, authController.updateDeviceToken);
router.post('/refresh-token', authController.refreshToken);

module.exports = router;
