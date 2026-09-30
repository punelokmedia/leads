import express from 'express';
import mongoose from 'mongoose';
import { auth, isAdmin } from '../Middlewares/auth.middleware.js';
import { SupportMessage } from '../Models/supportMessage.model.js';
import { User } from '../Models/user.model.js';

export const supportRouter = express.Router();
supportRouter.use(auth);

async function messages(req, res) {
  const user = req.params.userId || req.user.id;
  if (!mongoose.isValidObjectId(user)) return res.status(400).json({ success: false, message: 'Invalid user' });
  const filter = { user };
  if (req.query.before) {
    if (!mongoose.isValidObjectId(req.query.before)) return res.status(400).json({ success: false, message: 'Invalid cursor' });
    filter._id = { $lt: req.query.before };
  }
  const rows = await SupportMessage.find(filter).sort({ _id: -1 }).limit(100).lean();
  res.json({ success: true, data: rows.reverse() });
}

async function send(req, res) {
  const user = req.params.userId || req.user.id;
  const { text, clientId } = req.body;
  if (!mongoose.isValidObjectId(user) || typeof text !== 'string' || !text.trim() || text.trim().length > 2000 || typeof clientId !== 'string' || !/^[\w-]{1,100}$/.test(clientId)) {
    return res.status(400).json({ success: false, message: 'A message (1–2000 characters) and clientId are required' });
  }
  if (req.params.userId && !await User.exists({ _id: user })) return res.status(404).json({ success: false, message: 'User not found' });
  const key = { user, author: req.user.id, clientId };
  const values = { ...key, sender: req.params.userId ? 'support' : 'user', text: text.trim() };
  let message;
  try {
    message = await SupportMessage.findOneAndUpdate(key, { $setOnInsert: values }, { upsert: true, new: true, runValidators: true });
  } catch (error) {
    if (error.code !== 11000) throw error;
    message = await SupportMessage.findOne(key);
  }
  res.json({ success: true, data: message });
}

supportRouter.get('/messages', messages);
supportRouter.post('/messages', send);
supportRouter.get('/admin/threads', isAdmin, async (req, res) => {
  const page = Math.max(1, Math.min(10000, Number.parseInt(req.query.page, 10) || 1));
  const rows = await SupportMessage.aggregate([
    { $sort: { _id: -1 } },
    { $group: { _id: '$user', text: { $first: '$text' }, updatedAt: { $first: '$createdAt' }, sender: { $first: '$sender' } } },
    { $sort: { updatedAt: -1 } }, { $skip: (page - 1) * 50 }, { $limit: 50 },
  ]);
  res.json({ success: true, data: rows });
});
supportRouter.get('/admin/messages/:userId', isAdmin, messages);
supportRouter.post('/admin/messages/:userId', isAdmin, send);
supportRouter.use((error, req, res, next) => {
  console.error('Support request failed:', error.name);
  res.status(500).json({ success: false, message: 'Support is unavailable. Please retry.' });
});
