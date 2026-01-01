const { Notification } = require('../models');

async function listNotifications(req, res) {
  try {
    const userId = req.user.userId;
    const page = parseInt(req.query.page || '1', 10);
    const limit = parseInt(req.query.limit || '30', 10);
    const offset = (page - 1) * limit;
    const notifications = await Notification.findAll({
      where: { user_id: userId },
      order: [['created_at', 'DESC']],
      limit,
      offset
    });
    const { formatTurkeyDate } = require('../utils/dateUtils');
    const notificationsFormatted = notifications.map(n => {
      const plain = n.toJSON();
      plain.formatted_date = formatTurkeyDate(n.created_at);
      return plain;
    });

    return res.json({ notifications: notificationsFormatted });
  } catch (err) {
    console.error('listNotifications err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function markRead(req, res) {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    await Notification.update({ is_read: true }, { where: { id, user_id: userId } });
    return res.json({ ok: true });
  } catch (err) {
    console.error('markRead err', err);
    return res.status(500).json({ message: 'Server error' });
  }
}

module.exports = { listNotifications, markRead };