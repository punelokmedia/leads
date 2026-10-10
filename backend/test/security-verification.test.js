import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';
import express from 'express';
import { MongoServerError } from 'mongodb';
import { User } from '../src/Models/user.model.js';
import { WalletEntry, WalletTopup } from '../src/Models/wallet.model.js';
import { SecurityAudit, ledgerSignature } from '../src/Services/security-audit.js';
import { SecurityBucket, sharedLimit } from '../src/Middlewares/security-limits.js';
import { Referral } from '../src/Models/referral.model.js';
import { Lead } from '../src/Models/leads.model.js';
import { LeadPurchase } from '../src/Models/lead.purchase.model.js';
import { Cart } from '../src/Models/cart.mode.js';
import { Order } from '../src/Models/orders.models.js';
import { creditCapturedTopup, walletTransaction } from '../src/Services/wallet.service.js';
import { purchaseWithWallet } from '../src/Services/checkout.service.js';
import { applyReferral, qualifyReferral } from '../src/Services/referral.service.js';

// This suite never connects to the configured Atlas database or payment network.
Object.assign(process.env, { NODE_ENV: 'production', JWT_SECRET: 'verification-jwt-only', RAZORPAY_KEY_ID: 'rzp_test_verification', RAZORPAY_KEY_SECRET: 'verification-gateway-only', RAZORPAY_WEBHOOK_SECRET: 'verification-webhook-only', RESEND_API_KEY: 're_test_only', WALLET_LEDGER_HMAC_KEY: 'verification-ledger-key-at-least-32-bytes', WALLET_REFERRAL_MIN_PURCHASE_PAISE: '5000' });
delete process.env.VERCEL;
let mongo, server, base, gateway;
let number = 0;
const vendor = name => User.create({ firstname: name, lastname: 'Test', email: `${name}${++number}@example.invalid` });
const token = user => jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
const balance = async user => (await User.findById(user.id).select('+walletBalancePaise')).walletBalancePaise;
const lead = price => Lead.create({ title: 'Synthetic project', description: 'Test only', category: new mongoose.Types.ObjectId(), createdBy: new mongoose.Types.ObjectId(), city: 'Pune', state: 'Maharashtra', price, expiresAt: new Date(Date.now() + 86400000) });
const call = async (path, user, body, options = {}) => {
  const response = await fetch(base + path, { method: body === undefined ? 'GET' : 'POST', headers: { 'Content-Type': 'application/json', ...(user ? { Authorization: `Bearer ${typeof user === 'string' ? user : token(user)}` } : {}), ...options.headers }, ...(body === undefined ? {} : { body: typeof body === 'string' ? body : JSON.stringify(body) }), ...options });
  const text = await response.text();
  let bodyResult; try { bodyResult = JSON.parse(text); } catch { bodyResult = { text }; }
  return { status: response.status, headers: response.headers, body: bodyResult };
};
async function fund(user, amount, suffix) {
  await WalletTopup.create({ user: user.id, amountPaise: amount, gatewayOrderId: 'order_' + suffix });
  const payment = { id: 'pay_' + suffix, order_id: 'order_' + suffix, amount, currency: 'INR', status: 'captured' };
  await creditCapturedTopup(payment, user.id);
  return payment;
}
async function reconcile(user) {
  const entries = await WalletEntry.find({ user: user.id }).select('+signature');
  assert.equal(entries.reduce((sum, entry) => sum + entry.amountPaise, 0), await balance(user));
  for (const entry of entries) {
    assert.equal(entry.signature, ledgerSignature(entry));
    assert.ok(await SecurityAudit.exists({ eventKey: 'ledger:' + entry.id }));
  }
}
before(async () => {
  User.schema.set('autoIndex', false); // Full declared user indexes are separately tested below.
  mongo = await MongoMemoryReplSet.create({ replSet: { count: 1 }, binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  assert.match(mongoose.connection.host, /127\.0\.0\.1|localhost/);
  await Promise.all([WalletEntry.init(), WalletTopup.init(), SecurityAudit.init(), SecurityBucket.init(), Referral.init(), Lead.init(), LeadPurchase.init(), Cart.init(), Order.init()]);
  const { razorpay } = await import('../src/Config/razorpay.config.js');
  gateway = razorpay;
  gateway.orders.create = async () => { throw new Error('Unexpected gateway network call blocked by verification suite'); };
  gateway.payments.fetch = async () => { throw new Error('Unexpected gateway network call blocked by verification suite'); };
  const { app } = await import('../src/app.js');
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}/api/v1`;
}, { timeout: 900000 });
after(async () => { if (server) await new Promise(resolve => server.close(resolve)); await mongoose.disconnect(); if (mongo) await mongo.stop(); });

test('VER-01 wallet rejects invalid topups and ignores foreign user/balance input', async () => {
  const a = await vendor('walletA'), b = await vendor('walletB');
  await fund(a, 50000, 'ver_balance');
  for (const amountPaise of [-100, 0, 1.5, '100', null, 1000001]) assert.equal((await call('/wallet/topup', a, { amountPaise })).status, 400);
  const res = await call('/wallet?userId=' + b.id, a);
  assert.equal(res.body.data.balancePaise, 50000);
  assert.equal((await call('/wallet', b)).body.data.balancePaise, 0);
  const profile = await call('/auth/mobile/complete-profile', a, { fullName: 'Synthetic Vendor', email: a.email, city: 'Pune', businessName: 'Test', workType: 'Interior', walletBalancePaise: 99999999, role: 'ADMIN', userId: b.id, registrationFeePaid: true });
  assert.equal(profile.status, 200);
  assert.equal(await balance(a), 50000);
  assert.equal((await User.findById(a.id)).role, 'USER');
  assert.equal((await User.findById(a.id)).registrationFeePaid, false);
  assert.equal(await balance(b), 0);
  assert.equal((await call('/wallet/balance', a, { amountPaise: 999999 })).status, 404);
  await reconcile(a);
});

test('VER-02 JWT validation, admin authorization and blocked-account access', async () => {
  const a = await vendor('auth');
  assert.equal((await call('/wallet')).status, 401);
  for (const bad of ['not-a-jwt', jwt.sign({ id: a.id }, 'wrong-key'), jwt.sign({ id: a.id }, process.env.JWT_SECRET, { expiresIn: -1 })]) assert.equal((await call('/wallet', bad)).status, 401);
  assert.equal((await call('/admin/users', a)).status, 403);
  await User.updateOne({ _id: a.id }, { $set: { isBlocked: true } });
  assert.equal((await call('/wallet', a)).status, 403);
});

test('VER-03 mobile OTP expires, is consumed after success and attempts are limited', async () => {
  const a = await vendor('otp');
  await User.updateOne({ _id: a.id }, { $set: { phoneNumber: '9876543201', loginOtp: '1234', loginOtpExpire: new Date(Date.now() - 1000) } });
  assert.equal((await call('/auth/mobile/verify-otp', null, { phoneNumber: '9876543201', otp: '1234' })).status, 400);
  await User.updateOne({ _id: a.id }, { $set: { loginOtpExpire: new Date(Date.now() + 60000) } });
  assert.equal((await call('/auth/mobile/verify-otp', null, { phoneNumber: '9876543201', otp: '1234' })).status, 200);
  assert.equal((await call('/auth/mobile/verify-otp', null, { phoneNumber: '9876543201', otp: '1234' })).status, 400);
  for (let i = 0; i < 2; i++) assert.equal((await call('/auth/mobile/verify-otp', null, { phoneNumber: '9876543201', otp: '9999' })).status, 400);
  assert.equal((await call('/auth/mobile/verify-otp', null, { phoneNumber: '9876543201', otp: '9999' })).status, 429);
});

test('VER-04 real app parser, CORS, prototype/operator and content-type probes', async () => {
  const a = await vendor('api');
  for (const body of ['{"email":{"$ne":null}}', '{"nested":{"__proto__":{"polluted":true}}}', '{bad']) assert.equal((await call('/auth/login', null, body)).status, 400);
  assert.equal({}.polluted, undefined);
  assert.equal((await call('/wallet?%24where=0', a)).status, 400);
  assert.equal((await call('/auth/login', null, { email: 'x'.repeat(270000) })).status, 413);
  assert.equal((await call('/auth/login', null, 'email=' + 'a'.repeat(34000), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } })).status, 413);
  const malformed = await call('/auth/login', null, 'plain text', { headers: { 'Content-Type': 'text/plain' } });
  assert.ok(malformed.status >= 400);
  assert.doesNotMatch(JSON.stringify(malformed.body), /TypeError|node_modules|stack/);
  assert.equal((await call('/wallet', a, undefined, { headers: { Origin: 'https://attacker.invalid' } })).status, 403);
  const wallet = await call('/wallet', a);
  assert.equal(wallet.headers.get('x-powered-by'), null);
  assert.equal(wallet.headers.get('x-content-type-options'), 'nosniff');
});

test('VER-05 forwarded IP spoofing cannot reset a shared IP limiter', async () => {
  const { app } = await import('../src/app.js');
  assert.equal(app.get('trust proxy'), false);
  const harness = express(); harness.set('trust proxy', app.get('trust proxy'));
  harness.get('/', sharedLimit('verified-proxy', 2, 60000, req => req.ip), (_req, res) => res.json({ success: true }));
  const s = harness.listen(0, '127.0.0.1'); await new Promise(resolve => s.once('listening', resolve));
  try {
    const statuses = [];
    for (const ip of ['1.1.1.1', '2.2.2.2', '3.3.3.3']) statuses.push((await fetch(`http://127.0.0.1:${s.address().port}/`, { headers: { 'X-Forwarded-For': ip } })).status);
    assert.deepEqual(statuses, [200, 200, 429]);
  } finally { await new Promise(resolve => s.close(resolve)); }
});

