const { verifyAccessToken } = require('../utils/jwt');
const { isBlacklisted } = require('../utils/tokenBlacklist');

async function authMiddleware(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header) return res.status(401).json({ message: 'Authorization header missing' });
    const parts = header.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') return res.status(401).json({ message: 'Invalid auth format' });
    const token = parts[1];

    // check blacklist
    if (await isBlacklisted(token)) return res.status(401).json({ message: 'Token invalidated' });

    const payload = verifyAccessToken(token); // throws if invalid
    req.user = payload; // { userId, role, iat, exp ... }
    req.token = token;
    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
}

module.exports = authMiddleware;