import { walletLimit } from '../Middlewares/security-limits.js';
import { CheckoutError } from '../Services/lead-inventory.js';
import express from 'express';
import mongoose from 'mongoose';
import { auth, checkAccountType } from '../Middlewares/auth.middleware.js';
import { User } from '../Models/user.model.js';
import { WalletEntry, WalletTopup } from '../Models/wallet.model.js';
import { razorpay } from '../Config/razorpay.config.js';
import { validSignature } from '../Controllers/orders/payment.controller.js';
import { creditCapturedTopup, purchaseMembership } from '../Services/wallet.service.js';
import { purchaseWithWallet } from '../Services/checkout.service.js';
import { assertWalletLedgerConfigured } from '../Services/security-audit.js';

const router = express.Router();
router.use(auth, checkAccountType('USER'));
router.use((req, res, next) => req.method === 'POST' ? walletLimit(req, res, next) : next());
const handle = work => async (req, res) => {
  try { res.json({ success: true, data: await work(req) }); }
  catch (error) {
    // Keep unexpected failures diagnosable in hosting logs without logging
    // request bodies, authorization headers, or payment signatures.
    if (!error.status || error.status >= 500) console.error('Wallet request failed', {
      method: req.method, path: req.path,
      requestId: req.headers['x-vercel-id'],
      error: { name: error.name, code: error.code, message: error.message, stack: error.stack },
    });
    res.status(error.status || 503).json({ success: false, code: error.code, message: error.status ? error.message : 'Wallet unavailable. Please retry.' });
  }
};
router.get('/', handle(async req => {
  const user = await User.findById(req.user.id).select('+walletBalancePaise +referralCreditPaise');
  const entries = await WalletEntry.find({ user: req.user.id }).sort({ _id: -1 }).limit(51).lean();
  const hasMore = entries.length > 50;
  return { balancePaise: user.walletBalancePaise, referralCreditPaise: user.referralCreditPaise, frozen: user.walletFrozen, entries: entries.slice(0, 50), nextCursor: hasMore ? String(entries[49]._id) : null };
}));
router.get('/history', handle(async req => {
  const cursor = req.query.cursor;
  if (cursor !== undefined && (typeof cursor !== 'string' || !/^[a-f0-9]{24}$/i.test(cursor))) throw Object.assign(new Error('Invalid history cursor.'), { status: 400 });
  const entries = await WalletEntry.find({ user: req.user.id, ...(cursor ? { _id: { $lt: new mongoose.Types.ObjectId(cursor) } } : {}) }).sort({ _id: -1 }).limit(51).lean();
  return { entries: entries.slice(0, 50), nextCursor: entries.length > 50 ? String(entries[49]._id) : null };
}));
router.post('/topup', handle(async req => {
  // Fail before taking payment when production cannot commit a signed credit.
  assertWalletLedgerConfigured();
  const account = await User.findById(req.user.id).select('walletFrozen');
  if (account?.walletFrozen) throw Object.assign(new Error('Wallet is under security review. Contact support.'), { status: 403, code: 'WALLET_FROZEN' });
  const amount = req.body?.amountPaise;
  if (!Number.isSafeInteger(amount) || amount < 100 || amount > 10000000) throw Object.assign(new Error('Enter an amount between ₹1 and ₹1,00,000 in whole paise.'), { status: 400 });
  const topup = await WalletTopup.create({ user: req.user.id, amountPaise: amount });
  const order = await razorpay.orders.create({ amount, currency: 'INR', receipt: topup.id, notes: { purpose: 'wallet_topup', userId: String(req.user.id) } });
  topup.gatewayOrderId = order.id;
  await topup.save();
  return { keyId: process.env.RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY, razorpayOrderId: order.id, amountPaise: amount };
}));
router.get('/topups/:id', handle(async req => {
  if (!/^[a-f\d]{24}$/i.test(req.params.id)) throw new CheckoutError('TOPUP_NOT_FOUND', 'Top-up not found.', 404);
  const topup = await WalletTopup.findOne({ _id: req.params.id, user: req.user.id }).lean();
  if (!topup) throw new CheckoutError('TOPUP_NOT_FOUND', 'Top-up not found.', 404);
  const user = await User.findById(req.user.id).select('+walletBalancePaise');
  return { topup: { _id: topup._id, status: topup.status, amountPaise: topup.amountPaise, paymentId: topup.paymentId, paidAt: topup.updatedAt, reversedPaise: topup.reversedPaise, disputed: topup.disputed }, balancePaise: user.walletBalancePaise };
}));
router.post('/verify', handle(async req => {
  const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body ?? {};
  if (typeof razorpayOrderId !== 'string' || typeof razorpayPaymentId !== 'string' || !validSignature(`${razorpayOrderId}|${razorpayPaymentId}`, razorpaySignature, process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_SECRET)) throw Object.assign(new Error('Invalid payment signature.'), { status: 400 });
  // Ownership is checked before fetching a payment from the gateway.
  if (!await WalletTopup.exists({ gatewayOrderId: razorpayOrderId, user: req.user.id })) throw Object.assign(new Error('Top-up not found.'), { status: 404 });
  return creditCapturedTopup(await razorpay.payments.fetch(razorpayPaymentId), req.user.id);
}));
router.post('/membership', handle(req => purchaseMembership(req.user.id)));
router.post('/purchase', handle(req => purchaseWithWallet(req.user.id, req.body?.leadIds, req.body?.expectedTotalPaise)));
export default router;
