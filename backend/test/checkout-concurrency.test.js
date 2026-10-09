import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import { Lead } from '../src/Models/leads.model.js';
import { Order } from '../src/Models/orders.models.js';
import { Cart } from '../src/Models/cart.mode.js';
import { LeadPurchase } from '../src/Models/lead.purchase.model.js';
import { PaymentRefund } from '../src/Models/payment-refund.model.js';
import { reserveCheckout, cancelCheckout, settleCapturedPayment, processRefunds } from '../src/Services/checkout.service.js';
import { inventory } from '../src/Services/lead-inventory.js';

let server;
const oid = () => new mongoose.Types.ObjectId();
before(async () => {
  server = await MongoMemoryReplSet.create({ replSet: { count: 1 }, binary: { version: '7.0.24' } });
  await mongoose.connect(server.getUri());
  await Promise.all([Lead.init(), Order.init(), Cart.init(), LeadPurchase.init(), PaymentRefund.init()]);
}, { timeout: 300000 });
after(async () => { await mongoose.disconnect(); if (server) await server.stop(); });
beforeEach(async () => {
  await Promise.all([Lead.deleteMany({}), Order.deleteMany({}), Cart.deleteMany({}), LeadPurchase.deleteMany({}), PaymentRefund.deleteMany({})]);
});
async function fixture(buyers = 3) {
  const lead = await Lead.create({ title: 'Project', description: 'Project work', city: 'Delhi', state: 'Delhi', price: 275.5, category: oid(), createdBy: oid(), expiresAt: new Date(Date.now() + 86400000) });
  const users = Array.from({ length: buyers }, oid);
  await Cart.create(users.map((user) => ({ user, leads: [{ lead: lead._id, quantity: 1 }] })));
  return { lead, users };
}
async function gatewayOrder(reserved) {
  return Order.findByIdAndUpdate(reserved.order._id, { $set: { razorpayOrderId: `order_${reserved.order._id}`, status: 'CREATED' } }, { returnDocument: "after" });
}
function payment(order) {
  return { id: `pay_${order._id}`, order_id: order.razorpayOrderId, status: 'captured', currency: 'INR', amount: Math.round(order.totalAmount * 100) };
}

test('three simultaneous checkouts: exactly two reserve; third never gets an order', async () => {
  const { lead, users } = await fixture();
  const results = await Promise.allSettled(users.map((u) => reserveCheckout(u)));
  assert.equal(results.filter((r) => r.status === 'fulfilled').length, 2);
  assert.equal(results.filter((r) => r.status === 'rejected').length, 1);
  assert.equal(await Order.countDocuments(), 2);
  assert.equal((await Lead.findById(lead._id)).reservations.length, 2);
  assert.equal(inventory(await Lead.findById(lead._id)).status, 'RESERVED');
  const orders = await Promise.all(results.filter((r) => r.status === 'fulfilled').map((r) => gatewayOrder(r.value)));
  await Promise.all(orders.map((o) => settleCapturedPayment(payment(o), o.user)));
  assert.equal((await Lead.findById(lead._id)).buyersCount, 2);
  assert.equal(inventory(await Lead.findById(lead._id)).status, 'SOLD_OUT');
  assert.equal(await LeadPurchase.countDocuments(), 2);
  assert.equal(await Order.countDocuments({ status: 'PAID' }), 2);
});

test('duplicate callback/webhook deliveries allocate a purchase only once', async () => {
  const { lead, users } = await fixture(1);
  const order = await gatewayOrder(await reserveCheckout(users[0]));
  const results = await Promise.all(Array.from({ length: 6 }, () => settleCapturedPayment(payment(order), users[0])));
  assert.ok(results.every((r) => r.status === 'PAID'));
  assert.equal((await Lead.findById(lead._id)).buyersCount, 1);
  assert.equal(await LeadPurchase.countDocuments(), 1);
});

test('same buyer cannot reserve twice, buy twice or consume two slots', async () => {
  const { lead, users } = await fixture(1);
  const results = await Promise.allSettled([reserveCheckout(users[0]), reserveCheckout(users[0])]);
  assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
  const order = await gatewayOrder(results.find((r) => r.status === 'fulfilled').value);
  const reused = await reserveCheckout(users[0]);
  assert.equal(reused.reused, true);
  await settleCapturedPayment(payment(order), users[0]);
  await Cart.updateOne({ user: users[0] }, { $push: { leads: { lead: lead._id, quantity: 1 } } });
  await assert.rejects(reserveCheckout(users[0]), { code: 'ALREADY_PURCHASED' });
  await Cart.collection.updateOne({ user: users[0] }, { $set: { 'leads.0.quantity': 2 } });
  await assert.rejects(reserveCheckout(users[0]), { code: 'ONE_PER_BUYER' });
});