test('VER-06 20 captured webhook duplicates credit exactly once and reconcile', async () => {
  const a = await vendor('webhooks');
  await WalletTopup.create({ user: a.id, amountPaise: 50000, gatewayOrderId: 'order_ver_webhook' });
  const payment = { id: 'pay_ver_webhook', order_id: 'order_ver_webhook', amount: 50000, currency: 'INR', status: 'captured' };
  gateway.payments.fetch = async id => { assert.equal(id, payment.id); return payment; };
  const body = JSON.stringify({ event: 'payment.captured', payload: { payment: { entity: payment } } });
  const signature = crypto.createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET).update(body).digest('hex');
  const forged = await call('/payments/razorpay-webhook', null, body, { headers: { 'Content-Type': 'application/json', 'x-razorpay-signature': '0'.repeat(64) } });
  assert.equal(forged.status, 400); assert.equal(await balance(a), 0);
  const results = await Promise.all(Array.from({ length: 20 }, () => call('/payments/razorpay-webhook', null, body, { headers: { 'Content-Type': 'application/json', 'x-razorpay-signature': signature } })));
  assert.ok(results.every(r => r.status === 200));
  assert.equal(await balance(a), 50000); assert.equal(await WalletEntry.countDocuments({ user: a.id }), 1);
  await reconcile(a);
});

