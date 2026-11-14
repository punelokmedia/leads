import test from 'node:test';
import assert from 'node:assert/strict';
process.env.RESEND_API_KEY = 're_test_only';
process.env.RAZORPAY_KEY_ID = 'test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_secret';
const { notificationRouter } = await import('../src/Routes/notification.routes.js');
const { Notification, NotificationPreference, defaultPreferences } = await import('../src/Models/notification.model.js');
const { User } = await import('../src/Models/user.model.js');
const { notifyUser } = await import('../src/Services/notification.service.js');
const handler = method => notificationRouter.stack.find(layer => layer.route?.path === '/preferences' && layer.route.methods[method]).route.stack[0].handle;
const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });

test('notification defaults preserve existing consent and include all preference fields', () => {
  assert.equal(defaultPreferences.announcements, true);
  assert.equal(defaultPreferences.push, false);
  assert.equal(defaultPreferences.whatsapp, false);
  const row = new NotificationPreference({ user: '507f1f77bcf86cd799439011' });
  for (const [key, value] of Object.entries(defaultPreferences)) assert.equal(row[key], value);
});

test('preferences API saves boolean fields for the authenticated account only', async (t) => {
  let calls = 0;
  const changes = { leadUpdates: false, payments: false, membership: false, referrals: false, whatsapp: true };
  t.mock.method(NotificationPreference, 'findOneAndUpdate', async (query, update) => {
    calls++;
    assert.deepEqual(query, { user: 'current-user' });
    assert.deepEqual(update.$set, changes);
    return { ...defaultPreferences, ...update.$set };
  });
  const res = response();
  await handler('patch')({ user: { id: 'current-user' }, body: changes }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.payments, false);
  assert.equal(res.body.data.whatsapp, true);
  for (const body of [{ payments: 'false' }, { user: 'other-user' }, {}]) {
    const bad = response();
    await handler('patch')({ user: { id: 'current-user' }, body }, bad);
    assert.equal(bad.statusCode, 400);
  }
  assert.equal(calls, 1);
});

test('payment and membership preferences suppress their alerts while support replies remain enabled', async (t) => {
  t.mock.method(User, 'findOne', () => ({ select: () => ({ session: async () => ({ _id: 'user' }) }) }));
  t.mock.method(NotificationPreference, 'findOne', () => ({ session: () => ({ lean: async () => ({ payments: false, membership: false }) }) }));
  let writes = 0;
  t.mock.method(Notification, 'findOneAndUpdate', async () => { writes++; return { _id: 'notification' }; });
  for (const type of ['PAYMENT_SUCCESS', 'WALLET_CREDIT', 'REFUND_COMPLETED', 'MEMBERSHIP_ACTIVATED']) {
    assert.equal(await notifyUser({ user: 'user', type, eventKey: type, title: type, message: 'Test' }), null);
  }
  assert.equal(writes, 0);
  assert.ok(await notifyUser({ user: 'user', type: 'SUPPORT_REPLY', eventKey: 'support', title: 'Reply', message: 'Test' }));
  assert.equal(writes, 1);
});
