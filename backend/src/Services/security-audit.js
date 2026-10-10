import crypto from 'node:crypto';
import mongoose from 'mongoose';
export const SecurityAudit = mongoose.model('SecurityAudit', new mongoose.Schema({
  eventKey: { type: String, required: true, unique: true }, event: { type: String, required: true }, subject: String,
  createdAt: { type: Date, default: Date.now, immutable: true }, exportedAt: Date,
  detail: mongoose.Schema.Types.Mixed,
}));
export function ledgerSignature(entry) {
  const secret = process.env.WALLET_LEDGER_HMAC_KEY;
  if (process.env.NODE_ENV === 'production' && (!secret || Buffer.byteLength(secret) < 32)) throw new Error('WALLET_LEDGER_HMAC_KEY must contain at least 32 bytes');
  if (!secret) { if (process.env.NODE_ENV === 'production') throw new Error('WALLET_LEDGER_HMAC_KEY must be configured'); return undefined; }
  return crypto.createHmac('sha256', secret).update(JSON.stringify([String(entry._id), String(entry.user), entry.key, entry.kind, entry.amountPaise, entry.createdAt?.toISOString()])).digest('hex');
}
export async function exportSecurityAudit() {
  const url = process.env.SECURITY_AUDIT_URL;
  if (!url) return;
  if (new URL(url).protocol !== 'https:') throw new Error('Audit sink must use HTTPS');
  const events = await SecurityAudit.find({ exportedAt: { $exists: false } }).sort({ _id: 1 }).limit(100).lean();
  if (!events.length) return;
  const response = await fetch(url, { method: 'POST', signal: AbortSignal.timeout(10000), headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${process.env.SECURITY_AUDIT_TOKEN || ''}` }, body: JSON.stringify({ events }) });
  if (!response.ok) throw new Error('Audit export failed');
  await SecurityAudit.updateMany({ _id: { $in: events.map(e => e._id) } }, { $set: { exportedAt: new Date() } });
}