test('VER-07 callback rejects failed/mismatched/wrong-order/foreign payments before credit', async () => {
  const a = await vendor('callbacks'), b = await vendor('callbackOther');
  await WalletTopup.create({ user: a.id, amountPaise: 10000, gatewayOrderId: 'order_ver_callback' });
  const payment = { id: 'pay_ver_callback', order_id: 'order_ver_callback', amount: 10000, currency: 'INR', status: 'captured' };
  const body = { razorpayOrderId: payment.order_id, razorpayPaymentId: payment.id, razorpaySignature: crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET).update(payment.order_id + '|' + payment.id).digest('hex') };
  assert.equal((await call('/wallet/verify', a, { ...body, razorpaySignature: '0'.repeat(64), status: 'captured' })).status, 400);
  assert.equal((await call('/wallet/verify', b, body)).status, 404);
  for (const patch of [{ status: 'failed' }, { amount: 9999 }, { currency: 'USD' }, { order_id: 'wrong_order' }]) {
    gateway.payments.fetch = async () => ({ ...payment, ...patch });
    assert.ok((await call('/wallet/verify', a, body)).status >= 400);
    assert.equal(await balance(a), 0);
  }
  gateway.payments.fetch = async () => payment;
  assert.equal((await call('/wallet/verify', a, body)).status, 200);
  assert.equal((await call('/wallet/verify', a, body)).status, 200);
  assert.equal(await balance(a), 10000); await reconcile(a);
});

