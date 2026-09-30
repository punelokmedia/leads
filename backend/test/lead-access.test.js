import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { mock } from 'node:test';
import { Lead } from '../src/Models/leads.model.js';
import { Order } from '../src/Models/orders.models.js';
import { getAllLeads, getLeadDetailsById } from '../src/Controllers/Admin/leads.controller.js';
import { optionalAuth } from '../src/Middlewares/auth.middleware.js';

afterEach(() => mock.restoreAll());
const id = '507f1f77bcf86cd799439011';
function fixture(overrides = {}) {
  const fields = { _id: id, leadDisplayId: 'NL99439011', title: 'Project',
    buyersCount: 3, maxBuyers: 3, expiresAt: new Date('2099-01-01'),
    primaryPhone: '9876543210', email: 'client@example.com', customerName: 'Client',
    address: 'Private address', price: 275, ...overrides };
  return { ...fields, toObject: () => ({ ...fields }) };
}
function response() {
  return { statusCode: 200, body: null,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; } };
}

test('guest details hide contacts and calculate capacity from buyersCount', async () => {
  mock.method(Lead, 'findById', () => ({ populate: async () => fixture() }));
  mock.method(Order, 'exists', () => { throw new Error('Guest must not query ownership'); });
  const res = response();
  await getLeadDetailsById({ params: { id } }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.isPurchased, false);
  assert.equal(res.body.data.primaryPhone, null);
  assert.equal(res.body.data.address, null);
  assert.equal(res.body.data.status, 'SOLD_OUT');
});

test('only a paid order belonging to the current user unlocks contacts', async () => {
  mock.method(Lead, 'findById', () => ({ populate: async () => fixture() }));
  let owned = true;
  mock.method(Order, 'exists', async (query) => {
    assert.deepEqual(query, { user: 'vendor-1', status: 'PAID', 'leads.lead': id });
    return owned ? { _id: 'paid-order' } : null;
  });
  const req = { user: { id: 'vendor-1' }, params: { id } };
  let res = response();
  await getLeadDetailsById(req, res);
  assert.equal(res.body.data.isPurchased, true);
  assert.equal(res.body.data.primaryPhone, '9876543210');
  owned = false;
  res = response();
  await getLeadDetailsById(req, res);
  assert.equal(res.body.data.isPurchased, false);
  assert.equal(res.body.data.primaryPhone, null);
});

test('listing marks paid purchases but never includes client contacts', async () => {
  mock.method(Lead, 'countDocuments', async () => 1);
  const chain = { populate() { return this; }, sort() { return this; }, limit() { return this; }, skip: async () => [fixture()] };
  mock.method(Lead, 'find', () => chain);
  mock.method(Order, 'find', (query) => {
    assert.equal(query.user, 'vendor-1');
    assert.equal(query.status, 'PAID');
    return { select: () => ({ lean: async () => [{ leads: [{ lead: id }] }] }) };
  });
  const res = response();
  await getAllLeads({ user: { id: 'vendor-1' }, query: {} }, res);
  assert.equal(res.body.data[0].isPurchased, true);
  assert.equal(res.body.data[0].status, 'SOLD_OUT');
  assert.equal(res.body.data[0].primaryPhone, undefined);
  assert.equal(res.body.data[0].email, undefined);
});

test('optional authentication allows guests and rejects invalid supplied tokens', async () => {
  let called = false;
  await optionalAuth({ header: () => undefined }, response(), () => { called = true; });
  assert.equal(called, true);
  called = false;
  const res = response();
  await optionalAuth({ header: () => 'Bearer invalid' }, res, () => { called = true; });
  assert.equal(res.statusCode, 401);
  assert.equal(called, false);
});
