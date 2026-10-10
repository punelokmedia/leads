import { walletLimit } from '../Middlewares/security-limits.js';
import express from 'express';
import mongoose from 'mongoose';
import { auth, checkAccountType } from '../Middlewares/auth.middleware.js';
import { User } from '../Models/user.model.js';
import { WalletEntry, WalletTopup } from '../Models/wallet.model.js';
import { razorpay } from '../Config/razorpay.config.js';
import { validSignature } from '../Controllers/orders/payment.controller.js';
import { creditCapturedTopup, purchaseMembership } from '../Services/wallet.service.js';
import { purchaseWithWallet } from '../Services/checkout.service.js';

const router = express.Router();
router.use(auth, checkAccountType('USER'));
router.use((req, res, next) => req.method === 'POST' ? walletLimit(req, res, next) : next());
const handle = work => async (req, res) => {
  try { res.json({ success: true, data: await work(req) }); }
  catch (error) { res.status(error.status || 503).json({ success: false, code: error.code, message: error.status ? error.message : 'Wallet unavailable. Please retry.' }); }
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
  const account = await User.findById(req.user.id).select('walletFrozen');
  if (account?.walletFrozen) throw Object.assign(new Error('Wallet is under security review. Contact support.'), { status: 403, code: 'WALLET_FROZEN' });
  const amount = req.body?.amountPaise;
  if (!Number.isSafeInteger(amount) || amount < 100 || amount > 1000000) throw Object.assign(new Error('Enter an amount between ₹1 and ₹10,000 in whole paise.'), { status: 400 });
  const topup = await WalletTopup.create({ user: req.user.id, amountPaise: amount });
  const order = await razorpay.orders.create({ amount, currency: 'INR', receipt: topup.id, notes: { purpose: 'wallet_topup', userId: String(req.user.id) } });
  topup.gatewayOrderId = order.id;
  await topup.save();
  return { keyId: process.env.RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY, razorpayOrderId: order.id, amountPaise: amount };
}));
router.post('/verify', handle(async req => {
  const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body ?? {};
  if (typeof razorpayOrderId !== 'string' || typeof razorpayPaymentId !== 'string' || !validSignature(`${razorpayOrderId}|${razorpayPaymentId}`, razorpaySignature, process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_SECRET)) throw Object.assign(new Error('Invalid payment signature.'), { status: 400 });
  // Ownership is checked before fetching a payment from the gateway.
  if (!await WalletTopup.exists({ gatewayOrderId: razorpayOrderId, user: req.user.id })) throw Object.assign(new Error('Top-up not found.'), { status: 404 });
  return creditCapturedTopup(await razorpay.payments.fetch(razorpayPaymentId), req.user.id);
}));
router.post('/membership', handle(req => purchaseMembership(req.user.id)));
router.post('/purchase', handle(req => purchaseWithWallet(req.user.id, req.body?.leadIds)));
export default router;