test('VER-08 20 competing debits never overspend; client price is ignored', async () => {
  const a = await vendor('debits'); await fund(a, 50000, 'ver_debits');
  await User.updateOne({ _id: a.id }, { $set: { registrationFeePaid: true } });
  const leads = await Promise.all(Array.from({ length: 20 }, () => lead(100)));
  await Cart.create({ user: a.id, leads: leads.map(item => ({ lead: item.id, quantity: 1 })) });
  const outcomes = await Promise.all(leads.map(item => call('/wallet/purchase', a, { leadIds: [item.id], price: 0.01, amountPaise: 1, totalAmount: 0 })));
  assert.equal(outcomes.filter(item => item.status === 200).length, 5);
  assert.equal(await balance(a), 0);
  assert.equal(await LeadPurchase.countDocuments({ user: a.id }), 5);
  assert.equal(await WalletEntry.countDocuments({ user: a.id, kind: 'LEAD' }), 5);
  await reconcile(a);
});

test('VER-09 20 qualified referral retries reward once; self/invalid/prequalification rejected', async () => {
  const owner = await vendor('rewardOwner'), buyer = await vendor('rewardBuyer');
  await assert.rejects(applyReferral(owner.id, owner.referralCode));
  await assert.rejects(applyReferral(buyer.id, 'INVALID'));
  await applyReferral(buyer.id, owner.referralCode);
  assert.equal(await balance(owner), 0);
  await fund(buyer, 5000, 'ver_reward');
  const order = await Order.create({ user: buyer.id, leads: [], totalAmount: 50, status: 'PAID' });
  await Promise.all(Array.from({ length: 20 }, () => walletTransaction(session => qualifyReferral(buyer.id, order.id, session))));
  assert.equal(await balance(owner), 5000);
  assert.equal(await WalletEntry.countDocuments({ user: owner.id, kind: 'REFERRAL' }), 1);
  assert.equal((await Referral.findOne({ referredUser: buyer.id })).referrer.toString(), owner.id);
  await reconcile(owner);
});

test('VER-10 20 buyers cannot exceed the two-vendor inventory limit', async () => {
  const item = await lead(1);
  const users = await Promise.all(Array.from({ length: 20 }, (_, i) => vendor('sharing' + i)));
  for (const [i, user] of users.entries()) { await fund(user, 100, 'sharing_' + i); await User.updateOne({ _id: user.id }, { $set: { registrationFeePaid: true } }); await Cart.create({ user: user.id, leads: [{ lead: item.id, quantity: 1 }] }); }
  const outcomes = await Promise.allSettled(users.map(user => purchaseWithWallet(user.id, [item.id])));
  assert.equal(outcomes.filter(r => r.status === 'fulfilled').length, 2);
  assert.equal((await Lead.findById(item.id)).buyersCount, 2);
  assert.equal(await LeadPurchase.countDocuments({ lead: item.id }), 2);
  for (const user of users) await reconcile(user);
});

