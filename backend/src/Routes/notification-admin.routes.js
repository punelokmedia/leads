import express from 'express';
import mongoose from 'mongoose';
import { isAdmin } from '../Middlewares/auth.middleware.js';
import { Notification, NotificationReceipt, NotificationDevice, NotificationPreference, notificationTypes, defaultPreferences } from '../Models/notification.model.js';
import { User } from '../Models/user.model.js';

export const notificationAdminRouter = express.Router();
notificationAdminRouter.use(isAdmin);
const validId = value => typeof value === 'string' && /^[a-f\d]{24}$/i.test(value);
function filter(query) {
  const match = {};
  if (query.userId !== undefined) {
    if (!validId(query.userId)) throw new Error('Invalid userId');
    match.user = new mongoose.Types.ObjectId(query.userId);
  }
  if (query.type !== undefined) {
    if (!notificationTypes.includes(query.type)) throw new Error('Invalid type');
    match.type = query.type;
  }
  if (query.read !== undefined) {
    if (!['true', 'false'].includes(query.read)) throw new Error('Invalid read filter');
    match.readAt = query.read === 'true' ? { $ne: null } : null;
  }
  for (const [key, operator] of [['from', '$gte'], ['to', '$lte']]) {
    if (query[key] === undefined) continue;
    if (typeof query[key] !== 'string' || !/^\d{4}-\d{2}-\d{2}T/.test(query[key]) || !Number.isFinite(Date.parse(query[key]))) throw new Error('Use ISO timestamps for from/to');
    match.createdAt = { ...match.createdAt, [operator]: new Date(query[key]) };
  }
  if (query.from && query.to && new Date(query.from) > new Date(query.to)) throw new Error('Invalid date range');
  return match;
}
const receiptLookup = { $lookup: { from: NotificationReceipt.collection.name, localField: '_id', foreignField: 'notification', as: 'receipts' } };
const status = row => ({ ...row, inboxStatus: 'SAVED', receiptStatus: row.receipts?.length ? 'RECEIVED' : 'AWAITING_CLIENT', pushStatus: 'NOT_CONFIGURED' });

notificationAdminRouter.get('/recipients', async (req, res) => {
  const { q = '', before } = req.query;
  if (typeof q !== 'string' || q.length > 100 || (before !== undefined && !validId(before))) return res.status(400).json({ success: false, message: 'Invalid recipient search.' });
  const text = q.trim();
  const literal = new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  const match = { role: 'USER', isBlocked: { $ne: true }, ...(before ? { _id: { $lt: new mongoose.Types.ObjectId(before) } } : {}),
    ...(text ? { $or: [{ firstname: literal }, { lastname: literal }, { email: literal }, ...(validId(text) ? [{ _id: new mongoose.Types.ObjectId(text) }] : [])] } : {}),
  };
  const rows = await User.find(match).sort({ _id: -1 }).limit(31).select('firstname lastname email').lean();
  const hasMore = rows.length > 30;
  if (hasMore) rows.pop();
  res.json({ success: true, data: rows, nextCursor: hasMore ? rows.at(-1)._id : null });
});

notificationAdminRouter.get('/summary', async (req, res) => {
  let match;
  try { match = filter(req.query); } catch (error) { return res.status(400).json({ success: false, message: error.message }); }
  const [data] = await Notification.aggregate([
    { $match: match }, receiptLookup,
    { $facet: {
      totals: [{ $group: { _id: null, saved: { $sum: 1 }, read: { $sum: { $cond: [{ $ne: ['$readAt', null] }, 1, 0] } },
        received: { $sum: { $cond: [{ $gt: [{ $size: '$receipts' }, 0] }, 1, 0] } },
        mobileReceived: { $sum: { $cond: [{ $in: ['mobile', '$receipts.channel'] }, 1, 0] } },
        webReceived: { $sum: { $cond: [{ $in: ['web', '$receipts.channel'] }, 1, 0] } },
      } }],
      byType: [{ $group: { _id: '$type', saved: { $sum: 1 }, read: { $sum: { $cond: [{ $ne: ['$readAt', null] }, 1, 0] } } } }, { $sort: { _id: 1 } }],
    } },
  ]);
  const { _id, ...totals } = data.totals[0] || { saved: 0, read: 0, received: 0, mobileReceived: 0, webReceived: 0 };
  res.json({ success: true, data: { ...totals, unread: totals.saved - totals.read, awaitingClient: totals.saved - totals.received,
    byType: notificationTypes.map(type => ({ type, saved: data.byType.find(row => row._id === type)?.saved || 0, read: data.byType.find(row => row._id === type)?.read || 0 })),
    push: { configured: false, status: 'NOT_CONFIGURED' },
  } });
});
notificationAdminRouter.get('/notifications', async (req, res) => {
  let match;
  const { before, limit = '30' } = req.query;
  try {
    match = filter(req.query);
    if (before !== undefined && !validId(before)) throw new Error('Invalid cursor');
    if (typeof limit !== 'string' || !/^\d+$/.test(limit) || Number(limit) < 1 || Number(limit) > 100) throw new Error('Invalid limit');
  } catch (error) { return res.status(400).json({ success: false, message: error.message }); }
  if (before) match._id = { $lt: new mongoose.Types.ObjectId(before) };
  const rows = await Notification.aggregate([{ $match: match }, { $sort: { _id: -1 } }, { $limit: Number(limit) + 1 }, receiptLookup]);
  const hasMore = rows.length > Number(limit);
  if (hasMore) rows.pop();
  res.json({ success: true, data: rows.map(status), nextCursor: hasMore ? rows.at(-1)._id : null });
});
notificationAdminRouter.get('/notifications/:id', async (req, res) => {
  if (!validId(req.params.id)) return res.status(400).json({ success: false, message: 'Invalid notification ID.' });
  const row = await Notification.findById(req.params.id).lean();
  if (!row) return res.status(404).json({ success: false, message: 'Notification not found.' });
  const [recipient, receipts, preference, devices] = await Promise.all([
    User.findById(row.user).select('firstname lastname email role isBlocked').lean(),
    NotificationReceipt.find({ notification: row._id }).lean(),
    NotificationPreference.findOne({ user: row.user }).lean(),
    NotificationDevice.find({ user: row.user }).select('platform permission createdAt updatedAt').lean(),
  ]);
  res.json({ success: true, data: { ...status({ ...row, receipts }), recipient, preferences: Object.fromEntries(Object.keys(defaultPreferences).map(key => [key, preference?.[key] ?? defaultPreferences[key]])), devices } });
});
