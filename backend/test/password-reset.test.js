import test from 'node:test';
import assert from 'node:assert/strict';
process.env.RESEND_API_KEY = 're_test_only';
process.env.RAZORPAY_KEY_ID = 'test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_secret';
const { resetPassword } = await import('../src/Controllers/auth.controller.js');
const { User } = await import('../src/Models/user.model.js');
const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });
const body = { email: 'user@example.com', newPassword: 'new-password-123', confirmPassword: 'new-password-123' };

test('password reset requires an OTP before querying users', async (t) => {
  t.mock.method(User, 'findOne', () => assert.fail('must reject before database access'));
  const res = response();
  await resetPassword({ body }, res);
  assert.equal(res.statusCode, 400);
});

test('password reset rejects incorrect and expired OTPs', async (t) => {
  for (const [resetOtp, resetOtpExpire] of [['9999', new Date(Date.now() + 60000)], ['1234', new Date(0)]]) {
    t.mock.method(User, 'findOne', async () => ({ resetOtp, resetOtpExpire, save() { assert.fail('must not change password'); } }));
    const res = response();
    await resetPassword({ body: { ...body, otp: '1234' } }, res);
    assert.equal(res.statusCode, 400);
  }
});

test('valid password reset hashes the password and consumes the OTP', async (t) => {
  let saved = false;
  const user = { resetOtp: '1234', resetOtpExpire: new Date(Date.now() + 60000), async save() { saved = true; } };
  t.mock.method(User, 'findOne', async () => user);
  const res = response();
  await resetPassword({ body: { ...body, otp: '1234' } }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(saved, true);
  assert.notEqual(user.password, body.newPassword);
  assert.equal(user.resetOtp, null);
  assert.equal(user.resetOtpExpire, null);
});