test('VER-11 failure after wallet debit rolls back access/ledger/audit and permits retry', async t => {
  const a = await vendor('rollback'); await fund(a, 10000, 'ver_rollback');
  await User.updateOne({ _id: a.id }, { $set: { registrationFeePaid: true } });
  const item = await lead(100);
  await Cart.create({ user: a.id, leads: [{ lead: item.id, quantity: 1 }] });
  const stub = t.mock.method(LeadPurchase, 'create', async () => { throw new Error('Synthetic failure after debit'); });
  await assert.rejects(purchaseWithWallet(a.id, [item.id]), /Synthetic failure/);
  stub.mock.restore();
  assert.equal(await balance(a), 10000);
  assert.equal((await Lead.findById(item.id)).buyersCount, 0);
  assert.equal(await WalletEntry.countDocuments({ user: a.id, kind: 'LEAD' }), 0);
  assert.equal(await SecurityAudit.countDocuments({ subject: a.id, event: 'WALLET_LEAD' }), 0);
  assert.equal((await purchaseWithWallet(a.id, [item.id])).status, 'PAID');
  await reconcile(a);
});

test('VER-12 required financial unique indexes exist in disposable database', async () => {
  for (const [model, keys] of [[WalletEntry, ['key']], [WalletTopup, ['gatewayOrderId', 'paymentId']], [Referral, ['referredUser']], [SecurityAudit, ['eventKey']]]) {
    const indexes = await model.collection.indexes();
    for (const key of keys) assert.ok(indexes.some(index => index.unique && index.key[key] === 1), `${model.modelName}.${key} unique index absent`);
  }
  const indexes = await LeadPurchase.collection.indexes();
  assert.ok(indexes.some(index => index.unique && index.key.lead && index.key.user));
});

test('VER-13 declared User indexes can be created on supported MongoDB (security expectation)', async () => {
  // Does not drop/sync indexes. This intentionally exposes an invalid existing schema index.
  await User.createIndexes();
});

test('VER-14 logout invalidates a previously issued token (security expectation)', async () => {
  const a = await vendor('logout'); const issued = token(a);
  assert.equal((await call('/auth/logout', issued)).status, 200);
  const after = await call('/wallet', issued);
  assert.equal(after.status, 401, 'Logged-out JWT remains valid until expiration');
});

test('VER-15 concurrent use of one mobile OTP issues at most one session (security expectation)', async t => {
  const a = await vendor('otpRace');
  await User.updateOne({ _id: a.id }, { $set: { phoneNumber: '9876543202', loginOtp: '2468', loginOtpExpire: new Date(Date.now() + 60000) } });
  // Deterministic slow-read barrier: both legitimate concurrent requests read the
  // OTP before either saves. No authentication result or database value is faked.
  const original = User.findOne.bind(User);
  let reads = 0, release;
  const barrier = new Promise(resolve => { release = resolve; });
  t.mock.method(User, 'findOne', async filter => {
    const document = await original(filter);
    if (filter.phoneNumber === '9876543202') { if (++reads === 2) release(); await barrier; }
    return document;
  });
  const results = await Promise.all(Array.from({ length: 2 }, () => call('/auth/mobile/verify-otp', null, { phoneNumber: '9876543202', otp: '2468' })));
  assert.equal(results.filter(result => result.status === 200).length, 1, 'Concurrent OTP submissions both issued sessions');
});

test('VER-17 Google redirect does not put a bearer JWT in the URL (security expectation)', async () => {
  const { googleCallback } = await import('../src/Controllers/auth.controller.js');
  const a = await vendor('googleRedirect'); let location;
  await googleCallback({ user: a }, { redirect(_code, value) { location = value; } });
  const url = new URL(location);
  assert.equal(url.searchParams.has('token'), false, 'Google callback exposes bearer token in URL');
});

test('VER-18 unsupported login content-type returns a client error (security expectation)', async () => {
  const res = await call('/auth/login', null, 'plain text', { headers: { 'Content-Type': 'text/plain' } });
  assert.ok([400, 415].includes(res.status), `Unsupported Content-Type returned ${res.status}`);
});

