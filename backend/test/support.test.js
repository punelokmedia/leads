import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { supportRouter } from '../src/Routes/support.routes.js';
import { User } from '../src/Models/user.model.js';
import { SupportMessage } from '../src/Models/supportMessage.model.js';
import { Notification } from '../src/Models/notification.model.js';
import { SupportTicket } from '../src/Models/supportTicket.model.js';

let mongo, server, base, tokens, users;
before(async () => {
  process.env.JWT_SECRET = 'isolated-support-test-secret';
  // These route tests exercise the support indexes. Existing user-index
  // migrations are outside this fixture; authentication still uses real users.
  User.schema.set('autoIndex', false);
  mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  await SupportMessage.init();
  await SupportTicket.init();
  await Notification.init();
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
  await call(`/admin/messages/${users[0].id}`, 2, { text: 'Please provide your order ID', clientId: 'reply-one' });
  assert.equal(await Notification.countDocuments({ user: users[0]._id, type: 'SUPPORT_REPLY' }), 1);
  assert.equal(await Notification.countDocuments({ user: users[1]._id }), 0);
  const history = await call('/messages', 0);
  assert.ok(history.data.some(m => m.text === reply.data.text));
  assert.equal((await call('/messages', 1)).data.length, 0);
  assert.ok((await call('/admin/threads', 2)).data.some(t => t._id === users[0].id));
});

test('inbox identifies customers and records which messages were read', async () => {
  const inbox = await call('/admin/threads', 2);
  const thread = inbox.data.find(row => row._id === users[0].id);
  assert.equal(thread.customerName, 'Test User');
  assert.equal(thread.unreadCount, 1);
  const history = await call(`/admin/messages/${users[0].id}`, 2);
  assert.ok(history.data.every(row => row.authorName === 'Test User'));
  const last = history.data.at(-1)._id;
  assert.equal((await call(`/admin/read/${users[0].id}`, 2, { through: last })).status, 200);
  assert.equal((await call('/admin/threads', 2)).data.find(row => row._id === users[0].id).unreadCount, 0);
  const reply = history.data.find(row => row.sender === 'support');
  assert.equal((await call('/read', 1, { through: reply._id })).status, 404);
  assert.equal((await call('/read', 0, { through: reply._id })).status, 200);
  assert.ok((await call('/messages', 0)).data.find(row => row._id === reply._id).readAt);
  assert.equal((await call(`/admin/read/${users[0].id}`, 1, { through: last })).status, 403);
});

test('read receipts reject malformed cursors and cannot mark newer messages', async () => {
  assert.equal((await call('/read', 0, { through: 'invalid' })).status, 400);
  const old = (await call('/messages', 0)).data.at(-1);
  const newer = await call(`/admin/messages/${users[0].id}`, 2, { text: 'Another reply', clientId: 'newer-reply' });
  await call('/read', 0, { through: old._id });
  assert.equal((await call('/messages', 0)).data.find(row => row._id === newer.data._id).readAt, null);
});

