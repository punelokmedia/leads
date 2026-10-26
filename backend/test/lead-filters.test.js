import test from 'node:test';
import assert from 'node:assert/strict';
import { applyLeadFilters } from '../src/Utils/lead-filters.js';

test('lead filters combine project, property, overlapping budgets and inclusive IST dates', () => {
  const query = { category: 'selected-category', city: /Bengaluru/i };
  applyLeadFilters(query, { projectTypes: 'New Installation,Repair & Maintenance', propertyTypes: 'Office', budgetMin: '1000', budgetMax: '50000', postedFrom: '2026-10-01', postedTo: '2026-10-26' });
  assert.equal(query.category, 'selected-category');
  assert.equal(query.requirement.$in[0].test('new installation'), true);
  assert.equal(query.requirement.$in[0].test('New Installation extra'), false);
  assert.equal(query.propertyType.$in[0].test('office'), true);
  assert.equal(query.$expr.$let.in.$and[2].$gte[1], 1000);
  assert.equal(query.$expr.$let.in.$and[3].$lte[1], 50000);
  assert.equal(query.createdAt.$gte.toISOString(), '2026-09-30T18:30:00.000Z');
  assert.equal(query.createdAt.$lt.toISOString(), '2026-10-26T18:30:00.000Z');
});
test('empty filters impose no constraints and filter options are regex escaped', () => {
  const query = {}; applyLeadFilters(query, {}); assert.deepEqual(query, {});
  applyLeadFilters(query, { projectTypes: 'Repair (AMC).*' });
  assert.equal(query.requirement.$in[0].test('Repair (AMC).*'), true);
  assert.equal(query.requirement.$in[0].test('Repair AMCxyz'), false);
});
test('lead filters reject invalid budgets, injected objects and invalid date ranges', () => {
  for (const filters of [{ budgetMin: '-1' }, { budgetMax: 'abc' }, { budgetMax: '' }, { budgetMin: '500', budgetMax: '100' }, { propertyTypes: { $ne: '' } }, { postedFrom: '2026-02-30' }, { postedFrom: '2026-13-01' }, { postedFrom: '2026-10-26', postedTo: '2026-10-01' }]) {
    assert.throws(() => applyLeadFilters({}, filters));
  }
});

test('budget filtering matches numeric budgets and legacy display ranges in MongoDB', async () => {
  const { MongoMemoryServer } = await import('mongodb-memory-server');
  const { MongoClient } = await import('mongodb');
  const mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  const client = new MongoClient(mongo.getUri());
  try {
    await client.connect();
    const leads = client.db().collection('leads');
    await leads.insertMany([
      { title: 'numeric', budget: { min: 18000, max: 36000 }, requirement: 'New Installation', propertyType: 'Office' },
      { title: 'rupees', budgetRange: '₹25,000 - ₹60,000', requirement: 'New Installation', propertyType: 'Office' },
      { title: 'thousands', budgetRange: '20k - 40k', requirement: 'Repair & Maintenance', propertyType: 'Residential' },
      { title: 'lakhs', budgetRange: '2 lakh - 3 lakh' },
      { title: 'unknown', budgetRange: 'Contact for budget' },
    ]);
    const query = {}; applyLeadFilters(query, { budgetMin: '10000', budgetMax: '50000' });
    assert.deepEqual((await leads.find(query).toArray()).map(item => item.title).sort(), ['numeric','rupees','thousands']);
    applyLeadFilters(query, { projectTypes: 'New Installation', propertyTypes: 'Office' });
    assert.equal(await leads.countDocuments(query), 2);
    assert.equal((await leads.find(query).limit(1).skip(1).toArray()).length, 1);
  } finally { await client.close(); await mongo.stop(); }
});

test('lead purchase price is separate from customer budget and capped at 5000', () => {
  const query = {}; applyLeadFilters(query, { priceMin: '0', priceMax: '5000' });
  assert.deepEqual(query.price, { $gte: 0, $lte: 5000 });
  assert.equal(query.$expr, undefined);
  for (const filters of [{ priceMax: '5001' }, { priceMin: '-1' }, { priceMin: '2000', priceMax: '1000' }, { priceMax: { $gt: 0 } }]) assert.throws(() => applyLeadFilters({}, filters));
});
