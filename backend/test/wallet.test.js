import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import { User } from '../src/Models/user.model.js';
import { WalletEntry, WalletTopup } from '../src/Models/wallet.model.js';
import { creditCapturedTopup, purchaseMembership, reverseTopup } from '../src/Services/wallet.service.js';
import { ledgerSignature, SecurityAudit } from '../src/Services/security-audit.js';
import { sharedLimit, SecurityBucket } from '../src/Middlewares/security-limits.js';
import { purchaseWithWallet } from '../src/Services/checkout.service.js';
import { qualifyReferral } from '../src/Services/referral.service.js';
import { Referral } from '../src/Models/referral.model.js';
import { Lead } from '../src/Models/leads.model.js';
import { Cart } from '../src/Models/cart.mode.js';
import { Order } from '../src/Models/orders.models.js';
import { LeadPurchase } from '../src/Models/lead.purchase.model.js';
import express from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';

let mongo;
process.env.WALLET_REFERRAL_MIN_PURCHASE_PAISE = '0';
process.env.WALLET_LEDGER_HMAC_KEY = 'test-only-ledger-key';
before(async () => {
  User.schema.set('autoIndex', false);
  mongo = await MongoMemoryReplSet.create({ replSet: { count: 1 }, binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  await Promise.all([WalletEntry.init(), WalletTopup.init(), Referral.init(), Lead.init(), Cart.init(), Order.init(), LeadPurchase.init()]);
}, { timeout: 900000 });
after(async () => { await mongoose.disconnect(); if (mongo) await mongo.stop(); });
const user = name => User.create({ firstname: name, lastname: 'Test', email: name + '@example.invalid' });
const balance = async id => (await User.findById(id).select('+walletBalancePaise')).walletBalancePaise;

test('Add money API verifies payment then exposes updated balance and complete private paginated history', async t => {
  process.env.JWT_SECRET = 'wallet-test-jwt';
  process.env.RAZORPAY_KEY_ID = 'wallet-test-key';
  process.env.RAZORPAY_KEY_SECRET = 'wallet-test-secret';
  const { default: router } = await import('../src/Routes/wallet.routes.js');
  const { razorpay } = await import('../src/Config/razorpay.config.js');
  const buyer = await user('historybuyer');
  const outsider = await user('historyoutsider');
  t.mock.method(razorpay.orders, 'create', async order => {
    assert.equal(order.amount, 50000);
    assert.equal(order.currency, 'INR');
    return { id: 'order_history' };
  });
  t.mock.method(razorpay.payments, 'fetch', async id => {
    assert.equal(id, 'pay_history');
    return { id, order_id: 'order_history', amount: 50000, currency: 'INR', status: 'captured' };
  });
  const app = express();
  app.use(express.json());
  app.use('/wallet', router);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const call = async (path, account = buyer, body) => {
    const response = await fetch(`http://127.0.0.1:${server.address().port}/wallet${path}`, {
      method: body ? 'POST' : 'GET',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${jwt.sign({ id: account.id }, process.env.JWT_SECRET)}` },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    return { status: response.status, ...(await response.json()) };
  };
  try {
    const topup = await call('/topup', buyer, { amountPaise: 50000 });
    assert.equal(topup.data.razorpayOrderId, 'order_history');
    assert.equal((await call('')).data.balancePaise, 0);
    const body = { razorpayOrderId: 'order_history', razorpayPaymentId: 'pay_history', razorpaySignature: crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET).update('order_history|pay_history').digest('hex') };
    assert.equal((await call('/verify', outsider, body)).status, 404);
    assert.equal((await call('/verify', buyer, { ...body, razorpaySignature: '0'.repeat(64) })).status, 400);
    assert.equal((await call('/verify', buyer, body)).status, 200);
    assert.equal((await call('/verify', buyer, body)).status, 200);
    const wallet = (await call('')).data;
    assert.equal(wallet.balancePaise, 50000);
    assert.equal(wallet.entries.length, 1);
    assert.equal(wallet.entries[0].kind, 'TOPUP');
    assert.equal(wallet.entries[0].amountPaise, 50000);
    assert.ok(wallet.entries[0].createdAt);
    assert.equal((await call('', outsider)).data.entries.length, 0);
    // Existing older ledger rows must remain accessible beyond the first page.
    await WalletEntry.create(Array.from({ length: 55 }, (_, i) => ({ user: buyer.id, key: `history-fixture:${i}`, kind: 'LEAD', amountPaise: -1 })));
    const first = (await call('')).data;
    const second = (await call('/history?cursor=' + first.nextCursor)).data;
    assert.equal(first.entries.length, 50);
    assert.equal(second.entries.length, 6);
    assert.equal(second.nextCursor, null);
    assert.equal(new Set([...first.entries, ...second.entries].map(entry => entry._id)).size, 56);
    assert.equal((await call('/history?cursor=invalid')).status, 400);
    assert.equal((await call('/history?cursor=' + first.nextCursor, outsider)).data.entries.length, 0);
  } finally { await new Promise(resolve => server.close(resolve)); }
});

test('refund/dispute reversals are cumulative, idempotent and freeze spent funds as debt', async () => {
  const buyer = await user('reversalbuyer');
  await WalletTopup.create({ user: buyer.id, amountPaise: 10000, gatewayOrderId: 'order_reversal' });
  const payment = { id: 'pay_reversal', order_id: 'order_reversal', amount: 10000, currency: 'INR', status: 'captured' };
  await creditCapturedTopup(payment, buyer.id);
  await User.updateOne({ _id: buyer.id }, { $set: { walletBalancePaise: 2000 } });
  await Promise.all(Array.from({ length: 3 }, () => reverseTopup({ ...payment, amount_refunded: 5000 })));
  let account = await User.findById(buyer.id).select('+walletDebtPaise');
  assert.equal(await balance(buyer.id), 0);
  assert.equal(account.walletDebtPaise, 3000);
  assert.equal(account.walletFrozen, true);
  await assert.rejects(purchaseMembership(buyer.id), { code: 'WALLET_FROZEN' });
  await reverseTopup(payment, true);
  await reverseTopup({ ...payment, amount_refunded: 10000 });
  account = await User.findById(buyer.id).select('+walletDebtPaise');
  assert.equal(account.walletDebtPaise, 8000);
  assert.equal(await WalletEntry.countDocuments({ user: buyer.id, kind: 'REVERSAL' }), 2);
});

test('ledger signs content, prohibits mutation and records transactional audit', async () => {
  const buyer = await user('ledgerbuyer');
  const entry = await WalletEntry.create({ user: buyer.id, key: 'signed-test', kind: 'TOPUP', amountPaise: 100 });
  assert.equal(entry.signature, ledgerSignature(entry));
  entry.amountPaise = 200;
  assert.notEqual(entry.signature, ledgerSignature(entry));
  await assert.rejects(entry.save(), /append-only/);
  await assert.rejects(WalletEntry.updateOne({ _id: entry.id }, { $set: { amountPaise: 200 } }), /append-only/);
  await assert.rejects(WalletEntry.deleteOne({ _id: entry.id }), /append-only/);
  assert.ok(await SecurityAudit.exists({ eventKey: 'ledger:' + entry.id }));
});

test('shared limits enforce five attempts and isolate account identities', async () => {
  await SecurityBucket.init();
  const limiter = sharedLimit('limit-test', 5, 900000, req => req.account);
  let allowed = 0, denied = 0;
  const res = { set() {}, status(code) { assert.equal(code, 429); return this; }, json() { denied++; } };
  for (let i = 0; i < 7; i++) await limiter({ account: 'a' }, res, () => allowed++);
  await limiter({ account: 'b' }, res, () => allowed++);
  assert.equal(allowed, 6);
  assert.equal(denied, 2);
});

test('low-spend referrals enter review without granting a reward', async () => {
  const owner = await user('fraudowner'), buyer = await user('fraudbuyer');
  const referral = await Referral.create({ referrer: owner.id, referredUser: buyer.id, code: owner.referralCode });
  const order = await Order.create({ user: buyer.id, leads: [], totalAmount: 1, status: 'PAID' });
  process.env.WALLET_REFERRAL_MIN_PURCHASE_PAISE = '5000';
  const session = await mongoose.startSession();
  try { await session.withTransaction(() => qualifyReferral(buyer.id, order.id, session)); }
  finally { await session.endSession(); process.env.WALLET_REFERRAL_MIN_PURCHASE_PAISE = '0'; }
  assert.equal((await Referral.findById(referral.id)).status, 'REVIEW');
  assert.equal(await balance(owner.id), 0);
});

test('signed refund webhooks reject forgery and reverse credit once across retries', async t => {
  const { webhookHandler } = await import('../src/Controllers/orders/payment.controller.js');
  const { razorpay } = await import('../src/Config/razorpay.config.js');
  const buyer = await user('webhookbuyer');
  await WalletTopup.create({ user: buyer.id, amountPaise: 1000, gatewayOrderId: 'order_webhook' });
  const payment = { id: 'pay_webhook', order_id: 'order_webhook', amount: 1000, currency: 'INR', status: 'captured' };
  await creditCapturedTopup(payment, buyer.id);
  t.mock.method(razorpay.payments, 'fetch', async () => ({ ...payment, status: 'refunded', amount_refunded: 1000 }));
  process.env.RAZORPAY_WEBHOOK_SECRET = 'webhook-test-secret';
  const body = { event: 'refund.processed', payload: { refund: { entity: { payment_id: payment.id } } } };
  const rawBody = Buffer.from(JSON.stringify(body));
  const signature = crypto.createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET).update(rawBody).digest('hex');
  const response = () => ({ code: 200, status(code) { this.code = code; return this; }, json() { return this; } });
  const forged = response();
  await webhookHandler({ body, rawBody, headers: { 'x-razorpay-signature': '0'.repeat(64) } }, forged);
  assert.equal(forged.code, 400);
  assert.equal(await balance(buyer.id), 1000);
  for (let i = 0; i < 2; i++) {
    const res = response();
    await webhookHandler({ body, rawBody, headers: { 'x-razorpay-signature': signature } }, res);
    assert.equal(res.code, 200);
  }
  assert.equal(await balance(buyer.id), 0);
  assert.equal(await WalletEntry.countDocuments({ user: buyer.id, kind: 'REVERSAL' }), 1);
});

test('production admin OTP alone cannot issue a privileged session', async t => {
  process.env.RESEND_API_KEY = 're_test_only';
  const { verifyAdminOtp } = await import('../src/Controllers/Admin/admin.controller.js');
  const { hashPassword } = await import('../src/Utils/hash.js');
  const hash = await hashPassword('test-admin-password');
  t.mock.method(User, 'findOne', async () => ({ _id: new mongoose.Types.ObjectId(), role: 'ADMIN', email: 'admin@example.invalid', password: hash, resetOtp: '1234', resetOtpExpire: new Date(Date.now() + 60000), save: async () => {} }));
  const response = () => ({ code: 200, body: null, cookie() {}, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } });
  const previous = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';
  try {
    const rejected = response();
    await verifyAdminOtp({ body: { email: 'admin@example.invalid', otp: '1234' } }, rejected);
    assert.equal(rejected.code, 401);
    assert.equal(rejected.body.token, undefined);
    const accepted = response();
    await verifyAdminOtp({ body: { email: 'admin@example.invalid', otp: '1234', password: 'test-admin-password' } }, accepted);
    assert.equal(accepted.code, 200);
    assert.equal(jwt.verify(accepted.body.token, process.env.JWT_SECRET).mfa, true);
  } finally { if (previous === undefined) delete process.env.NODE_ENV; else process.env.NODE_ENV = previous; }
});

test('referral credits are revoked once when the referred payment is refunded', async () => {
  const owner = await user('revokeowner'), buyer = await user('revokebuyer');
  const referral = await Referral.create({ referrer: owner.id, referredUser: buyer.id, code: owner.referralCode });
  await WalletTopup.create({ user: buyer.id, amountPaise: 5000, gatewayOrderId: 'order_revoke' });
  const payment = { id: 'pay_revoke', order_id: 'order_revoke', amount: 5000, currency: 'INR', status: 'captured' };
  await creditCapturedTopup(payment, buyer.id);
  const session = await mongoose.startSession();
  try { await session.withTransaction(() => qualifyReferral(buyer.id, new mongoose.Types.ObjectId(), session)); }
  finally { await session.endSession(); }
  assert.equal(await balance(owner.id), 5000);
  await reverseTopup({ ...payment, amount_refunded: 5000 });
  await reverseTopup({ ...payment, amount_refunded: 5000 });
  assert.equal(await balance(owner.id), 0);
  assert.equal((await Referral.findById(referral.id)).status, 'REVIEW');
  assert.equal(await WalletEntry.countDocuments({ key: `referral-reversal:${referral.id}` }), 1);
});

test('captured top-ups require ownership, exact amount and currency, and credit once under concurrent retries', async () => {
  const buyer = await user('topup');
  await WalletTopup.create({ user: buyer.id, amountPaise: 10000, gatewayOrderId: 'order_topup' });
  const payment = { id: 'pay_topup', order_id: 'order_topup', amount: 10000, currency: 'INR', status: 'captured' };
  for (const patch of [{ amount: 10001 }, { currency: 'USD' }, { status: 'authorized' }, { amount_refunded: 1 }]) await assert.rejects(creditCapturedTopup({ ...payment, ...patch }, buyer.id));
  await assert.rejects(creditCapturedTopup(payment, new mongoose.Types.ObjectId()));
  assert.equal(await balance(buyer.id), 0);
  await Promise.all(Array.from({ length: 5 }, () => creditCapturedTopup(payment, buyer.id)));
  assert.equal(await balance(buyer.id), 10000);
  assert.equal(await WalletEntry.countDocuments({ user: buyer.id }), 1);
});

test('membership cannot overdraw and concurrent activation charges once', async () => {
  const buyer = await user('membership');
  await assert.rejects(purchaseMembership(buyer.id));
  await User.updateOne({ _id: buyer.id }, { $set: { walletBalancePaise: 100 } });
  await Promise.all(Array.from({ length: 4 }, () => purchaseMembership(buyer.id)));
  assert.equal(await balance(buyer.id), 0);
  assert.equal(await WalletEntry.countDocuments({ user: buyer.id, kind: 'MEMBERSHIP' }), 1);
});

test('referral rewards roll back, credit once, and cannot exceed the lifetime ₹100 cap', async () => {
  const owner = await user('referrer');
  for (let i = 0; i < 3; i++) {
    const buyer = await user('referred' + i);
    await Referral.create({ referrer: owner.id, referredUser: buyer.id, code: owner.referralCode });
    const session = await mongoose.startSession();
    try {
      await assert.rejects(session.withTransaction(async () => { await qualifyReferral(buyer.id, new mongoose.Types.ObjectId(), session); throw new Error('rollback'); }));
      await session.withTransaction(() => qualifyReferral(buyer.id, new mongoose.Types.ObjectId(), session));
      await session.withTransaction(() => qualifyReferral(buyer.id, new mongoose.Types.ObjectId(), session));
    } finally { await session.endSession(); }
  }
  assert.equal(await balance(owner.id), 10000);
  assert.equal(await WalletEntry.countDocuments({ user: owner.id, kind: 'REFERRAL' }), 2);
});

test('lead purchase uses server price and commits access with debit; insufficient funds roll back', async () => {
  const buyer = await user('leadbuyer');
  await User.updateOne({ _id: buyer.id }, { $set: { registrationFeePaid: true, walletBalancePaise: 5000 } });
  const lead = await Lead.create({ title: 'Project', description: 'Work', category: new mongoose.Types.ObjectId(), createdBy: new mongoose.Types.ObjectId(), city: 'Delhi', state: 'Delhi', price: 100, expiresAt: new Date(Date.now() + 86400000) });
  await Cart.create({ user: buyer.id, leads: [{ lead: lead.id, quantity: 1 }] });
  await assert.rejects(purchaseWithWallet(buyer.id, [lead.id]));
  assert.equal(await balance(buyer.id), 5000);
  assert.equal(await LeadPurchase.countDocuments({ user: buyer.id }), 0);
  await User.updateOne({ _id: buyer.id }, { $set: { walletBalancePaise: 10000 } });
  const result = await purchaseWithWallet(buyer.id, [lead.id]);
  assert.equal(result.status, 'PAID');
  assert.equal(await balance(buyer.id), 0);
  assert.equal(await LeadPurchase.countDocuments({ user: buyer.id }), 1);
  await assert.rejects(purchaseWithWallet(buyer.id, [lead.id]));
  assert.equal(await balance(buyer.id), 0);
});