test('expired reservation frees a slot; late captured payment queues refund and grants nothing', async () => {
  const { lead, users } = await fixture();
  const first = await gatewayOrder(await reserveCheckout(users[0]));
  await gatewayOrder(await reserveCheckout(users[1]));
  await Order.updateOne({ _id: first._id }, { $set: { reservationExpiresAt: new Date(0) } });
  await Lead.updateOne({ _id: lead._id, 'reservations.order': first._id }, { $set: { 'reservations.$.expiresAt': new Date(0) } });
  await gatewayOrder(await reserveCheckout(users[2]));
  const result = await settleCapturedPayment(payment(first), first.user);
  assert.equal(result.status, 'REFUND_PENDING');
  assert.equal(await LeadPurchase.countDocuments({ user: first.user }), 0);
  assert.equal((await Lead.findById(lead._id)).buyersCount, 0);
  assert.equal(await PaymentRefund.countDocuments(), 1);
  await settleCapturedPayment(payment(first), first.user);
  assert.equal(await PaymentRefund.countDocuments(), 1);
});

test('cancellation releases only its own slots, even when repeated', async () => {
  const { lead, users } = await fixture();
  const first = await gatewayOrder(await reserveCheckout(users[0]));
  await gatewayOrder(await reserveCheckout(users[1]));
  await cancelCheckout(first._id, users[2]);
  assert.equal((await Lead.findById(lead._id)).reservations.length, 2);
  await cancelCheckout(first._id, users[0]);
  await cancelCheckout(first._id, users[0]);
  await reserveCheckout(users[2]);
  assert.equal((await Lead.findById(lead._id)).reservations.length, 2);
});

test('wrong owner, non-captured payments and amount mismatches never unlock contacts', async () => {
  const { users } = await fixture(2);
  const order = await gatewayOrder(await reserveCheckout(users[0]));
  await assert.rejects(settleCapturedPayment(payment(order), users[1]), { code: 'ORDER_NOT_FOUND' });
  await assert.rejects(settleCapturedPayment({ ...payment(order), status: 'authorized' }, users[0]), { code: 'PAYMENT_PENDING' });
  const result = await settleCapturedPayment({ ...payment(order), amount: 1 }, users[0]);
  assert.equal(result.status, 'REFUND_PENDING');
  assert.equal(await LeadPurchase.countDocuments(), 0);
});

test('multi-lead reservation rolls back entirely when any lead is sold out', async () => {
  const { lead, users } = await fixture(1);
  const other = await Lead.create({ title: 'Sold', description: 'Sold', city: 'Delhi', state: 'Delhi', price: 100, category: oid(), createdBy: oid(), expiresAt: new Date(Date.now() + 86400000), buyersCount: 2 });
  await Cart.updateOne({ user: users[0] }, { $push: { leads: { lead: other._id, quantity: 1 } } });
  await assert.rejects(reserveCheckout(users[0]), { code: 'SOLD_OUT' });
  assert.equal((await Lead.findById(lead._id)).reservations.length, 0);
  assert.equal(await Order.countDocuments(), 0);
});

test('legacy maxBuyers=3 records still stop at two and multi-line settlement never partially unlocks', async () => {
  const { lead, users } = await fixture(1);
  await Lead.collection.updateOne({ _id: lead._id }, { $set: { maxBuyers: 3, buyersCount: 2 } });
  await assert.rejects(reserveCheckout(users[0]), { code: 'SOLD_OUT' });
  await Lead.collection.updateOne({ _id: lead._id }, { $set: { buyersCount: 0 } });
  const other = await Lead.create({ title: 'Other', description: 'Other', city: 'Delhi', state: 'Delhi', price: 100, category: oid(), createdBy: oid(), expiresAt: new Date(Date.now() + 86400000) });
  await Cart.updateOne({ user: users[0] }, { $push: { leads: { lead: other._id, quantity: 1 } } });
  const order = await gatewayOrder(await reserveCheckout(users[0]));
  await Lead.updateOne({ _id: other._id }, { $set: { expiresAt: new Date(0) } });
  assert.equal((await settleCapturedPayment(payment(order))).status, 'REFUND_PENDING');
  assert.equal((await Lead.findById(lead._id)).buyersCount, 0);
  assert.equal(await LeadPurchase.countDocuments(), 0);
});

test('refund job retries safely after a lost gateway response', async () => {
  const { users } = await fixture(1);
  const order = await gatewayOrder(await reserveCheckout(users[0]));
  await cancelCheckout(order._id, users[0]);
  await settleCapturedPayment(payment(order));
  let calls = 0;
  let refunded = false;
  const gateway = { payments: {
    fetch: async () => ({ status: refunded ? 'refunded' : 'captured', amount_refunded: refunded ? 27550 : 0 }),
    refund: async () => { calls++; refunded = true; throw new Error('Connection lost after gateway accepted refund'); },
  } };
  await processRefunds(gateway);
  await PaymentRefund.updateMany({}, { $set: { nextAttemptAt: new Date(0) } });
  await processRefunds(gateway);
  assert.equal(calls, 1);
  assert.equal((await PaymentRefund.findOne()).status, 'REFUNDED');
  assert.equal((await Order.findById(order._id)).status, 'REFUNDED');
});
