import mongoose from 'mongoose';
import { User } from '../Models/user.model.js';
import { WalletEntry, WalletTopup } from '../Models/wallet.model.js';
import { Referral } from '../Models/referral.model.js';
import { CheckoutError } from './lead-inventory.js';

export async function walletTransaction(work) {
  const session = await mongoose.startSession();
  try { return await session.withTransaction(() => work(session), { readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' } }); }
  finally { await session.endSession(); }
}

export async function creditCapturedTopup(payment, userId) {
  return walletTransaction(async session => {
    const topup = await WalletTopup.findOne({ gatewayOrderId: payment.order_id }).session(session);
    if (!topup || (userId && String(topup.user) !== String(userId))) throw new CheckoutError('TOPUP_NOT_FOUND', 'Top-up not found.', 404);
    if (payment.status !== 'captured' || payment.currency !== 'INR' || payment.amount !== topup.amountPaise || payment.amount_refunded > 0) throw new CheckoutError('PAYMENT_MISMATCH', 'Payment is not a valid captured top-up.', 400);
    if (topup.status === 'PAID') {
      if (topup.paymentId !== payment.id) throw new CheckoutError('DUPLICATE_PAYMENT', 'Top-up already paid with another payment.', 409);
      return topup;
    }
    topup.status = 'PAID';
    topup.paymentId = payment.id;
    await topup.save({ session });
    const user = await User.updateOne({ _id: topup.user, role: 'USER' }, { $inc: { walletBalancePaise: topup.amountPaise } }, { session });
    if (!user.matchedCount) throw new CheckoutError('USER_NOT_FOUND', 'Account unavailable.', 409);
    await WalletEntry.create([{ user: topup.user, key: `topup:${topup.id}`, kind: 'TOPUP', amountPaise: topup.amountPaise }], { session });
    return topup;
  });
}

export async function purchaseMembership(userId) {
  return walletTransaction(async session => {
    const current = await User.findOne({ _id: userId, role: 'USER', isBlocked: { $ne: true } }).session(session);
    if (!current) throw new CheckoutError('USER_NOT_FOUND', 'Account unavailable.', 403);
    if (current.walletFrozen) throw new CheckoutError('WALLET_FROZEN', 'Wallet is under security review. Contact support.', 403);
    if (current.registrationFeePaid) return { status: 'PAID' };
    const user = await User.findOneAndUpdate({ _id: userId, registrationFeePaid: false, walletBalancePaise: { $gte: 100 }, isBlocked: { $ne: true } }, {
      $inc: { walletBalancePaise: -100 }, $set: { registrationFeePaid: true, registrationFeePaidAt: new Date(), registrationPayment: { amount: 1, currency: 'INR' } },
    }, { session });
    if (!user) throw new CheckoutError('INSUFFICIENT_BALANCE', 'Add money to your wallet first.', 409);
    await WalletEntry.create([{ user: userId, key: `membership:${userId}`, kind: 'MEMBERSHIP', amountPaise: -100 }], { session });
    return { status: 'PAID' };
  });
}

// Gateway-authoritative cumulative refund totals make duplicate/out-of-order events safe.
export async function reverseTopup(payment, dispute = false) {
  return walletTransaction(async session => {
    const topup = await WalletTopup.findOne({ paymentId: payment.id, status: 'PAID' }).session(session);
    if (!topup) return { ignored: true };
    if (payment.order_id !== topup.gatewayOrderId || payment.currency !== 'INR' || payment.amount !== topup.amountPaise) throw new CheckoutError('PAYMENT_MISMATCH', 'Invalid reversal payment.', 400);
    const target = dispute ? topup.amountPaise : payment.amount_refunded;
    if (!Number.isSafeInteger(target) || target < 0 || target > topup.amountPaise) throw new CheckoutError('INVALID_REVERSAL', 'Invalid refund total.', 400);
    if (dispute) topup.disputed = true;
    const delta = target - (topup.reversedPaise || 0);
    if (delta <= 0) return { reversedPaise: topup.reversedPaise };
    const user = await User.findById(topup.user).select('+walletBalancePaise +walletDebtPaise').session(session);
    if (!user) throw new Error('Reversal account missing');
    const debit = Math.min(user.walletBalancePaise || 0, delta);
    await User.updateOne({ _id: user._id }, { $inc: { walletBalancePaise: -debit, walletDebtPaise: delta - debit }, $set: { walletFrozen: true, walletFrozenReason: dispute ? 'PAYMENT_DISPUTE' : 'TOPUP_REFUND' } }, { session });
    await WalletEntry.create([{ user: user._id, key: `reversal:${topup.id}:${target}`, kind: 'REVERSAL', amountPaise: -delta }], { session });
    topup.reversedPaise = target;
    await topup.save({ session });
    const referral = await Referral.findOne({ referredUser: topup.user, status: 'QUALIFIED' }).session(session);
    if (referral) {
      const reward = await WalletEntry.findOne({ key: `referral:${referral.id}` }).session(session);
      if (reward) {
        const owner = await User.findById(referral.referrer).select('+walletBalancePaise').session(session);
        if (!owner) throw new Error('Referral reversal account missing');
        const recovered = Math.min(owner.walletBalancePaise || 0, reward.amountPaise);
        await User.updateOne({ _id: owner._id }, { $inc: { walletBalancePaise: -recovered, walletDebtPaise: reward.amountPaise - recovered }, $set: { walletFrozen: true, walletFrozenReason: 'REFERRAL_PAYMENT_REVERSED' } }, { session });
        await WalletEntry.create([{ user: owner._id, key: `referral-reversal:${referral.id}`, kind: 'REVERSAL', amountPaise: -reward.amountPaise }], { session });
      }
      await Referral.updateOne({ _id: referral._id }, { $set: { status: 'REVIEW' } }, { session });
    }
    return { reversedPaise: target, debtPaise: delta - debit };
  });
}