test('VER-19 transient transaction failure retries without duplicate debit or allocation', async t => {
  const a = await vendor('timeoutRetry'); await fund(a, 10000, 'ver_timeout');
  await User.updateOne({ _id: a.id }, { $set: { registrationFeePaid: true } });
  const item = await lead(100); await Cart.create({ user: a.id, leads: [{ lead: item.id, quantity: 1 }] });
  const original = LeadPurchase.create.bind(LeadPurchase); let attempts = 0;
  t.mock.method(LeadPurchase, 'create', (...args) => {
    if (++attempts === 1) { const error = new MongoServerError({ message: 'Synthetic transient timeout', code: 112 }); error.addErrorLabel('TransientTransactionError'); throw error; }
    return original(...args);
  });
  assert.equal((await purchaseWithWallet(a.id, [item.id])).status, 'PAID');
  assert.ok(attempts >= 2); assert.equal(await balance(a), 0);
  assert.equal(await LeadPurchase.countDocuments({ user: a.id }), 1);
  assert.equal(await WalletEntry.countDocuments({ user: a.id, kind: 'LEAD' }), 1);
  await reconcile(a);
});

test('VER-20 successful admin role promotion creates an attributable audit record (security expectation)', async () => {
  const admin = await vendor('auditAdmin'), target = await vendor('auditTarget');
  await User.updateOne({ _id: admin.id }, { $set: { role: 'ADMIN' } });
  const before = await SecurityAudit.countDocuments();
  const credential = jwt.sign({ id: admin.id, mfa: true }, process.env.JWT_SECRET, { expiresIn: '1h' });
  assert.equal((await call('/admin/make-admin', credential, { userId: target.id })).status, 200);
  assert.equal((await User.findById(target.id)).role, 'ADMIN');
  assert.ok(await SecurityAudit.countDocuments() > before, 'Admin promotion committed without a persisted security audit event');
});

test('FIX-13 phone readiness detects duplicates; empty phones excluded and real phones unique', async () => {
  const { inspectPhoneIndexReadiness } = await import('../src/Services/user-index-readiness.js');
  assert.equal((await inspectPhoneIndexReadiness()).duplicateGroups, 0);
  const probe = mongoose.connection.collection('synthetic_phone_index_probe');
  await probe.insertMany([{ phoneNumber: '9876543299' }, { phoneNumber: '9876543299' }, { phoneNumber: '' }, { phoneNumber: '' }]);
  assert.deepEqual(await inspectPhoneIndexReadiness(probe), { duplicateGroups: 1, duplicateDocuments: 2, emptyPhones: 2 });
  await assert.rejects(probe.createIndex({ phoneNumber: 1 }, { unique: true, partialFilterExpression: { phoneNumber: { $type: 'string', $gt: '' } } }), { code: 11000 });
  const a = await vendor('emptyPhoneA'), b = await vendor('emptyPhoneB');
  a.phoneNumber = ' '; b.phoneNumber = ''; await a.save(); await b.save();
  assert.equal((await User.findById(a.id)).phoneNumber, undefined);
  a.phoneNumber = '9876543298'; await a.save(); b.phoneNumber = a.phoneNumber;
  await assert.rejects(b.save(), { code: 11000 });
});

test('FIX-14 revoked legacy token stays rejected while fresh password login works', async () => {
  const { hashPassword } = await import('../src/Utils/hash.js');
  const a = await vendor('freshLogin');
  await User.updateOne({ _id: a.id }, { $set: { password: await hashPassword('synthetic-password') } });
  const legacy = token(a);
  assert.equal((await call('/auth/logout', legacy)).status, 200);
  assert.equal((await call('/wallet', legacy)).status, 401);
  const login = await call('/auth/login', null, { email: a.email, password: 'synthetic-password' });
  assert.equal(login.status, 200);
  assert.equal(jwt.verify(login.body.token, process.env.JWT_SECRET).sv, 1);
  assert.equal((await call('/wallet', login.body.token)).status, 200);
});

