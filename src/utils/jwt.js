const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'change_me';

// Sign access token (short-lived)
function signAccessToken(payload, expiresIn = '7d') {
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

// Sign refresh token (long-lived)
function signRefreshToken(payload, expiresIn = '30d') {
  return jwt.sign(payload, JWT_SECRET, { expiresIn }); // In prod, consider a separate secret
}

function verifyAccessToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

module.exports = { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken };
