import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
process.env.RESEND_API_KEY = 're_audit_fake';
process.env.RAZORPAY_KEY_ID = 'audit_fake';
process.env.RAZORPAY_KEY_SECRET = 'audit_fake_secret';
process.env.WALLET_LEDGER_HMAC_KEY = 'audit-only-isolated-ledger-key-32-bytes';
delete process.env.SECURITY_AUDIT_URL;
const { User } = await import('../src/Models/user.model.js');
const { Lead } = await import('../src/Models/leads.model.js');
const { Category } = await import('../src/Models/category.model.js');
const { Cart } = await import('../src/Models/cart.mode.js');
const { Order } = await import('../src/Models/orders.models.js');
const { LeadPurchase } = await import('../src/Models/lead.purchase.model.js');
const { WalletEntry, WalletTopup } = await import('../src/Models/wallet.model.js');
const { Referral } = await import('../src/Models/referral.model.js');
const { SecurityAudit } = await import('../src/Services/security-audit.js');
const { purchaseWithWallet, reserveCheckout, settleCapturedPayment } = await import('../src/Services/checkout.service.js');
const { updateLead } = await import('../src/Controllers/Admin/leads.controller.js');
const { purchaseMembership } = await import('../src/Services/wallet.service.js');
const { qualifyReferral } = await import('../src/Services/referral.service.js');
const admin = await import('../src/Controllers/Admin/admin.controller.js');
let mongo;
const models = [User, Lead, Category, Cart, Order, LeadPurchase, WalletEntry, WalletTopup, Referral, SecurityAudit];
before(async () => {
  User.schema.set('autoIndex', false);
  mongo = await MongoMemoryReplSet.create({ replSet: { count: 1 }, binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  await Promise.all(models.filter(m => m !== User).map(m => m.init()));
});
after(async () => { await mongoose.disconnect(); if (mongo) await mongo.stop(); });
beforeEach(async () => { await Promise.all(models.map(m => m.collection.deleteMany({}))); });
const response = () => ({ statusCode: 200, status(n) { this.statusCode = n; return this; }, json(body) { this.body = body; return this; } });
async function fixture() {
  const users = await User.create([0,1,2].map(i => ({ firstname: 'Audit', lastname: 'Vendor', email: `audit${i}@example.invalid`, registrationFeePaid: true, walletBalancePaise: 10000 })));
  const category = await Category.create({ name: 'audit-category' });
  const lead = await Lead.create({ title: 'Audit lead', description: 'Isolated fixture', category: category.id, city: 'Delhi', state: 'Delhi', price: 50, createdBy: users[0].id, expiresAt: new Date(Date.now() + 86400000) });
  await Cart.create(users.map(u => ({ user: u.id, leads: [{ lead: lead.id, quantity: 1 }] })));
  return { users, lead, category };
}
test('three simultaneous WALLET purchases: two allocations/debits; loser balance unchanged', async () => {
  const {users, lead} = await fixture();
  const results = await Promise.allSettled(users.map(u => purchaseWithWallet(u.id, [lead.id], 5000)));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 2);
  assert.equal(await LeadPurchase.countDocuments(), 2);
  assert.equal((await Lead.findById(lead.id)).buyersCount, 2);
  assert.equal(await WalletEntry.countDocuments({kind: 'LEAD'}), 2);
  for (let i=0; i<3; i++) assert.equal((await User.findById(users[i].id).select('+walletBalancePaise')).walletBalancePaise, results[i].status === 'fulfilled' ? 5000 : 10000);
});
test('duplicate simultaneous wallet requests debit exactly once even when retry rejects', async () => {
  const {users, lead} = await fixture();
  await Promise.allSettled(Array.from({length: 5}, () => purchaseWithWallet(users[0].id, [lead.id], 5000)));
  assert.equal(await LeadPurchase.countDocuments(), 1);
  assert.equal(await WalletEntry.countDocuments({kind: 'LEAD'}), 1);
  assert.equal((await User.findById(users[0].id).select('+walletBalancePaise')).walletBalancePaise, 5000);
});
test('CONFIRMED BUG: admin lead detail returns 500 for an existing lead (missing import)', async () => {
  const {lead} = await fixture();
  const res = response(); await admin.getLeadByIdAdmin({params: {id: lead.id}}, res);
  assert.equal(res.statusCode, 500);
  assert.equal(res.body.message, 'Failed to fetch lead');
});
test('admin lead revenue matches paid order and debit; membership is excluded from revenue', async () => {
  const {users, lead} = await fixture();
  await purchaseWithWallet(users[0].id, [lead.id], 5000);
  let res = response(); await admin.getDashboardOverview({}, res);
  assert.equal(res.body.data.totalRevenue, 50);
  assert.equal((await WalletEntry.findOne({kind:'LEAD'})).amountPaise, -5000);
  await User.updateOne({_id:users[1].id}, {$set:{registrationFeePaid:false, walletBalancePaise:49900}});
  await purchaseMembership(users[1].id);
  res = response(); await admin.getDashboardOverview({}, res);
  assert.equal(res.body.data.totalRevenue, 50);
  assert.equal((await WalletEntry.findOne({kind:'MEMBERSHIP'})).amountPaise, -49900);
});
test('category fallback works for current-schema purchases; legacy buyers corrupt category result', async () => {
  const {users, lead, category} = await fixture();
  await purchaseWithWallet(users[0].id, [lead.id], 5000);
  let res = response(); await admin.getTopCategories({}, res);
  assert.equal(res.body.data[0].categoryName, category.name);
  assert.equal(res.body.data[0].totalSold, 1);
  await Lead.collection.updateOne({_id:lead._id}, {$set:{buyers:[users[0]._id]}});
  res = response(); await admin.getTopCategories({}, res);
  assert.equal(res.body.data[0].categoryName, 'Unknown');
  assert.equal(res.body.data[0].totalSold, undefined);
});
test('default referral eligibility credits exactly 5000 paise once after paid purchase', async () => {
  delete process.env.WALLET_REFERRAL_MIN_PURCHASE_PAISE;
  const {users, lead} = await fixture();
  await WalletTopup.create({user:users[0].id, amountPaise:5000, gatewayOrderId:'audit-isolated-topup',paymentId:'audit-isolated-payment',status:'PAID'});
  const referral = await Referral.create({referrer:users[1].id, referredUser:users[0].id, code:users[1].referralCode});
  const result = await purchaseWithWallet(users[0].id, [lead.id], 5000);
  const session = await mongoose.startSession();
  try { await session.withTransaction(() => qualifyReferral(users[0].id, result.orderId, session)); } finally { await session.endSession(); }
  const entries = await WalletEntry.find({key:'referral:'+referral.id});
  assert.equal(entries.length, 1); assert.equal(entries[0].amountPaise, 5000);
});
test('CONFIRMED BUG: partially refunded captured direct payment still allocates lead', async () => {
  const {users, lead} = await fixture();
  const {order} = await reserveCheckout(users[0].id, [lead.id]);
  await Order.updateOne({_id:order.id}, {$set:{razorpayOrderId:'audit-partial-refund',status:'CREATED'}});
  const result = await settleCapturedPayment({id:'audit-payment-partial',order_id:'audit-partial-refund',status:'captured',currency:'INR',amount:5000,amount_refunded:1000}, users[0].id);
  assert.equal(result.status, 'PAID');
  assert.equal(await LeadPurchase.countDocuments(), 1);
});
test('CONFIRMED BUG: lead edit accepts missing category, past expiry and inconsistent original price', async () => {
  const {lead} = await fixture();
  const res = response();
  await updateLead({params:{id:lead.id},body:{category:String(new mongoose.Types.ObjectId()),expiresAt:new Date(0).toISOString(),originalPrice:1}}, res);
  assert.equal(res.statusCode, 200);
  const saved = await Lead.findById(lead.id);
  assert.equal(saved.originalPrice, 1); assert.equal(saved.price, 50);
  assert.equal(saved.expiresAt.getTime(), 0);
  assert.equal(res.body.data.category, null);
});
