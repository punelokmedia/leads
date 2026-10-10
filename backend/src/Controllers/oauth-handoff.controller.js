import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { OAuthHandoff } from '../Models/oauth-handoff.model.js';
import { User } from '../Models/user.model.js';
export async function exchangeGoogleCode(req, res) {
  res.set('Cache-Control', 'no-store');
  const { code, verifier } = req.body ?? {};
  if (typeof code !== 'string' || !/^[a-f0-9]{64}$/.test(code) || typeof verifier !== 'string' || !/^[a-f0-9]{64}$/.test(verifier)) return res.status(400).json({ success: false, message: 'Invalid login exchange.' });
  try {
    const record = await OAuthHandoff.findOneAndDelete({ codeHash: crypto.createHash('sha256').update(code).digest('hex'), challenge: crypto.createHash('sha256').update(verifier).digest('base64url'), expiresAt: { $gt: new Date() } });
    if (!record) return res.status(401).json({ success: false, message: 'Login expired or already used.' });
    const user = await User.findById(record.user);
    if (!user || user.isBlocked || (user.sessionVersion ?? 0) !== record.sessionVersion) return res.status(403).json({ success: false, message: 'Account unavailable.' });
    const token = jwt.sign({ id: user._id, sv: user.sessionVersion ?? 0 }, process.env.JWT_SECRET, { expiresIn: '7d' });
    return res.json({ success: true, token, data: user });
  } catch { return res.status(503).json({ success: false, message: 'Login unavailable.' }); }
}
