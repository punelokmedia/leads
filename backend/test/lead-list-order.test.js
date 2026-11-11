import test from 'node:test';
import assert from 'node:assert/strict';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { MongoClient } from 'mongodb';
import { leadListOrder } from '../src/Utils/lead-list-order.js';

test('available leads precede unavailable leads across sorts and pagination', async () => {
  const mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  const client = new MongoClient(mongo.getUri());
  const now = new Date('2026-11-11T12:00:00Z');
  const future = new Date(now.getTime() + 60000);
  const past = new Date(now.getTime() - 60000);
  try {
    await client.connect();
    const leads = client.db().collection('leads');
    await leads.insertMany([
      { title: 'sold', buyersCount: 2, price: 1, createdAt: future, expiresAt: future },
      { title: 'expired', buyersCount: 0, price: 1000, createdAt: future, expiresAt: past },
      { title: 'reserved', buyersCount: 1, reservations: [{ expiresAt: future }], price: 2, createdAt: future, expiresAt: future },
      { title: 'available', buyersCount: 0, price: 100, createdAt: past, expiresAt: future },
      { title: 'released', buyersCount: 1, reservations: [{ expiresAt: past }], price: 50, createdAt: now, expiresAt: future },
    ]);
    for (const sort of ['latest', 'cheapest', 'expensive']) {
      const rows = await leads.aggregate(leadListOrder(sort, now)).toArray();
      assert.deepEqual(rows.slice(0, 2).map(row => row.title), sort === 'expensive' ? ['available', 'released'] : ['released', 'available']);
      assert.deepEqual(new Set(rows.slice(2).map(row => row.title)), new Set(['sold', 'expired', 'reserved']));
      const page = await leads.aggregate([...leadListOrder(sort, now), { $skip: 1 }, { $limit: 2 }]).toArray();
      assert.deepEqual(page.map(row => row.title), rows.slice(1, 3).map(row => row.title));
    }
  } finally { await client.close(); await mongo.stop(); }
});
