import { WalletEntry } from '../Models/wallet.model.js';
import { WalletTopup } from '../Models/wallet.model.js';
import { SecurityAudit } from './security-audit.js';
import { User } from '../Models/user.model.js';
import mongoose from 'mongoose';
import { Referral } from '../Models/referral.model.js';
import { Order } from '../Models/orders.models.js';

export class ReferralError extends Error {
  constructor(message, status = 400) { super(message); this.status = status; }
}

export async function applyReferral(userId, value) {
  const code = normalizeReferralCode(value);
  if (!code) throw new ReferralError('Invalid referral code format.');
  const ownerId = await findReferralOwner(code);
  if (!ownerId) throw new ReferralError('Referral code not found.', 404);
  if (String(ownerId) === String(userId)) throw new ReferralError('You cannot refer yourself.');
  const session = await mongoose.startSession();
  try {
    return await session.withTransaction(async () => {
      // Checkout writes this same field so applying a code cannot race a purchase.
      const user = await User.findOneAndUpdate({ _id: userId, role: 'USER', isBlocked: { $ne: true } },
        { $inc: { referralVersion: 1 } }, { session, returnDocument: "after" });
      if (!user) throw new ReferralError('Account unavailable.', 403);
      const existing = await Referral.findOne({ referredUser: userId }).session(session);
      if (existing) {
        if (existing.code === code) return existing;
        throw new ReferralError('A referral has already been applied.', 409);
      }
      if (await Order.exists({ user: userId, status: 'PAID' }).session(session)) {
        throw new ReferralError('Apply a referral before your first lead purchase.', 409);
      }
      const owner = await User.exists({ _id: ownerId, role: 'USER', isBlocked: { $ne: true } }).session(session);
      if (!owner) throw new ReferralError('Referrer unavailable.', 409);
      const [referral] = await Referral.create([{ referrer: ownerId, referredUser: userId, code }], { session });
      return referral;
    });
  } finally { await session.endSession(); }
}

export async function qualifyReferral(userId, orderId, session) {
  await User.updateOne({ _id: userId }, { $inc: { referralVersion: 1 } }, { session });
  const referral = await Referral.findOneAndUpdate({ referredUser: userId, status: 'PENDING' }, {
    $set: { status: 'QUALIFIED', qualifyingOrder: orderId, qualifiedAt: new Date() },
  }, { session, returnDocument: 'after' });
  if (referral) {
    const owner = await User.findById(referral.referrer).select('+referralCreditPaise').session(session);
    const buyer = await User.findById(userId).session(session);
    const minimum = Number(process.env.WALLET_REFERRAL_MIN_PURCHASE_PAISE ?? 5000);
    if (!Number.isSafeInteger(minimum) || minimum < 0) throw new Error('Invalid referral minimum');
    const order = await Order.findOne({ _id: orderId, user: userId, status: 'PAID' }).session(session);
    const topups = await WalletTopup.find({ user: userId, status: 'PAID', disputed: { $ne: true } }).session(session);
    const deposited = topups.reduce((sum, item) => sum + item.amountPaise - (item.reversedPaise || 0), 0);
    const reciprocal = await Referral.exists({ referrer: userId, referredUser: referral.referrer }).session(session);
    if ((minimum > 0 && (!order || Math.round(order.totalAmount * 100) < minimum || deposited < minimum)) ||
        (buyer?.phoneNumber && buyer.phoneNumber === owner?.phoneNumber) || reciprocal || buyer?.walletFrozen || owner?.walletFrozen) {
      await Referral.updateOne({ _id: referral._id }, { $set: { status: 'REVIEW' } }, { session });
      await SecurityAudit.updateOne({ eventKey: `referral-review:${referral.id}` }, { $setOnInsert: { event: 'REFERRAL_REVIEW_REQUIRED', subject: String(userId) } }, { upsert: true, session });
      return;
    }
    const reward = Math.min(5000, 10000 - (owner?.referralCreditPaise ?? 0));
    if (owner && !owner.isBlocked && reward > 0) {
      await User.updateOne({ _id: owner._id }, { $inc: { walletBalancePaise: reward, referralCreditPaise: reward } }, { session });
      await WalletEntry.create([{ user: owner._id, key: 'referral:' + referral.id, kind: 'REFERRAL', amountPaise: reward }], { session });
    }
  }
}

export const referralCodeForId = (id) => `NL${id.toString().toUpperCase()}`;

export function normalizeReferralCode(value) {
  if (typeof value !== 'string') return null;
  const code = value.trim().toUpperCase();
  return /^NL[A-F0-9]{24}$/.test(code) ? code : null;
}

export async function ensureReferralCode(userId) {
  // Raw collection access avoids Mongoose defaults hiding a missing legacy field
  // and permits the one-time initialization of the immutable code.
  const users = User.collection;
  await users.updateOne(
    { _id: userId, $or: [{ referralCode: { $exists: false } }, { referralCode: null }] },
    { $set: { referralCode: referralCodeForId(userId) } },
  );
  const user = await users.findOne({ _id: userId }, { projection: { referralCode: 1 } });
  return user?.referralCode ?? null;
}

export async function findReferralOwner(code) {
  // Supports unbackfilled accounts without decoding a code into a mutable field.
  const userId = new User.base.Types.ObjectId(code.slice(2));
  const owner = await User.collection.findOne({
    isBlocked: { $ne: true }, role: 'USER',
    $or: [
      { referralCode: code },
      { _id: userId, $or: [{ referralCode: { $exists: false } }, { referralCode: null }] },
    ],
  }, { projection: { _id: 1 } });
  if (!owner) return null;
  await ensureReferralCode(owner._id);
  return owner._id;
}
