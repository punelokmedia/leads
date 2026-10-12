import express from 'express';
import mongoose from 'mongoose';
import { auth, isAdmin } from '../Middlewares/auth.middleware.js';
import { Notification, NotificationDevice, NotificationPreference, NotificationReceipt, defaultPreferences } from '../Models/notification.model.js';
import { notificationAdminRouter } from './notification-admin.routes.js';
import { User } from '../Models/user.model.js';
import { notifyUser } from '../Services/notification.service.js';

export const notificationRouter = express.Router();
notificationRouter.use(auth);
notificationRouter.use('/admin', notificationAdminRouter);
const validId = value => typeof value === 'string' && /^[a-f\d]{24}$/i.test(value);
const bad = res => res.status(400).json({ success: false, message: 'Invalid notification request.' });

notificationRouter.get('/', async (req, res) => {
  const { before, limit = '30', unread } = req.query;
  if ((before && !validId(before)) || typeof limit !== 'string' || !/^\d+$/.test(limit) || Number(limit) < 1 || Number(limit) > 100 || (unread !== undefined && !['true', 'false'].includes(unread))) return bad(res);
  const rows = await Notification.find({ user: req.user.id, ...(before ? { _id: { $lt: new mongoose.Types.ObjectId(before) } } : {}), ...(unread === 'true' ? { readAt: null } : {}) }).sort({ _id: -1 }).limit(Number(limit) + 1).select('-eventKey').lean();
  const hasMore = rows.length > Number(limit);
  if (hasMore) rows.pop();
  res.json({ success: true, data: rows, nextCursor: hasMore ? rows.at(-1)._id : null });
});
notificationRouter.get('/unread-count', async (req, res) => res.json({ success: true, data: { count: await Notification.countDocuments({ user: req.user.id, readAt: null }) } }));
notificationRouter.patch('/read-all', async (req, res) => {
  const result = await Notification.updateMany({ user: req.user.id, readAt: null }, { $set: { readAt: new Date() } });
  res.json({ success: true, data: { updated: result.modifiedCount } });
});
notificationRouter.get('/preferences', async (req, res) => {
  const row = await NotificationPreference.findOne({ user: req.user.id }).lean();
  res.json({ success: true, data: Object.fromEntries(Object.keys(defaultPreferences).map(key => [key, row?.[key] ?? defaultPreferences[key]])) });
});
notificationRouter.patch('/preferences', async (req, res) => {
  const body = req.body;
  if (!body || !Object.keys(body).length || Object.entries(body).some(([key, value]) => !(key in defaultPreferences) || !Object.hasOwn(defaultPreferences, key) || typeof value !== 'boolean')) return bad(res);
  const row = await NotificationPreference.findOneAndUpdate({ user: req.user.id }, { $set: body }, { upsert: true, returnDocument: 'after', runValidators: true });
  res.json({ success: true, data: Object.fromEntries(Object.keys(defaultPreferences).map(key => [key, row[key]])) });
});
notificationRouter.post('/devices', async (req, res) => {
  const { token, platform, permission } = req.body || {};
  if (typeof token !== 'string' || token.length < 20 || token.length > 4096 || /\s/.test(token) || !['android', 'ios', 'web'].includes(platform) || permission !== 'granted') return bad(res);
  // The client reports OS/browser permission; the server cannot grant it.
  // A token registered after an account switch belongs to the current account.
  await NotificationDevice.findOneAndUpdate({ token }, { $set: { user: req.user.id, platform, permission } }, { upsert: true, runValidators: true });
  res.status(201).json({ success: true });
});
notificationRouter.delete('/devices', async (req, res) => {
  if (typeof req.body?.token !== 'string') return bad(res);
  await NotificationDevice.deleteOne({ user: req.user.id, token: req.body.token });
  res.json({ success: true });
});
notificationRouter.post('/admin/send', isAdmin, async (req, res) => {
  const { userIds, title, message, clientId } = req.body || {};
  if (!Array.isArray(userIds) || !userIds.length || userIds.length > 100 || !userIds.every(validId) || typeof title !== 'string' || !title.trim() || title.trim().length > 150 || typeof message !== 'string' || !message.trim() || message.trim().length > 1000 || typeof clientId !== 'string' || !/^[\w-]{1,100}$/.test(clientId)) return bad(res);
  const users = await User.find({ _id: { $in: userIds }, role: 'USER', isBlocked: { $ne: true } }).select('_id');
  let recipients = 0;
  for (const user of users) {
    const row = await notifyUser({ user: user._id, eventKey: `announcement:${req.user.id}:${clientId}`, type: 'ANNOUNCEMENT', title: title.trim(), message: message.trim() });
    if (row) recipients++;
  }
  res.json({ success: true, data: { recipients } });
});
notificationRouter.patch('/:id/read', async (req, res) => {
  if (!validId(req.params.id)) return bad(res);
  const row = await Notification.findOneAndUpdate({ _id: req.params.id, user: req.user.id, readAt: null }, { $set: { readAt: new Date() } }, { returnDocument: 'after' });
  if (!row && !await Notification.exists({ _id: req.params.id, user: req.user.id })) return res.status(404).json({ success: false, message: 'Notification not found.' });
  res.json({ success: true });
});

// Client calls this only after receiving the inbox item. Fetching an inbox alone
// does not prove that the response reached the user's app or portal.
notificationRouter.post('/:id/received', async (req, res) => {
  const channel = req.body?.channel;
  if (!validId(req.params.id) || !['mobile', 'web'].includes(channel)) return bad(res);
  if (!await Notification.exists({ _id: req.params.id, user: req.user.id })) return res.status(404).json({ success: false, message: 'Notification not found.' });
  const key = { notification: req.params.id, channel };
  let receipt;
  try {
    receipt = await NotificationReceipt.findOneAndUpdate(key, { $setOnInsert: { ...key, user: req.user.id, receivedAt: new Date() } }, { upsert: true, returnDocument: 'after', runValidators: true });
  } catch (error) {
    if (error.code !== 11000) throw error;
    receipt = await NotificationReceipt.findOne(key);
  }
  res.json({ success: true, data: receipt });
});
