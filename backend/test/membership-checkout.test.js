import test from 'node:test';
import assert from 'node:assert/strict';
process.env.RAZORPAY_KEY_ID = 'test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_secret';
const { createOrder } = await import('../src/Controllers/orders/payment.controller.js');
const { User } = await import('../src/Models/user.model.js');
const { Order } = await import('../src/Models/orders.models.js');
function response() {
  return { statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };
}
test('first-time unpaid user is shown membership before any lead reservation', async (t) => {
  t.mock.method(User, 'findById', () => ({ select: async () => ({ registrationFeePaid: false }) }));
  t.mock.method(Order, 'exists', async () => null);
  t.mock.method(Order, 'findOne', () => assert.fail('must not reserve leads'));
  const res = response();
  await createOrder({ user: { id: 'new-user' }, body: {} }, res);
  assert.equal(res.statusCode, 403);
  assert.equal(res.body.code, 'MEMBERSHIP_REQUIRED');
});
for (const [name, paid, purchased] of [['lifetime member', true, false], ['existing lead buyer', false, true]]) {
  test(name + ' skips membership on subsequent checkout', async (t) => {
    t.mock.method(User, 'findById', () => ({ select: async () => ({ registrationFeePaid: paid }) }));
    t.mock.method(Order, 'exists', async () => purchased ? { _id: 'prior-order' } : null);
    const previous = process.env.RAZORPAY_KEY_ID;
    const previousAlias = process.env.RAZORPAY_KEY;
    process.env.RAZORPAY_KEY_ID = '';
    process.env.RAZORPAY_KEY = '';
    const res = response();
    try { await createOrder({ user: { id: 'existing-user' }, body: {} }, res); }
    finally {
      process.env.RAZORPAY_KEY_ID = previous;
      if (previousAlias !== undefined) process.env.RAZORPAY_KEY = previousAlias;
      else delete process.env.RAZORPAY_KEY;
    }
    assert.equal(res.body.code, 'PAYMENTS_UNAVAILABLE');
  });
}

process.env.RESEND_API_KEY = 're_test_only';
const { verifyMobileRegistrationPayment } = await import('../src/Controllers/auth.controller.js');
const { razorpay } = await import('../src/Config/razorpay.config.js');
const { createHmac } = await import('node:crypto');
const paymentBody = {
  razorpayOrderId: 'order_membership', razorpayPaymentId: 'pay_membership', membershipOnly: true,
  razorpaySignature: createHmac('sha256', 'test_secret').update('order_membership|pay_membership').digest('hex'),
};
function gateway(t, overrides = {}, noteOverrides = {}) {
  t.mock.method(razorpay.orders, 'fetch', async () => ({ amount: 49900, currency: 'INR', notes: { userId: 'new-user', purpose: 'signup_registration_fee', ...noteOverrides } }));
  t.mock.method(razorpay.payments, 'fetch', async () => ({ order_id: 'order_membership', amount: 49900, currency: 'INR', status: 'captured', ...overrides }));
}
for (const [label, payment, notes] of [
  ['uncaptured', { status: 'authorized' }, {}],
  ['wrong amount', { amount: 100 }, {}],
  ['wrong account', {}, { userId: 'another-user' }],
  ['lead order', {}, { purpose: 'lead_purchase' }],
]) {
  test('membership rejects ' + label + ' payment', async (t) => {
    gateway(t, payment, notes);
    t.mock.method(User, 'findOneAndUpdate', () => assert.fail('must not activate membership'));
    const res = response();
    await verifyMobileRegistrationPayment({ user: { id: 'new-user' }, body: paymentBody }, res);
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.success, false);
  });
}
test('captured membership payment activates once without requiring profile fields', async (t) => {
  gateway(t);
  const member = { _id: 'new-user', registrationFeePaid: true };
  let calls = 0;
  t.mock.method(User, 'findOneAndUpdate', (filter, update) => {
    assert.equal(filter.registrationFeePaid.$ne, true);
    assert.equal(update.$set.registrationPayment.amount, 499);
    return { select: async () => ++calls === 1 ? member : null };
  });
  t.mock.method(User, 'findById', () => ({ select: async () => member }));
  for (let i = 0; i < 2; i++) {
    const res = response();
    await verifyMobileRegistrationPayment({ user: { id: 'new-user' }, body: paymentBody }, res);
    assert.equal(res.body.success, true);
    assert.equal(res.body.data.registrationFeePaid, true);
  }
});
