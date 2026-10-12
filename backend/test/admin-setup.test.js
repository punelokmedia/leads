import test from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import { setupAdmin } from '../src/Services/admin-setup.service.js';
import { User } from '../src/Models/user.model.js';
import { comparePassword, hashPassword } from '../src/Utils/hash.js';
process.env.RESEND_API_KEY = 're_admin_setup_test_only';
process.env.RAZORPAY_KEY_ID = 'admin_setup_test_key';
process.env.RAZORPAY_KEY_SECRET = 'admin_setup_test_secret';
const { verifyAdminOtp } = await import('../src/Controllers/Admin/admin.controller.js');

test('setup initializes a missing admin password, clears OTP and revokes sessions without leaking plaintext', async t => {
  t.mock.method(User, 'findOne', async query => {
    assert.equal(query.email.$options, 'i');
    return { _id: 'admin-id', role: 'ADMIN', password: null };
  });
  t.mock.method(User, 'updateOne', async (filter, update) => {
    assert.equal(filter.role, 'ADMIN');
    assert.equal(update.$set.resetOtp, null);
    assert.equal(update.$set.resetOtpExpire, null);
    assert.equal(update.$inc.sessionVersion, 1);
    assert.notEqual(update.$set.password, 'setup-test-password');
    assert.ok(await comparePassword('setup-test-password', update.$set.password));
    return { modifiedCount: 1 };
  });
  assert.deepEqual(await setupAdmin({ email: ' ADMIN@example.invalid ', password: 'setup-test-password' }), { status: 'PASSWORD_INITIALIZED' });
});

test('setup preserves existing admin passwords and refuses automatic role elevation', async t => {
  t.mock.method(User, 'updateOne', () => assert.fail('must not change existing password or role'));
  const find = t.mock.method(User, 'findOne', async () => ({ role: 'ADMIN', password: 'existing-hash' }));
  assert.deepEqual(await setupAdmin({ email: 'admin@example.invalid', password: 'different' }), { status: 'EXISTS' });
  find.mock.mockImplementation(async () => ({ role: 'USER', password: null }));
  await assert.rejects(setupAdmin({ email: 'admin@example.invalid', password: 'different' }), /without ADMIN role/);
});

test('production requires saved password plus OTP; failure preserves OTP and success issues MFA token', async t => {
  const previous = { node: process.env.NODE_ENV, jwt: process.env.JWT_SECRET };
  process.env.NODE_ENV = 'production'; process.env.JWT_SECRET = 'admin-setup-test-secret';
  t.after(() => {
    if (previous.node === undefined) delete process.env.NODE_ENV; else process.env.NODE_ENV = previous.node;
    if (previous.jwt === undefined) delete process.env.JWT_SECRET; else process.env.JWT_SECRET = previous.jwt;
  });
  let saves = 0;
  const admin = { _id: 'admin-id', role: 'ADMIN', email: 'admin@example.invalid', password: await hashPassword('correct-password'), resetOtp: '1234', resetOtpExpire: new Date(Date.now() + 60000), sessionVersion: 1, async save() { saves++ } };
  t.mock.method(User, 'findOne', async () => admin);
  const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this }, json(body) { this.body = body; return this } });
  for (const password of [undefined, '', 'incorrect-password']) {
    const res = response();
    await verifyAdminOtp({ body: { email: admin.email, otp: '1234', password } }, res);
    assert.equal(res.statusCode, 401);
    assert.equal(admin.resetOtp, '1234');
    assert.equal(saves, 0);
  }
  const res = response();
  await verifyAdminOtp({ body: { email: admin.email, otp: '1234', password: 'correct-password' } }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(jwt.verify(res.body.token, process.env.JWT_SECRET).mfa, true);
  assert.equal(admin.resetOtp, null);
  assert.equal(saves, 1);
});
