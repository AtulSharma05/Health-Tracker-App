const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_me';

async function requireUnifiedAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    if (!token) {
      return res.status(401).json({ message: 'Missing auth token' });
    }

    const payload = jwt.verify(token, JWT_SECRET);
    const userId = payload.sub || payload.id || payload.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Invalid auth token payload' });
    }

    const user = await User.findById(userId).select('_id name email');
    if (!user) {
      return res.status(401).json({ message: 'User not found for token' });
    }

    req.user = user;
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

module.exports = { requireUnifiedAuth };