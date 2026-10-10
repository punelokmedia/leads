import crypto from 'node:crypto';
import mongoose from 'mongoose';
const schema = new mongoose.Schema({ _id: String, count: { type: Number, default: 0 }, expiresAt: Date });
schema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
export const SecurityBucket = mongoose.model('SecurityBucket', schema);
export function sharedLimit(scope, maximum, windowMs, identity) {
  return async (req, res, next) => {
    try {
      const now = Date.now();
      const key = crypto.createHash('sha256').update(`${scope}:${identity(req)}:${Math.floor(now / windowMs)}`).digest('hex');
      let bucket;
      try { bucket = await SecurityBucket.findOneAndUpdate({ _id: key }, { $inc: { count: 1 }, $setOnInsert: { expiresAt: new Date((Math.floor(now / windowMs) + 2) * windowMs) } }, { upsert: true, returnDocument: 'after' }); }
      catch (error) { if (error.code !== 11000) throw error; bucket = await SecurityBucket.findOneAndUpdate({ _id: key }, { $inc: { count: 1 } }, { returnDocument: 'after' }); }
      if (bucket.count > maximum) { res.set('Retry-After', String(Math.ceil((windowMs - now % windowMs) / 1000))); return res.status(429).json({ success: false, code: 'RATE_LIMITED', message: 'Too many attempts. Please try again later.' }); }
      next();
    } catch { res.status(503).json({ success: false, message: 'Security checks unavailable. Please retry.' }); }
  };
}
const ip = req => req.ip || req.socket?.remoteAddress || 'unknown';
const account = req => String(req.body?.email || req.body?.phoneNumber || req.user?.id || ip(req)).trim().toLowerCase();
const ipLimit = sharedLimit('auth-ip', 60, 15 * 60000, ip);
const attemptLimit = sharedLimit('otp-account', 5, 15 * 60000, account);
const issueLimit = sharedLimit('otp-issue', 3, 15 * 60000, account);
export function authLimits(req, res, next) {
  if (req.method !== 'POST') return next();
  return ipLimit(req, res, () => {
    if (/verify.*otp|reset-password|change-password|\/login$/.test(req.path)) return attemptLimit(req, res, next);
    if (/otp|forgot-password/.test(req.path)) return issueLimit(req, res, next);
    next();
  });
}
export const walletLimit = sharedLimit('wallet-mutation', 20, 60000, req => String(req.user.id));
export const paymentLimit = sharedLimit('payment-mutation', 20, 60000, req => String(req.user.id));
export const referralLimit = sharedLimit('referral-mutation', 10, 60000, req => String(req.user.id));
