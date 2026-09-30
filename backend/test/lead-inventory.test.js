import { test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import { inventory, BUYER_LIMIT } from '../src/Services/lead-inventory.js';
import { Lead } from '../src/Models/leads.model.js';
import { Cart } from '../src/Models/cart.mode.js';

const now = new Date('2026-01-01T00:00:00Z');
const later = new Date(now.getTime() + 60000);
test('two paid buyers sell out even a legacy lead configured for three', () => {
  const result = inventory({ maxBuyers: 3, buyersCount: 2, expiresAt: later }, now);
  assert.equal(BUYER_LIMIT, 2);
  assert.equal(result.status, 'SOLD_OUT');
  assert.equal(result.maxBuyers, 2);
  assert.equal(result.remainingSlots, 0);
});
test('pending reservations consume slots but expired ones do not', () => {
  const lead = { buyersCount: 1, expiresAt: later, reservations: [{ expiresAt: later }] };
  assert.equal(inventory(lead, now).status, 'RESERVED');
  assert.equal(inventory(lead, now).remainingSlots, 0);
  lead.reservations[0].expiresAt = now;
  assert.equal(inventory(lead, now).status, 'ACTIVE');
  assert.equal(inventory(lead, now).remainingSlots, 1);
});
test('expired leads cannot expose availability and historic oversold counts are preserved', () => {
  assert.equal(inventory({ buyersCount: 0, expiresAt: now }, now).status, 'EXPIRED');
  assert.equal(inventory({ buyersCount: 0, expiresAt: now }, now).remainingSlots, 0);
  assert.equal(inventory({ buyersCount: 3, expiresAt: later }, now).remainingSlots, 0);
});
test('model always normalizes new/imported lead limits to two', async () => {
  const lead = new Lead({ title: 'Project', description: 'Work', category: new mongoose.Types.ObjectId(), createdBy: new mongoose.Types.ObjectId(), city: 'Delhi', state: 'Delhi', price: 100, expiresAt: later, maxBuyers: 30 });
  await lead.validate();
  assert.equal(lead.maxBuyers, 2);
});
test('cart schema rejects buying two quantities of one lead', async () => {
  const cart = new Cart({ user: new mongoose.Types.ObjectId(), leads: [{ lead: new mongoose.Types.ObjectId(), quantity: 2 }] });
  await assert.rejects(cart.validate(), /maximum allowed value/);
});
