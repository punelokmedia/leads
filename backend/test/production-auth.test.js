import test from 'node:test';
import assert from 'node:assert/strict';
process.env.RESEND_API_KEY = 're_test_only';
process.env.RAZORPAY_KEY_ID = 'test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_secret';
const { verifyAdminOtp } = await import('../src/Controllers/Admin/admin.controller.js');
const { requestMobileOtp, requestSessionMobileOtp } = await import('../src/Controllers/auth.controller.js');
const { User } = await import('../src/Models/user.model.js');
const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });

test('admin login rejects missing OTP before database access', async (t) => {
  t.mock.method(User, 'findOne', () => assert.fail('must not access database'));
  const res = response();
  await verifyAdminOtp({ body: { email: 'admin@example.com' } }, res);
  assert.equal(res.statusCode, 400);
});

test('admin login rejects an OTP without an expiry', async (t) => {
  t.mock.method(User, 'findOne', async () => ({ role: 'ADMIN', resetOtp: '1234', save() { assert.fail('must not authenticate'); } }));
  const res = response();
  await verifyAdminOtp({ body: { email: 'admin@example.com', otp: '1234' } }, res);
  assert.equal(res.statusCode, 400);
});

test('production phone OTP does not claim delivery without an SMS integration', async (t) => {
  const previous = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';
  t.after(() => {
    if (previous === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = previous;
  });
  t.mock.method(User, 'findOne', () => assert.fail('must not create an undeliverable code'));
  for (const handler of [requestMobileOtp, requestSessionMobileOtp]) {
    const res = response();
    await handler({ body: { phoneNumber: '9876543210' } }, res);
    assert.equal(res.statusCode, 503);
    assert.equal(res.body.code, 'SMS_NOT_CONFIGURED');
  }
});

test('user JSON omits passwords, OTPs and payment signatures', () => {
  const user = new User({ password: 'secret', resetOtp: '1234', loginOtp: '654321', resetOtpExpire: new Date(), loginOtpExpire: new Date(), pendingPhoneNumber: '9876543210', registrationPayment: { razorpaySignature: 'secret-signature' } });
  const json = JSON.parse(JSON.stringify(user));
  for (const field of ['password', 'resetOtp', 'resetOtpExpire', 'loginOtp', 'loginOtpExpire', 'pendingPhoneNumber']) assert.equal(json[field], undefined);
  assert.equal(json.registrationPayment?.razorpaySignature, undefined);
});
