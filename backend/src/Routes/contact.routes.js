import express from 'express';
import { submitContact } from '../Controllers/contact.controller.js';
import { sharedLimit } from '../Middlewares/security-limits.js';
import { auth, isAdmin } from '../Middlewares/auth.middleware.js';
import { ContactMessage } from '../Models/contact.model.js';
export const contactRouter = express.Router();
contactRouter.post('/', sharedLimit('contact-ip', 5, 15 * 60000, req => req.ip || req.socket?.remoteAddress || 'unknown'), submitContact);
contactRouter.get('/', auth, isAdmin, async (req, res) => {
  const page = Math.max(1, Math.min(1000, parseInt(req.query.page, 10) || 1));
  try {
    const [data, total] = await Promise.all([ContactMessage.find().sort({ createdAt: -1, _id: -1 }).skip((page - 1) * 20).limit(20).lean(), ContactMessage.countDocuments()]);
    return res.json({ success: true, data, pagination: { page, limit: 20, total } });
  } catch { return res.status(503).json({ success: false, message: 'Unable to load contact enquiries.' }); }
});
