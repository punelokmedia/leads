import express from 'express';
import { auth } from '../Middlewares/auth.middleware.js';
import { ensureReferralCode, findReferralOwner, normalizeReferralCode } from '../Services/referral.service.js';

export const referralRouter = express.Router();
referralRouter.use(auth);

referralRouter.get('/me', async (req, res) => {
  try {
    const referralCode = await ensureReferralCode(req.user.id);
    if (!referralCode) return res.status(404).json({ success: false, message: 'User not found.' });
    return res.json({ success: true, data: { referralCode } });
  } catch (error) {
    console.error('Referral code lookup failed:', error.message);
    return res.status(503).json({ success: false, message: 'Referral code unavailable. Please retry.' });
  }
});

referralRouter.post('/validate', async (req, res) => {
  const referralCode = normalizeReferralCode(req.body?.referralCode);
  if (!referralCode) return res.status(400).json({ success: false, message: 'Invalid referral code format.' });
  try {
    const ownerId = await findReferralOwner(referralCode);
    if (!ownerId) return res.status(404).json({ success: false, message: 'Referral code not found.' });
    if (String(ownerId) === String(req.user.id)) {
      return res.status(400).json({ success: false, message: 'You cannot use your own referral code.' });
    }
    // Return no account details to the requesting client.
    return res.json({ success: true, data: { referralCode, valid: true } });
  } catch (error) {
    console.error('Referral validation failed:', error.message);
    return res.status(503).json({ success: false, message: 'Referral validation unavailable. Please retry.' });
  }
});
