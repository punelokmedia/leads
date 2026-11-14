import test from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
process.env.RESEND_API_KEY = 're_test_only';
const { markLeadContacted, getLeadDetailsById } = await import('../src/Controllers/Admin/leads.controller.js');
const { LeadPurchase } = await import('../src/Models/lead.purchase.model.js');
const { Lead } = await import('../src/Models/leads.model.js');
const response = () => ({ statusCode: 200, headers: {}, set(key, value) { this.headers[key] = value; return this; }, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });

test('contact status persists idempotently per buyer and purchased contacts stay protected', async () => {
  const mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  try {
    await mongoose.connect(mongo.getUri());
    const a = new mongoose.Types.ObjectId(), b = new mongoose.Types.ObjectId(), outsider = new mongoose.Types.ObjectId();
    const lead = await Lead.create({ createdBy: new mongoose.Types.ObjectId(), title: 'House construction', description: 'Build house', category: new mongoose.Types.ObjectId(), city: 'Pune', state: 'Maharashtra', price: 99, expiresAt: new Date(Date.now() + 86400000), customerName: 'Private Client', primaryPhone: '9876543210', email: 'private@example.com' });
    await LeadPurchase.create([{ lead: lead.id, user: a, quantity: 1, fulfillmentVersion: 2 }, { lead: lead.id, user: b, quantity: 1, fulfillmentVersion: 2 }]);
    const request = user => ({ params: { id: lead.id }, user: user ? { id: user } : undefined, body: { contactedAt: '2000-01-01', user: b } });
    const first = response();
    await markLeadContacted(request(a), first);
    assert.equal(first.statusCode, 200);
    const timestamp = first.body.data.contactedAt;
    assert.ok(timestamp instanceof Date);
    assert.ok(timestamp.getFullYear() > 2000);
    await LeadPurchase.create({ lead: lead.id, user: a, quantity: 1 });
    const again = response();
    await markLeadContacted(request(a), again);
    assert.equal(again.body.data.contactedAt.toISOString(), timestamp.toISOString());
    assert.equal((await LeadPurchase.findOne({ lead: lead.id, user: a, fulfillmentVersion: { $exists: false } })).contactedAt, null);
    assert.equal((await LeadPurchase.findOne({ lead: lead.id, user: b })).contactedAt, null);
    const own = response();
    await getLeadDetailsById(request(a), own);
    assert.equal(own.body.data.customerName, 'Private Client');
    assert.equal(own.body.data.contactedAt.toISOString(), timestamp.toISOString());
    assert.equal(own.headers['Cache-Control'], 'no-store');
    for (const user of [outsider, undefined]) {
      const denied = response();
      await markLeadContacted(request(user), denied);
      assert.equal(denied.statusCode, user ? 403 : 401);
      const hidden = response();
      await getLeadDetailsById(request(user), hidden);
      assert.equal(hidden.body.data.isPurchased, false);
      assert.equal(hidden.body.data.primaryPhone, null);
      assert.equal(hidden.body.data.customerName, null);
      assert.equal(hidden.body.data.contactedAt, null);
    }
    await LeadPurchase.deleteMany({ lead: lead.id, user: a });
    const revoked = response();
    await markLeadContacted(request(a), revoked);
    assert.equal(revoked.statusCode, 403);
    const bad = response();
    await markLeadContacted({ user: { id: b }, params: { id: 'invalid' } }, bad);
    assert.equal(bad.statusCode, 400);
  } finally {
    await mongoose.disconnect();
    await mongo.stop();
  }
});
