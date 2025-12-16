const { User, Driver, UserDevice, Wallet } = require('../models');
const { hashPassword, comparePassword } = require('../utils/hash');
const { blacklistToken } = require('../utils/tokenBlacklist');
const jwt = require('jsonwebtoken');

async function getProfile(req, res) {
  try {
    const userId = req.user.userId;
    const user = await User.findByPk(userId, {
      attributes: [
        'id',
        'role',
        'first_name',
        'last_name',
        'phone',
        'profile_photo',
        'is_active',
        'created_at',
        'level',
        'ref_code',
        'ref_count',
        'referrer_id'
      ]
    });
    if (!user) return res.status(404).json({ message: 'User not found' });

    // if driver, include driver details
    let driver = null;
    if (user.role === 'driver') {
      const driverRecord = await Driver.findOne({
        where: { user_id: userId },
        attributes: ['vehicle_plate', 'vehicle_type', 'status', 'is_available']
      });

      if (driverRecord) {
        driver = driverRecord.toJSON();
        // Include wallet balance
        const wallet = await Wallet.findOne({ where: { user_id: userId } });
        driver.wallet_balance = wallet ? wallet.balance : 0.00;
      }
    }

    return res.json({ user, driver });
  } catch (err) {
    console.error('getProfile err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function updateProfile(req, res) {
  try {
    const userId = req.user.userId;
    const { first_name, last_name, profile_photo } = req.body;
    const user = await User.findByPk(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (first_name) user.first_name = first_name;
    if (last_name) user.last_name = last_name;
    if (profile_photo) user.profile_photo = profile_photo;
    await user.save();
    return res.json({ ok: true, user });
  } catch (err) {
    console.error('updateProfile err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function changePhone(req, res) {
  try {
    const userId = req.user.userId;
    const { new_phone } = req.body;
    if (!new_phone) return res.status(400).json({ message: 'new_phone required' });

    // ensure unique
    const exists = await User.findOne({ where: { phone: new_phone } });
    if (exists) return res.status(409).json({ message: 'Phone already in use' });

    const user = await User.findByPk(userId);
    user.phone = new_phone;
    await user.save();
    return res.json({ ok: true, phone: new_phone });
  } catch (err) {
    console.error('changePhone err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function changePassword(req, res) {
  try {
    const userId = req.user.userId;
    const { old_password, new_password } = req.body;
    if (!old_password || !new_password) return res.status(400).json({ message: 'old_password and new_password required' });

    const user = await User.findByPk(userId);
    const ok = await comparePassword(old_password, user.password_hash);
    if (!ok) return res.status(401).json({ message: 'Old password incorrect' });

    user.password_hash = await hashPassword(new_password);
    await user.save();

    // optional: blacklist current token to force re-login
    if (req.token) {
      const decoded = jwt.decode(req.token);
      const exp = decoded && decoded.exp ? decoded.exp * 1000 : null;
      if (exp) {
        const ttl = exp - Date.now();
        if (ttl > 0) await blacklistToken(req.token, ttl);
      }
    }

    return res.json({ ok: true });
  } catch (err) {
    console.error('changePassword err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function logout(req, res) {
  try {
    const token = req.token;
    if (!token) return res.json({ ok: true });
    const decoded = jwt.decode(token);
    const exp = decoded && decoded.exp ? decoded.exp * 1000 : null;
    if (exp) {
      const ttl = exp - Date.now();
      if (ttl > 0) {
        await blacklistToken(token, ttl);
      }
    }
    return res.json({ ok: true });
  } catch (err) {
    console.error('logout err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

// NEW: hesap silme (soft delete + token blacklist)
async function deleteAccount(req, res) {
  try {
    const userId = req.user.userId;
    const token = req.token;

    const user = await User.findByPk(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    // soft delete: is_active = false
    user.is_active = false;
    await user.save();

    // mevcut token'ı blacklist et
    if (token) {
      const decoded = jwt.decode(token);
      const exp = decoded && decoded.exp ? decoded.exp * 1000 : null;
      if (exp) {
        const ttl = exp - Date.now();
        if (ttl > 0) {
          await blacklistToken(token, ttl);
        }
      }
    }

    return res.json({ ok: true });
  } catch (err) {
    console.error('deleteAccount err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function registerDevice(req, res) {
  try {
    const userId = req.user.userId;
    const { device_token, platform } = req.body;

    if (!device_token) {
      return res.status(400).json({ message: 'device_token required' });
    }

    const plat = platform && ['android', 'ios', 'web'].includes(platform) ? platform : 'android';

    // Aynı token daha önce kayıtlıysa tekrar ekleme (silinebilir)
    const exists = await UserDevice.findOne({ where: { user_id: userId, device_token } });
    if (!exists) {
      await UserDevice.create({ user_id: userId, device_token, platform: plat });
    }

    return res.json({ ok: true });
  } catch (err) {
    console.error('registerDevice err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function uploadPhoto(req, res) {
  try {
    const userId = req.user.userId;
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    // Construct public URL (assuming server runs on port 3000 or configured host)
    // We'll store relative path or full URL. Relative is more flexible.
    // req.file.filename is the saved name.
    const photoUrl = `uploads/${req.file.filename}`;

    const user = await User.findByPk(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.profile_photo = photoUrl;
    await user.save();

    return res.json({ ok: true, photo_url: photoUrl });
  } catch (err) {
    console.error('uploadPhoto err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

module.exports = {
  getProfile,
  updateProfile,
  changePhone,
  changePassword,
  logout,
  deleteAccount,
  registerDevice,
  uploadPhoto
};