test('FIX-17 PKCE handoff exposes no bearer, rejects wrong verifier, consumes once and expires', async () => {
  const { OAuthHandoff } = await import('../src/Models/oauth-handoff.model.js');
  await OAuthHandoff.init();
  const { googleCallback } = await import('../src/Controllers/auth.controller.js');
  const a = await vendor('handoff');
  const verifier = crypto.randomBytes(32).toString('hex');
  const challenge = crypto.createHash('sha256').update(verifier).digest('base64url');
  let location;
  await googleCallback({ user: a, query: { state: challenge } }, { redirect(_code, value) { location = value; } });
  const url = new URL(location);
  assert.equal(url.searchParams.has('token'), false); assert.equal(url.searchParams.has('user'), false);
  const code = new URLSearchParams(url.hash.slice(1)).get('oauth_code');
  assert.match(code, /^[a-f0-9]{64}$/);
  assert.equal((await call('/auth/google/exchange', null, { code, verifier: '0'.repeat(64) })).status, 401);
  const outcomes = await Promise.all(Array.from({ length: 2 }, () => call('/auth/google/exchange', null, { code, verifier })));
  assert.deepEqual(outcomes.map(result => result.status).sort(), [200, 401]);
  const success = outcomes.find(result => result.status === 200);
  assert.equal((await call('/wallet', success.body.token)).status, 200);
  const expired = crypto.randomBytes(32).toString('hex');
  await OAuthHandoff.create({ codeHash: crypto.createHash('sha256').update(expired).digest('hex'), user: a.id, sessionVersion: 0, challenge, expiresAt: new Date(Date.now() - 1000) });
  assert.equal((await call('/auth/google/exchange', null, { code: expired, verifier })).status, 401);
});

test('FIX-18 malformed login bodies return 400', async () => {
  for (const body of [[], { email: {}, password: 'x' }, { email: 'x', password: [] }]) assert.equal((await call('/auth/login', null, body)).status, 400);
});

test('FIX-20 audit failure rolls back promotion; success records actor, target and roles', async t => {
  const admin = await vendor('atomicAdmin'), target = await vendor('atomicTarget');
  await User.updateOne({ _id: admin.id }, { $set: { role: 'ADMIN' } });
  const credential = jwt.sign({ id: admin.id, mfa: true }, process.env.JWT_SECRET);
  const mock = t.mock.method(SecurityAudit, 'create', async () => { throw new Error('Synthetic audit failure'); });
  assert.equal((await call('/admin/make-admin', credential, { userId: target.id })).status, 503);
  mock.mock.restore();
  assert.equal((await User.findById(target.id)).role, 'USER');
  assert.equal((await call('/admin/make-admin', credential, { userId: target.id })).status, 200);
  const audit = await SecurityAudit.findOne({ subject: target.id, event: 'ADMIN_ROLE_PROMOTED' });
  assert.equal(audit.detail.actor, admin.id); assert.equal(audit.detail.target, target.id);
  assert.equal(audit.detail.oldRole, 'USER'); assert.equal(audit.detail.newRole, 'ADMIN');
  assert.equal(audit.detail.action, 'ADMIN_ROLE_PROMOTED'); assert.ok(audit.detail.timestamp);
});

test('FIX-15 authenticated phone verification also consumes an OTP once', async () => {
  const a = await vendor('sessionOtp');
  await User.updateOne({ _id: a.id }, { $set: { pendingPhoneNumber: '9876543297', loginOtp: '1357', loginOtpExpire: new Date(Date.now() + 60000) } });
  const responses = await Promise.all(Array.from({ length: 2 }, () => call('/auth/mobile/verify-otp-session', a, { phoneNumber: '9876543297', otp: '1357' })));
  assert.equal(responses.filter(result => result.status === 200).length, 1);
  assert.equal((await User.findById(a.id)).phoneNumber, '9876543297');
});

test('VER-16 login account attempts limited and production admin requires MFA claim', async () => {
  const a = await vendor('adminMfa');
  for (let i = 0; i < 5; i++) assert.equal((await call('/auth/login', null, { email: 'missing-verification@example.invalid', password: 'wrong' })).status, 404);
  assert.equal((await call('/auth/login', null, { email: 'missing-verification@example.invalid', password: 'wrong' })).status, 429);
  await User.updateOne({ _id: a.id }, { $set: { role: 'ADMIN' } });
  assert.equal((await call('/admin/users', token(a))).status, 403);
});