test('ticket creation is stored, pending, retry safe and owned by the customer', async () => {
  const body = { issue: 'PAYMENT', description: 'Payment deducted but order missing', clientId: 'ticket-one' };
  const results = await Promise.all([call('/tickets', 0, body), call('/tickets', 0, body)]);
  assert.ok(results.every(row => row.status === 200));
  assert.equal(results[0].data._id, results[1].data._id);
  assert.match(results[0].data.ticketId, /^NL-[A-F0-9]{24}$/);
  assert.equal(results[0].data.status, 'PENDING');
  assert.equal(await SupportTicket.countDocuments({ user: users[0]._id }), 1);
  assert.equal((await call('/tickets', 1)).data.length, 0);
  assert.equal((await call(`/tickets/${results[0].data._id}`, 1)).status, 404);
  assert.equal((await call('/tickets', 0, { ...body, description: 'Different issue' })).status, 409);
});
test('admin sees tickets and updates all statuses with an audit history', async () => {
  const ticket = (await call('/admin/tickets', 2)).data[0];
  assert.equal(ticket.user.firstname, 'Test');
  assert.equal((await call('/admin/tickets', 0)).status, 403);
  assert.equal((await call(`/admin/tickets/${ticket._id}/status`, 0, { status: 'COMPLETED', expectedStatus: 'PENDING' })).status, 403);
  const action = await call(`/admin/tickets/${ticket._id}/status`, 2, { status: 'ACTION_TAKEN', expectedStatus: 'PENDING' });
  assert.equal(action.data.status, 'ACTION_TAKEN');
  assert.equal((await call(`/admin/tickets/${ticket._id}/status`, 2, { status: 'COMPLETED', expectedStatus: 'PENDING' })).status, 409);
  const completed = await call(`/admin/tickets/${ticket._id}/status`, 2, { status: 'COMPLETED', expectedStatus: 'ACTION_TAKEN' });
  assert.deepEqual(completed.data.statusHistory.map(h => h.status), ['PENDING', 'ACTION_TAKEN', 'COMPLETED']);
  assert.equal((await call('/tickets?status=COMPLETED', 0)).data.length, 1);
  assert.equal((await call('/admin/tickets?status=PENDING', 2)).data.length, 0);
  assert.equal((await call('/admin/tickets?status=UNKNOWN', 2)).status, 400);
});
test('ticket replies and read markers cannot leak across tickets or customers', async () => {
  const first = (await call('/tickets', 0)).data[0];
  const second = (await call('/tickets', 0, { issue: 'WALLET', description: 'Balance issue', clientId: 'ticket-two' })).data;
  const reply = await call(`/admin/tickets/${first._id}/messages`, 2, { text: 'We checked your payment', clientId: 'ticket-reply' });
  assert.equal(reply.status, 200);
  assert.equal((await call(`/tickets/${first._id}/messages`, 0)).data.filter(m => m.sender === 'support').length, 1);
  assert.equal((await call(`/tickets/${second._id}/messages`, 0)).data.filter(m => m.sender !== 'automated').length, 0);
  assert.equal((await call(`/tickets/${first._id}/messages`, 1)).status, 404);
  assert.equal((await call(`/tickets/${second._id}/read`, 0, { through: reply.data._id })).status, 404);
  assert.equal((await call(`/tickets/${first._id}/read`, 0, { through: reply.data._id })).status, 200);
  assert.ok((await call(`/tickets/${first._id}/messages`, 0)).data.find(m => m._id === reply.data._id).readAt);
});

test('automated guidance is labeled, retry safe and can hand off to humans', async () => {
  const ticket = (await call('/tickets', 0, { issue: 'DOWNLOAD', description: 'Unable to download', clientId: 'automated-ticket' })).data;
  const path = `/tickets/${ticket._id}`;
  let rows = (await call(`${path}/messages`, 0)).data;
  assert.equal(rows.length, 1);
  assert.equal(rows[0].sender, 'automated');
  assert.equal(rows[0].authorName, 'Automated support assistant');
  assert.equal((await call(`${path}/automation`, 1, { choice: 'DOWNLOAD' })).status, 404);
  assert.equal((await call(`${path}/automation`, 0, { choice: 'INVALID' })).status, 400);
  await call(`${path}/automation`, 0, { choice: 'DOWNLOAD' });
  await call(`${path}/automation`, 0, { choice: 'DOWNLOAD' });
  assert.equal((await call(`${path}/messages`, 0)).data.length, 2);
  await call(`${path}/automation`, 0, { choice: 'HUMAN' });
  await call(`${path}/automation`, 0, { choice: 'HUMAN' });
  const handoff = (await call(path, 0)).data;
  assert.ok(handoff.humanRequestedAt);
  assert.equal(handoff.status, 'PENDING');
  rows = (await call(`${path}/messages`, 0)).data;
  assert.equal(rows.length, 3);
  assert.match(rows.at(-1).text, /human support queue/);
  assert.equal((await call(`${path}/automation`, 0, { choice: 'DOWNLOAD' })).status, 409);
  await call(`/admin/tickets/${ticket._id}/messages`, 2, { text: 'I can help with the download', clientId: 'human-download' });
  assert.ok((await call(path, 0)).data.humanReplyAt);
});
