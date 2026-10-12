import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import { notificationRouter } from '../src/Routes/notification.routes.js';
import { User } from '../src/Models/user.model.js';
import { Notification, NotificationPreference, NotificationDevice, NotificationReceipt, notificationTypes } from '../src/Models/notification.model.js';
import { notifyUser, notifyNewLead } from '../src/Services/notification.service.js';

let mongo, server, base, users, tokens;
before(async () => {
  process.env.JWT_SECRET = 'isolated-notification-test-secret';
  User.schema.set('autoIndex', false);
  mongo = await MongoMemoryReplSet.create({ binary: { version: '7.0.24' }, replSet: { count: 1 } });
  await mongoose.connect(mongo.getUri());
  await Promise.all([Notification.init(), NotificationPreference.init(), NotificationDevice.init(), NotificationReceipt.init()]);
  users = await User.create(['USER', 'USER', 'ADMIN'].map((role, i) => ({ firstname: 'Test', lastname: 'User', email: `notification${i}@example.invalid`, role, city: 'Mumbai', state: 'Maharashtra' })));
  tokens = users.map(u => jwt.sign({ id: u.id }, process.env.JWT_SECRET));
  const app = express(); app.use(express.json()); app.use('/notifications', notificationRouter);
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}/notifications`;
}, { timeout: 900000 });
after(async () => { if (server) await new Promise(resolve => server.close(resolve)); await mongoose.disconnect(); if (mongo) await mongo.stop(); });
async function call(path, user = 0, method = 'GET', body) {
  const response = await fetch(base + path, { method, headers: { 'Content-Type': 'application/json', ...(user === null ? {} : { Authorization: `Bearer ${tokens[user]}` }) }, body: body ? JSON.stringify(body) : undefined });
  return { status: response.status, ...(await response.json()) };
}
test('inbox authentication, isolation, deduplication and shared read state', async () => {
  assert.equal((await call('/', null)).status, 401);
  const event = { user: users[0]._id, eventKey: 'payment:test', type: 'PAYMENT_SUCCESS', title: 'Paid', message: 'Confirmed' };
  const rows = await Promise.all(Array.from({ length: 4 }, () => notifyUser(event)));
  assert.equal(new Set(rows.map(r => r.id)).size, 1);
  assert.equal((await call('/unread-count')).data.count, 1);
  assert.equal((await call('/', 1)).data.length, 0);
  assert.equal((await call(`/${rows[0].id}/read`, 1, 'PATCH')).status, 404);
  assert.equal((await call(`/${rows[0].id}/read`, 0, 'PATCH')).status, 200);
  assert.equal((await call('/unread-count')).data.count, 0);
  assert.equal((await call('/?before=bad')).status, 400);
});
test('lead recipient matching and preferences', async () => {
  const category = new mongoose.Types.ObjectId();
  await User.updateOne({ _id: users[0]._id }, { $set: { categories: [category] } });
  const lead = { _id: new mongoose.Types.ObjectId(), category, city: 'mumbai', state: 'maharashtra', status: 'ACTIVE', expiresAt: new Date(Date.now() + 60000), buyersCount: 0 };
  await notifyNewLead(lead);
  assert.equal(await Notification.countDocuments({ eventKey: `lead:${lead._id}` }), 1);
  assert.equal((await call('/preferences', 0, 'PATCH', { newLeads: false })).status, 200);
  await notifyNewLead({ ...lead, _id: new mongoose.Types.ObjectId() });
  assert.equal(await Notification.countDocuments({ type: 'NEW_LEAD' }), 1);
  assert.equal((await call('/preferences', 0, 'PATCH', { user: users[1].id })).status, 400);
});
test('device consent, account switching, token privacy and owner-only removal', async () => {
  const token = 'test-fcm-device-token-12345';
  assert.equal((await call('/devices', 0, 'POST', { token, platform: 'web', permission: 'denied' })).status, 400);
  assert.equal((await call('/devices', 0, 'POST', { token, platform: 'web', permission: 'granted' })).status, 201);
  assert.equal((await call('/preferences')).data.push, false);
  await call('/devices', 1, 'POST', { token, platform: 'web', permission: 'granted' });
  await call('/devices', 0, 'DELETE', { token });
  const device = await NotificationDevice.findOne({ token }).lean();
  assert.equal(String(device.user), users[1].id);
  assert.equal(device.token, undefined);
  await call('/devices', 1, 'DELETE', { token });
  assert.equal(await NotificationDevice.countDocuments({ token }), 0);
});
test('admin sends are restricted and retry-safe; announcements honor opt out', async () => {
  const body = { userIds: users.slice(0, 2).map(u => u.id), title: 'Update', message: 'Details', clientId: 'send-one' };
  assert.equal((await call('/admin/send', 0, 'POST', body)).status, 403);
  await call('/preferences', 1, 'PATCH', { announcements: false });
  assert.equal((await call('/admin/send', 2, 'POST', body)).data.recipients, 1);
  await call('/admin/send', 2, 'POST', body);
  assert.equal(await Notification.countDocuments({ type: 'ANNOUNCEMENT' }), 1);
});
test('notification writes roll back with their business transaction', async () => {
  const session = await mongoose.startSession();
  try {
    await assert.rejects(session.withTransaction(async () => {
      await notifyUser({ user: users[0]._id, eventKey: 'rollback:test', type: 'WALLET_CREDIT', title: 'Credit', message: 'Confirmed' }, session);
      throw new Error('business write failed');
    }), /business write failed/);
    assert.equal(await Notification.countDocuments({ eventKey: 'rollback:test' }), 0);
  } finally { await session.endSession(); }
});

test('admin monitoring is protected, validates filters and shows all seven notification types', async () => {
  for (const path of ['/admin/summary', '/admin/notifications']) {
    assert.equal((await call(path, null)).status, 401);
    assert.equal((await call(path, 0)).status, 403);
  }
  const summary = await call('/admin/summary', 2);
  assert.equal(summary.status, 200);
  assert.equal(summary.data.saved, await Notification.countDocuments());
  assert.equal(summary.data.read, await Notification.countDocuments({ readAt: { $ne: null } }));
  assert.equal(summary.data.byType.length, 7);
  assert.equal(summary.data.received, 0);
  assert.equal(summary.data.push.configured, false);
  assert.equal((await call('/admin/summary?userId=bad', 2)).status, 400);
  assert.equal((await call('/admin/summary?type=UNKNOWN', 2)).status, 400);
  assert.equal((await call('/admin/summary?from=yesterday', 2)).status, 400);
  assert.equal((await call('/admin/notifications?limit=1000', 2)).status, 400);
  const empty = await call('/admin/summary?type=REFUND_COMPLETED', 2);
  assert.equal(empty.data.saved, 0);
  assert.equal(empty.data.unread, 0);
});

test('only owner can acknowledge receipt and mobile/web confirmations are independent and retry-safe', async () => {
  const row = await notifyUser({ user: users[0]._id, eventKey: 'receipt:test', type: 'SUPPORT_REPLY', title: 'Reply', message: 'New support reply' });
  const path = `/${row.id}/received`;
  assert.equal((await call(path, 1, 'POST', { channel: 'mobile' })).status, 404);
  assert.equal((await call(path, 0, 'POST', { channel: 'email' })).status, 400);
  assert.equal((await call(path, null, 'POST', { channel: 'web' })).status, 401);
  const before = await call(`/admin/notifications/${row.id}`, 2);
  assert.equal(before.data.receiptStatus, 'AWAITING_CLIENT');
  // Fetching inbox history alone is never treated as proof of receipt.
  await call('/');
  assert.equal(await NotificationReceipt.countDocuments({ notification: row._id }), 0);
  const receipts = await Promise.all(Array.from({ length: 4 }, () => call(path, 0, 'POST', { channel: 'mobile' })));
  assert.ok(receipts.every(r => r.status === 200));
  assert.equal(new Set(receipts.map(r => r.data.receivedAt)).size, 1);
  await call(path, 0, 'POST', { channel: 'web' });
  assert.equal(await NotificationReceipt.countDocuments({ notification: row._id }), 2);
  const detail = await call(`/admin/notifications/${row.id}`, 2);
  assert.equal(detail.data.recipient._id, users[0].id);
  assert.equal(detail.data.receiptStatus, 'RECEIVED');
  assert.equal(detail.data.readAt, null);
  assert.equal(detail.data.pushStatus, 'NOT_CONFIGURED');
  const summary = await call(`/admin/summary?userId=${users[0].id}&type=SUPPORT_REPLY`, 2);
  assert.equal(summary.data.received, 1);
  assert.equal(summary.data.mobileReceived, 1);
  assert.equal(summary.data.webReceived, 1);
  assert.equal(summary.data.awaitingClient, 0);
  await call(`/${row.id}/read`, 0, 'PATCH');
  assert.equal((await call(`/admin/summary?type=SUPPORT_REPLY&read=true`, 2)).data.read, 1);
});

test('admin history paginates and recipient diagnostics never expose push tokens or private auth fields', async () => {
  const token = 'admin-diagnostic-test-device-token';
  await call('/devices', 0, 'POST', { token, platform: 'android', permission: 'granted' });
  const first = await call(`/admin/notifications?userId=${users[0].id}&limit=1`, 2);
  assert.equal(first.data.length, 1);
  assert.ok(first.nextCursor);
  const second = await call(`/admin/notifications?userId=${users[0].id}&limit=1&before=${first.nextCursor}`, 2);
  assert.notEqual(first.data[0]._id, second.data[0]._id);
  const detail = await call(`/admin/notifications/${first.data[0]._id}`, 2);
  assert.equal(detail.data.devices.length, 1);
  assert.equal(detail.data.devices[0].platform, 'android');
  assert.equal(detail.data.devices[0].token, undefined);
  assert.equal(detail.data.recipient.password, undefined);
  assert.equal(detail.data.recipient.sessionVersion, undefined);
  assert.equal((await call(`/admin/notifications/${first.data[0]._id}`, 0)).status, 403);
  assert.equal((await call('/admin/notifications/not-an-id', 2)).status, 400);
  assert.equal((await call(`/admin/notifications/${new mongoose.Types.ObjectId()}`, 2)).status, 404);
});

test('every notification type stays in its own recipient inbox and can be confirmed on both systems', async () => {
  await call('/preferences', 0, 'PATCH', { newLeads: true, announcements: true });
  const created = [];
  for (const type of notificationTypes) created.push(await notifyUser({ user: users[0]._id, eventKey: `all-types:${type}`, type, title: type, message: 'Recipient routing check' }));
  const ownerInbox = await call('/?limit=100');
  const otherInbox = await call('/?limit=100', 1);
  for (const row of created) {
    assert.ok(ownerInbox.data.some(item => item._id === row.id));
    assert.ok(!otherInbox.data.some(item => item._id === row.id));
    assert.equal((await call(`/${row.id}/received`, 1, 'POST', { channel: 'web' })).status, 404);
    for (const channel of ['mobile', 'web']) assert.equal((await call(`/${row.id}/received`, 0, 'POST', { channel })).status, 200);
    const detail = await call(`/admin/notifications/${row.id}`, 2);
    assert.equal(detail.data.recipient._id, users[0].id);
    assert.equal(detail.data.receipts.length, 2);
    assert.equal(detail.data.receiptStatus, 'RECEIVED');
  }
});

test('recipient search is admin-only, literal and excludes blocked accounts and private fields', async () => {
  assert.equal((await call('/admin/recipients', null)).status, 401);
  assert.equal((await call('/admin/recipients', 0)).status, 403);
  const result = await call('/admin/recipients?q=notification0', 2);
  assert.equal(result.status, 200);
  assert.equal(result.data.length, 1);
  assert.equal(result.data[0]._id, users[0].id);
  assert.equal(result.data[0].password, undefined);
  assert.equal((await call('/admin/recipients?q=%2E%2A', 2)).data.length, 0);
  assert.equal((await call('/admin/recipients?before=bad', 2)).status, 400);
  await User.updateOne({ _id: users[1]._id }, { $set: { isBlocked: true } });
  assert.equal((await call(`/admin/recipients?q=${users[1].id}`, 2)).data.length, 0);
  await User.updateOne({ _id: users[1]._id }, { $set: { isBlocked: false } });
});
