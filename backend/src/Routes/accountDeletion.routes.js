import express from 'express';
import { requestAccountDeletion } from '../Controllers/accountDeletion.controller.js';
import { AccountDeletionRequest } from '../Models/accountDeletionRequest.model.js';
import { auth, isAdmin } from '../Middlewares/auth.middleware.js';

export const accountDeletionRouter = express.Router();
accountDeletionRouter.post('/', requestAccountDeletion);
accountDeletionRouter.get('/', auth, isAdmin, async (req, res) => {
  try {
    const page = Math.max(1, Math.min(10000, Number.parseInt(req.query.page, 10) || 1));
    const requests = await AccountDeletionRequest.find().sort({ createdAt: -1 }).skip((page - 1) * 50).limit(50).lean();
    res.json({ success: true, data: requests, page });
  } catch {
    res.status(503).json({ success: false, message: 'Unable to load deletion requests.' });
  }
});
