import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { supportRouter } from '../src/Routes/support.routes.js';
import { User } from '../src/Models/user.model.js';
import { SupportMessage } from '../src/Models/supportMessage.model.js';

let mongo, server, base, tokens, users;
before(async () => {
  process.env.JWT_SECRET = 'isolated-support-test-secret';
  // These route tests exercise the support indexes. Existing user-index
  // migrations are outside this fixture; authentication still uses real users.
  User.schema.set('autoIndex', false);
  mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  await SupportMessage.init();
  users = await User.create(['USER', 'USER', 'ADMIN'].map((role, i) => ({ firstname: 'Test', lastname: 'User', email: `support${i}@example.invalid`, role })));
  tokens = users.map(u => jwt.sign({ id: u.id }, process.env.JWT_SECRET));
  const app = express(); app.use(express.json()); app.use('/support', supportRouter);
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}/support`;
}, { timeout: 900000 });
after(async () => { if (server) await new Promise(resolve => server.close(resolve)); await mongoose.disconnect(); if (mongo) await mongo.stop(); });
async function call(path, user = 0, body) {
  const response = await fetch(base + path, { method: body ? 'POST' : 'GET', headers: { 'Content-Type': 'application/json', ...(user == null ? {} : { Authorization: `Bearer ${tokens[user]}` }) }, body: body ? JSON.stringify(body) : undefined });
  return { status: response.status, ...(await response.json()) };
}
test('support enforces authentication and message validation', async () => {
  assert.equal((await call('/messages', null)).status, 401);
  assert.equal((await call('/messages', 0, { text: ' ', clientId: 'empty' })).status, 400);
  assert.equal((await call('/messages', 0, { text: 'x'.repeat(2001), clientId: 'long' })).status, 400);
  assert.equal((await call('/admin/threads', 0)).status, 403);
});
test('concurrent retries save one message and cannot expose another user history', async () => {
  const responses = await Promise.all(Array.from({ length: 3 }, () => call('/messages', 0, { text: 'Payment question', clientId: 'same-request' })));
  assert.ok(responses.every(r => r.status === 200));
  assert.equal(new Set(responses.map(r => r.data._id)).size, 1);
  assert.equal((await call('/messages', 0)).data.length, 1);
  assert.equal((await call('/messages', 1)).data.length, 0);
  assert.equal((await call(`/admin/messages/${users[0].id}`, 1)).status, 403);
});
test('admin replies persist and are visible only to the conversation owner', async () => {
  const reply = await call(`/admin/messages/${users[0].id}`, 2, { text: 'Please provide your order ID', clientId: 'reply-one' });
  assert.equal(reply.status, 200);
  assert.equal(reply.data.sender, 'support');
  const history = await call('/messages', 0);
  assert.ok(history.data.some(m => m.text === reply.data.text));
  assert.equal((await call('/messages', 1)).data.length, 0);
  assert.ok((await call('/admin/threads', 2)).data.some(t => t._id === users[0].id));
});
