import { supportTicketRouter, ticketScope } from './support-ticket.routes.js';
import { notifyUser } from '../Services/notification.service.js';
import express from 'express';
import mongoose from 'mongoose';
import { auth, isAdmin } from '../Middlewares/auth.middleware.js';
import { SupportMessage } from '../Models/supportMessage.model.js';
import { User } from '../Models/user.model.js';
import { SupportTicket } from '../Models/supportTicket.model.js';

export const supportRouter = express.Router();
supportRouter.use(auth);
supportRouter.use(supportTicketRouter);

function messageView(row) {
  if (row.sender === 'automated') return { ...row, authorName: 'Automated support assistant' };
  const author = row.author;
  return { ...row, author: author?._id || author, authorName: [author?.firstname, author?.lastname].filter(Boolean).join(' ') || (row.sender === 'support' ? 'Support representative' : 'Customer') };
}

async function messages(req, res) {
  const user = req.params.userId || req.user.id;
  if (!mongoose.isValidObjectId(user)) return res.status(400).json({ success: false, message: 'Invalid user' });
  const filter = { user, ticket: req.supportTicket?._id || null };
  if (req.query.before) {
    if (!mongoose.isValidObjectId(req.query.before)) return res.status(400).json({ success: false, message: 'Invalid cursor' });
    filter._id = { $lt: req.query.before };
  }
  const rows = await SupportMessage.find(filter).sort({ _id: -1 }).limit(100).populate('author', 'firstname lastname').lean();
  res.set('Cache-Control', 'no-store');
  res.json({ success: true, data: rows.reverse().map(messageView) });
}

async function markRead(req, res) {
  const user = req.params.userId || req.user.id;
  const through = req.body?.through;
  if (!mongoose.isValidObjectId(user) || !mongoose.isValidObjectId(through)) return res.status(400).json({ success: false, message: 'A valid message ID is required.' });
  if (!await SupportMessage.exists({ _id: through, user, ticket: req.supportTicket?._id || null })) return res.status(404).json({ success: false, message: 'Message not found in this conversation.' });
  await SupportMessage.updateMany({ user, ticket: req.supportTicket?._id || null, sender: req.params.userId ? 'user' : 'support', _id: { $lte: new mongoose.Types.ObjectId(through) }, readAt: null }, { $set: { readAt: new Date() } });
  res.json({ success: true });
}

async function send(req, res) {
  const user = req.params.userId || req.user.id;
  const { text, clientId } = req.body ?? {};
  if (!mongoose.isValidObjectId(user) || typeof text !== 'string' || !text.trim() || text.trim().length > 2000 || typeof clientId !== 'string' || !/^[\w-]{1,100}$/.test(clientId)) {
    return res.status(400).json({ success: false, message: 'A message (1–2000 characters) and clientId are required' });
  }
  if (req.params.userId && !await User.exists({ _id: user })) return res.status(404).json({ success: false, message: 'User not found' });
  const key = { user, author: req.user.id, clientId, ticket: req.supportTicket?._id || null };
  const values = { ...key, sender: req.params.userId ? 'support' : 'user', text: text.trim() };
  let message;
  try {
    message = await SupportMessage.findOneAndUpdate(key, { $setOnInsert: values }, { upsert: true, returnDocument: "after", runValidators: true });
  } catch (error) {
    if (error.code !== 11000) throw error;
    message = await SupportMessage.findOne(key);
  }
  if (!message) return res.status(409).json({ success: false, message: 'Use a new clientId for this conversation.' });
  if (req.supportTicket && req.params.userId) await SupportTicket.updateOne({ _id: req.supportTicket._id, humanReplyAt: null }, { $set: { humanReplyAt: new Date() } });
  if (req.params.userId) await notifyUser({ user, eventKey: `support:${message._id}`, type: 'SUPPORT_REPLY', title: 'Support replied', message: 'You have a new reply from support.', targetId: message._id });
  await message.populate('author', 'firstname lastname');
  res.json({ success: true, data: messageView(message.toObject()) });
}

supportRouter.get('/tickets/:ticketId/messages', ticketScope, messages);
supportRouter.post('/tickets/:ticketId/messages', ticketScope, send);
supportRouter.post('/tickets/:ticketId/read', ticketScope, markRead);
supportRouter.get('/admin/tickets/:ticketId/messages', isAdmin, ticketScope, messages);
supportRouter.post('/admin/tickets/:ticketId/messages', isAdmin, ticketScope, send);
supportRouter.post('/admin/tickets/:ticketId/read', isAdmin, ticketScope, markRead);
supportRouter.get('/messages', messages);
supportRouter.post('/messages', send);
supportRouter.post('/read', markRead);
supportRouter.get('/admin/threads', isAdmin, async (req, res) => {
  const page = Math.max(1, Math.min(10000, Number.parseInt(req.query.page, 10) || 1));
  const rows = await SupportMessage.aggregate([
    { $match: { ticket: null } },
    { $sort: { _id: -1 } },
    { $group: { _id: '$user', text: { $first: '$text' }, updatedAt: { $first: '$createdAt' }, sender: { $first: '$sender' }, unreadCount: { $sum: { $cond: [{ $and: [{ $eq: ['$sender', 'user'] }, { $eq: [{ $ifNull: ['$readAt', null] }, null] }] }, 1, 0] } } } },
    { $sort: { updatedAt: -1 } }, { $skip: (page - 1) * 50 }, { $limit: 50 },
  ]);
  const accounts = await User.find({ _id: { $in: rows.map(row => row._id) } }).select('firstname lastname').lean();
  const names = new Map(accounts.map(account => [String(account._id), [account.firstname, account.lastname].filter(Boolean).join(' ')]));
  res.set('Cache-Control', 'no-store');
  res.json({ success: true, data: rows.map(row => ({ ...row, customerName: names.get(String(row._id)) || 'Customer' })) });
});
supportRouter.get('/admin/messages/:userId', isAdmin, messages);
supportRouter.post('/admin/messages/:userId', isAdmin, send);
supportRouter.post('/admin/read/:userId', isAdmin, markRead);
supportRouter.use((error, req, res, next) => {
  console.error('Support request failed:', error.name);
  res.status(500).json({ success: false, message: 'Support is unavailable. Please retry.' });
});
