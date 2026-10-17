import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import express from 'express';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import { Cart } from '../src/Models/cart.mode.js';
import { Lead } from '../src/Models/leads.model.js';
import { User } from '../src/Models/user.model.js';
import { Order } from '../src/Models/orders.models.js';
import { LeadPurchase } from '../src/Models/lead.purchase.model.js';
import { WalletEntry } from '../src/Models/wallet.model.js';
import { SecurityAudit } from '../src/Services/security-audit.js';
import { Notification } from '../src/Models/notification.model.js';
import cartRouter from '../src/Routes/cart.routes.js';
import { purchaseWithWallet, reserveCheckout } from '../src/Services/checkout.service.js';
import jwt from 'jsonwebtoken';

Object.assign(process.env, { NODE_ENV: 'test', JWT_SECRET: 'cart-test-only', WALLET_LEDGER_HMAC_KEY: 'cart-test-ledger-only', DATABASE_URL: 'mongodb://127.0.0.1:1/cart-test-no-env', RESEND_API_KEY: 're_test_only', RAZORPAY_KEY_ID: 'synthetic-cart', RAZORPAY_KEY_SECRET: 'synthetic-cart' });
let mongo, server, base;
const oid = () => new mongoose.Types.ObjectId();
before(async () => {
  mongo = await MongoMemoryReplSet.create({ replSet: { count: 1 }, binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  assert.match(mongoose.connection.host, /^(127\.0\.0\.1|localhost)$/);
  await Promise.all([Cart, Lead, User, Order, LeadPurchase, WalletEntry, SecurityAudit, Notification].map(model => model.init()));
  const app = express();
  app.use(express.json());
  app.use('/cart', cartRouter);
  const { default: walletRouter } = await import('../src/Routes/wallet.routes.js');
  app.use('/wallet', walletRouter);
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
}, { timeout: 300000 });
after(async () => { if (server) await new Promise(resolve => server.close(resolve)); await mongoose.disconnect(); if (mongo) await mongo.stop(); });
beforeEach(async () => {
  // Delete only this suite's fresh loopback fixture collections, never configured data.
  await Promise.all([Cart, Lead, User, Order, LeadPurchase, SecurityAudit, Notification].map(model => model.deleteMany({})));
  await WalletEntry.collection.deleteMany({});
});
async function buyer() {
  return User.create({ firstname: 'Cart', lastname: 'Synthetic', email: `${oid()}@example.invalid`, registrationFeePaid: true, walletBalancePaise: 100000 });
}
async function lead(overrides = {}) {
  return Lead.create({ title: 'Synthetic lead', description: 'Fixture only', city: 'Pune', state: 'Maharashtra', price: 10, category: oid(), createdBy: oid(), expiresAt: new Date(Date.now() + 86400000), ...overrides });
}
async function putCart(user, leads) { return Cart.create({ user: user._id, leads: leads.map(value => ({ lead: value._id ?? value, quantity: 1 })) }); }
async function call(user, method = 'GET', endpoint = '/get-cart', body) {
  const response = await fetch(`${base}/cart${endpoint}`, { method, headers: { Authorization: `Bearer ${jwt.sign({ id: user._id, sv: 0 }, process.env.JWT_SECRET)}`, 'Content-Type': 'application/json' }, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
  return { status: response.status, ...(await response.json()) };
}
const ids = values => values.map(value => String(value._id ?? value));
const storedIds = async user => (await Cart.findOne({ user: user._id })).leads.map(item => String(item.lead));
const balance = async user => (await User.findById(user._id).select('+walletBalancePaise')).walletBalancePaise;

test('DATA-06 available cart, add duplicate, remove and clear remain consistent after refresh', async () => {
  const user = await buyer(), a = await lead(), b = await lead();
  for (const value of [a, a, b]) assert.equal((await call(user, 'POST', '/add-cart', { leadId: String(value._id) })).status, 200);
  const first = await call(user);
  assert.deepEqual(ids(first.data.leads), ids([a, b]));
  assert.deepEqual(await storedIds(user), ids([a, b]));
  assert.equal(first.data.totalAmount, 20);
  assert.deepEqual(first.data.removedLeads, []);
  await call(user, 'DELETE', '/delete-cart-item', { leadId: String(a._id) });
  assert.deepEqual(ids((await call(user)).data.leads), ids([b]));
  await call(user, 'DELETE', '/delete-cart');
  assert.deepEqual((await call(user)).data.leads, []);
});

for (const status of ['SOLD_OUT', 'EXPIRED', 'ALREADY_PURCHASED', 'RESERVED', 'MISSING', 'LEGACY_PURCHASED']) {
  test(`DATA-06 mixed cart prunes ${status}, reports reason and stays consistent on refresh`, async () => {
    const user = await buyer(), a = await lead(), unavailable = await lead();
    await putCart(user, [a, unavailable]);
    if (status === 'SOLD_OUT') await Lead.updateOne({ _id: unavailable._id }, { $set: { buyersCount: 2 } });
    if (status === 'EXPIRED') await Lead.updateOne({ _id: unavailable._id }, { $set: { expiresAt: new Date(0), reservations: [{ order: oid(), user: user._id, expiresAt: new Date(Date.now() + 60000) }] } });
    if (status === 'ALREADY_PURCHASED') await LeadPurchase.create({ lead: unavailable._id, user: user._id, quantity: 1, fulfillmentVersion: 2 });
    if (status === 'LEGACY_PURCHASED') await Order.create({ user: user._id, leads: [{ lead: unavailable._id, quantity: 1, price: 10 }], totalAmount: 10, status: 'PAID' });
    if (status === 'RESERVED') await Lead.updateOne({ _id: unavailable._id }, { $set: { reservations: [{ order: oid(), user: oid(), expiresAt: new Date(Date.now() + 60000) }, { order: oid(), user: oid(), expiresAt: new Date(Date.now() + 60000) }] } });
    if (status === 'MISSING') await Lead.deleteOne({ _id: unavailable._id });
    const view = await call(user);
    assert.equal(view.status, 200);
    assert.deepEqual(ids(view.data.leads), ids([a]));
    assert.deepEqual(await storedIds(user), ids([a]));
    assert.equal(view.data.removedLeads.length, 1);
    assert.equal(view.data.removedLeads[0].code, status === 'LEGACY_PURCHASED' ? 'ALREADY_PURCHASED' : status);
    assert.ok(view.data.removedLeads[0].reason);
    assert.deepEqual(ids((await call(user)).data.leads), ids([a]));
    const paid = await purchaseWithWallet(user._id, ids(view.data.leads), 1000);
    const order = await Order.findById(paid.orderId);
    assert.deepEqual(order.leads.map(item => String(item.lead)), ids([a]));
    assert.equal(await balance(user), 99000);
    assert.deepEqual((await call(user)).data.leads, []);
    if (status === 'ALREADY_PURCHASED') assert.equal(await LeadPurchase.countDocuments({ user: user._id, lead: unavailable._id }), 1);
    if (status === 'LEGACY_PURCHASED') assert.equal(await Order.countDocuments({ user: user._id, status: 'PAID' }), 2);
  });
}

test('DATA-06 all unavailable leads produce an empty saved cart and no debit', async () => {
  const user = await buyer(), sold = await lead({ buyersCount: 2 });
  await putCart(user, [sold]);
  const view = await call(user);
  assert.deepEqual(view.data.leads, []);
  assert.equal(view.data.removedLeads.length, 1);
  assert.deepEqual(await storedIds(user), []);
  await assert.rejects(purchaseWithWallet(user._id, ids([sold]), 1000));
  assert.equal(await balance(user), 100000);
  assert.equal(await WalletEntry.countDocuments(), 0);
});

test('DATA-06 stale confirmed selection is rejected entirely, never replaced by remaining/new cart entries', async () => {
  const user = await buyer(), a = await lead(), b = await lead(), addedElsewhere = await lead();
  await putCart(user, [a, b]);
  const confirmed = ids((await call(user)).data.leads);
  await Lead.updateOne({ _id: b._id }, { $set: { buyersCount: 2 } });
  await call(user); // Another tab refreshes and removes the now-unavailable item.
  await call(user, 'POST', '/add-cart', { leadId: String(addedElsewhere._id) });
  await assert.rejects(purchaseWithWallet(user._id, confirmed, 2000));
  assert.equal(await balance(user), 100000);
  assert.equal(await Order.countDocuments(), 0);
  assert.equal(await LeadPurchase.countDocuments(), 0);
  assert.equal(await WalletEntry.countDocuments(), 0);
  assert.deepEqual(await storedIds(user), ids([a, addedElsewhere]));
});

test('DATA-06 price is revalidated against the confirmed total without a wallet debit', async () => {
  const user = await buyer(), a = await lead();
  await putCart(user, [a]);
  await Lead.updateOne({ _id: a._id }, { $set: { price: 20 } });
  await assert.rejects(purchaseWithWallet(user._id, ids([a]), 1000), { code: 'PRICE_CHANGED' });
  assert.equal(await balance(user), 100000);
  assert.equal(await WalletEntry.countDocuments(), 0);
  assert.equal(await Order.countDocuments(), 0);
  assert.equal((await Lead.findById(a._id)).reservations.length, 0);
});

test('DATA-06 HTTP wallet checkout enforces the confirmed total and exact selection', async () => {
  const user = await buyer(), a = await lead({ price: 20 }), b = await lead();
  await putCart(user, [a, b]);
  const request = expectedTotalPaise => fetch(`${base}/wallet/purchase`, {
    method: 'POST', headers: { Authorization: `Bearer ${jwt.sign({ id: user._id, sv: 0 }, process.env.JWT_SECRET)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ leadIds: ids([a]), expectedTotalPaise }),
  });
  const stale = await request(1000);
  assert.equal(stale.status, 409);
  assert.equal((await stale.json()).code, 'PRICE_CHANGED');
  assert.equal(await balance(user), 100000);
  const paid = await request(2000);
  assert.equal(paid.status, 200);
  assert.equal((await paid.json()).data.status, 'PAID');
  assert.equal(await balance(user), 98000);
  assert.deepEqual(await storedIds(user), ids([b]));
});

test('DATA-06 exact confirmed subset purchased; other cart additions are preserved', async () => {
  const user = await buyer(), a = await lead(), b = await lead();
  await putCart(user, [a, b]);
  const result = await purchaseWithWallet(user._id, ids([a]), 1000);
  assert.deepEqual((await Order.findById(result.orderId)).leads.map(item => String(item.lead)), ids([a]));
  assert.deepEqual(await storedIds(user), ids([b]));
  assert.equal(await balance(user), 99000);
});

test('DATA-06 unavailable before checkout rolls back the whole selection and does not debit', async () => {
  const user = await buyer(), a = await lead(), b = await lead();
  await putCart(user, [a, b]);
  await Lead.updateOne({ _id: b._id }, { $set: { expiresAt: new Date(0) } });
  await assert.rejects(purchaseWithWallet(user._id, ids([a, b]), 2000), { code: 'EXPIRED' });
  assert.equal(await balance(user), 100000);
  assert.equal(await WalletEntry.countDocuments(), 0);
  assert.equal(await Order.countDocuments(), 0);
  assert.equal((await Lead.findById(a._id)).reservations.length, 0);
});

test('DATA-06 two buyers compete for last slot: one debit and one purchase', async () => {
  const users = await Promise.all([buyer(), buyer()]), a = await lead({ buyersCount: 1 });
  await Promise.all(users.map(user => putCart(user, [a])));
  const outcomes = await Promise.allSettled(users.map(user => purchaseWithWallet(user._id, ids([a]), 1000)));
  assert.equal(outcomes.filter(item => item.status === 'fulfilled').length, 1);
  assert.equal(outcomes.filter(item => item.status === 'rejected').length, 1);
  assert.equal((await Lead.findById(a._id)).buyersCount, 2);
  assert.equal(await LeadPurchase.countDocuments(), 1);
  assert.equal(await WalletEntry.countDocuments(), 1);
  assert.equal((await Promise.all(users.map(balance))).reduce((sum, value) => sum + value, 0), 199000);
});

test('DATA-06 duplicate wallet requests never debit or allocate twice', async () => {
  const user = await buyer(), a = await lead();
  await putCart(user, [a]);
  await Promise.allSettled([purchaseWithWallet(user._id, ids([a]), 1000), purchaseWithWallet(user._id, ids([a]), 1000)]);
  assert.equal(await balance(user), 99000);
  assert.equal(await WalletEntry.countDocuments(), 1);
  assert.equal(await LeadPurchase.countDocuments(), 1);
  assert.equal(await Order.countDocuments({ status: 'PAID' }), 1);
  assert.equal((await Lead.findById(a._id)).buyersCount, 1);
});

test('DATA-06 existing unexpired own reservation remains usable, but an expired lead cannot be added', async () => {
  const user = await buyer(), a = await lead();
  await putCart(user, [a]);
  const reserved = await reserveCheckout(user._id, ids([a]), true);
  assert.deepEqual(ids((await call(user)).data.leads), ids([a]));
  await Lead.updateOne({ _id: a._id }, { $set: { expiresAt: new Date(0) } });
  assert.equal((await call(user, 'POST', '/add-cart', { leadId: String(a._id) })).status, 409);
  assert.equal((await call(user)).data.removedLeads[0].code, 'EXPIRED');
  assert.equal((await Order.findById(reserved.order._id)).status, 'RESERVED');
});
