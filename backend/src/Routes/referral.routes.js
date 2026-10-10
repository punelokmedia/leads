import express from 'express';
import { referralLimit } from '../Middlewares/security-limits.js';
import { auth } from '../Middlewares/auth.middleware.js';
import { ensureReferralCode, findReferralOwner, normalizeReferralCode, applyReferral, ReferralError } from '../Services/referral.service.js';
import { Referral } from '../Models/referral.model.js';

export const referralRouter = express.Router();
referralRouter.use(auth);
referralRouter.use((req, res, next) => req.method === 'POST' ? referralLimit(req, res, next) : next());

referralRouter.get('/me', async (req, res) => {
  try {
    const referralCode = await ensureReferralCode(req.user.id);
    if (!referralCode) return res.status(404).json({ success: false, message: 'User not found.' });
    const [invited, qualified, applied] = await Promise.all([
      Referral.countDocuments({ referrer: req.user.id }),
      Referral.countDocuments({ referrer: req.user.id, status: 'QUALIFIED' }),
      Referral.findOne({ referredUser: req.user.id }).select('code status').lean(),
    ]);
    const referralLink = new URL('/auth/mobile', process.env.REFERRAL_WEB_URL || 'https://www.trynextlead.com');
    referralLink.searchParams.set('ref', referralCode);
    const appDownloadLink = process.env.APP_DOWNLOAD_URL || null;
    return res.json({ success: true, data: { referralCode, referralLink: referralLink.toString(), appDownloadLink, invited, qualified, pending: invited - qualified, appliedReferral: applied } });
  } catch (error) {
    console.error('Referral code lookup failed:', error.message);
    return res.status(503).json({ success: false, message: 'Referral code unavailable. Please retry.' });
  }
});

referralRouter.post('/apply', async (req, res) => {
  try {
    const referral = await applyReferral(req.user.id, req.body?.referralCode);
    return res.json({ success: true, data: { referralCode: referral.code, status: referral.status } });
  } catch (error) {
    return res.status(error instanceof ReferralError ? error.status : 503).json({
      success: false, message: error instanceof ReferralError ? error.message : 'Unable to apply referral. Please retry.',
    });
  }
});

referralRouter.get('/history', async (req, res) => {
  try {
    const page = Math.min(1000, Math.max(1, Number.parseInt(req.query.page, 10) || 1));
    const limit = Math.min(50, Math.max(1, Number.parseInt(req.query.limit, 10) || 20));
    const query = { referrer: req.user.id };
    const [data, total] = await Promise.all([
      Referral.find(query).select('_id status createdAt qualifiedAt').sort({ createdAt: -1, _id: -1 }).skip((page - 1) * limit).limit(limit).lean(),
      Referral.countDocuments(query),
    ]);
    return res.json({ success: true, data, pagination: { page, limit, total } });
  } catch {
    return res.status(503).json({ success: false, message: 'Referral history unavailable.' });
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
