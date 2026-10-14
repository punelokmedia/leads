import express from 'express';
import mongoose from 'mongoose';
import { isAdmin } from '../Middlewares/auth.middleware.js';
import { SupportTicket, SUPPORT_ISSUES, SUPPORT_STATUSES } from '../Models/supportTicket.model.js';
import { SUPPORT_HELP, automatedMessage } from '../Services/support-automation.js';

export const supportTicketRouter = express.Router();
export async function ticketScope(req, res, next) {
  if (!mongoose.isValidObjectId(req.params.ticketId)) return res.status(400).json({ success: false, message: 'Invalid ticket.' });
  const admin = req.path.startsWith('/admin/');
  const ticket = await SupportTicket.findOne({ _id: req.params.ticketId, ...(admin ? {} : { user: req.user.id }) });
  if (!ticket) return res.status(404).json({ success: false, message: 'Ticket not found.' });
  req.supportTicket = ticket;
  if (admin) req.params.userId = String(ticket.user);
  next();
}
async function list(req, res) {
  const admin = req.path.startsWith('/admin/');
  const status = req.query.status;
  if (status && !SUPPORT_STATUSES.includes(status)) return res.status(400).json({ success: false, message: 'Invalid ticket status.' });
  const page = Math.max(1, Math.min(10000, Number.parseInt(req.query.page, 10) || 1));
  const query = { ...(admin ? {} : { user: req.user.id }), ...(status ? { status } : {}) };
  const [rows, total] = await Promise.all([SupportTicket.find(query).sort({ _id: -1 }).skip((page - 1) * 30).limit(30).populate('user', 'firstname lastname').lean(), SupportTicket.countDocuments(query)]);
  res.set('Cache-Control', 'no-store');
  res.json({ success: true, data: rows, pagination: { page, total, totalPages: Math.ceil(total / 30) } });
}
supportTicketRouter.get('/tickets', list);
supportTicketRouter.get('/admin/tickets', isAdmin, list);
supportTicketRouter.post('/tickets', async (req, res) => {
  const { issue, description, clientId } = req.body ?? {};
  if (!SUPPORT_ISSUES.includes(issue) || typeof description !== 'string' || !description.trim() || description.trim().length > 2000 || typeof clientId !== 'string' || !/^[\w-]{1,100}$/.test(clientId)) return res.status(400).json({ success: false, message: 'Select an issue and enter a description (1-2000 characters) and clientId.' });
  const key = { user: req.user.id, clientId };
  const id = new mongoose.Types.ObjectId();
  let ticket;
  try {
    ticket = await SupportTicket.findOneAndUpdate(key, { $setOnInsert: { ...key, _id: id, ticketId: `NL-${String(id).toUpperCase()}`, issue, description: description.trim(), status: 'PENDING', statusHistory: [{ status: 'PENDING', actor: req.user.id, at: new Date() }] } }, { upsert: true, returnDocument: 'after', runValidators: true });
  } catch (error) { if (error.code !== 11000) throw error; ticket = await SupportTicket.findOne(key); }
  if (!ticket || ticket.issue !== issue || ticket.description !== description.trim()) return res.status(409).json({ success: false, message: 'Use a new clientId for a different request.' });
  await automatedMessage(ticket, 'START');
  res.json({ success: true, data: ticket });
});
supportTicketRouter.get('/tickets/:ticketId', ticketScope, (req, res) => res.json({ success: true, data: req.supportTicket }));
supportTicketRouter.post('/tickets/:ticketId/automation', ticketScope, async (req, res) => {
  const choice = req.body?.choice;
  if (choice !== 'HUMAN' && !Object.hasOwn(SUPPORT_HELP, choice)) return res.status(400).json({ success: false, message: 'Select a valid support option.' });
  if (req.supportTicket.status === 'COMPLETED') return res.status(409).json({ success: false, message: 'This ticket is completed. Create a new ticket if you need more help.' });
  if (choice !== 'HUMAN' && (req.supportTicket.humanRequestedAt || req.supportTicket.humanReplyAt)) return res.status(409).json({ success: false, message: 'Human support is handling this ticket. Send your message in the conversation.' });
  if (choice === 'HUMAN') {
    await SupportTicket.updateOne({ _id: req.supportTicket._id, humanRequestedAt: null }, { $set: { humanRequestedAt: new Date() } });
  }
  await automatedMessage(req.supportTicket, choice);
  res.json({ success: true });
});
supportTicketRouter.get('/admin/tickets/:ticketId', isAdmin, ticketScope, (req, res) => res.json({ success: true, data: req.supportTicket }));
supportTicketRouter.post('/admin/tickets/:ticketId/status', isAdmin, ticketScope, async (req, res) => {
  const { status, expectedStatus } = req.body ?? {};
  if (!SUPPORT_STATUSES.includes(status) || !SUPPORT_STATUSES.includes(expectedStatus)) return res.status(400).json({ success: false, message: 'Valid status and expectedStatus are required.' });
  if (status === req.supportTicket.status && status === expectedStatus) return res.json({ success: true, data: req.supportTicket });
  const ticket = await SupportTicket.findOneAndUpdate({ _id: req.supportTicket._id, status: expectedStatus }, { $set: { status }, $push: { statusHistory: { status, actor: req.user.id, at: new Date() } } }, { returnDocument: 'after', runValidators: true });
  if (!ticket) return res.status(409).json({ success: false, message: 'Ticket changed. Refresh before updating.' });
  res.json({ success: true, data: ticket });
});
