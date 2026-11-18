import { before, after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';

// Phone OTP via Twilio Verify. Every Twilio response here is mocked; no SMS is sent.
process.env.RESEND_API_KEY = 're_test_only';
process.env.RAZORPAY_KEY_ID = 'test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_secret';
process.env.JWT_SECRET = 'phone-otp-test-only';
const { requestMobileOtp, requestSessionMobileOtp, verifyMobileOtp, verifySessionMobileOtp } = await import('../src/Controllers/auth.controller.js');
const { User } = await import('../src/Models/user.model.js');
const { setTwilioFetch } = await import('../src/Services/sms-verification.js');

const CODE = '482913';
const TWILIO_ENV = { TWILIO_VERIFY_SERVICE_SID: 'VAtest', TWILIO_API_KEY_SID: 'SKtest', TWILIO_API_KEY_SECRET: 'secret-test' };
const OTP_ENV_KEYS = ['NODE_ENV', 'SMS_PROVIDER', 'TWILIO_VERIFY_SERVICE_SID', 'TWILIO_VERIFY_PHONE_CHANGE_SERVICE_SID', 'TWILIO_API_KEY_SID', 'TWILIO_API_KEY_SECRET', 'TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN'];
const savedEnv = Object.fromEntries(OTP_ENV_KEYS.map((key) => [key, process.env[key]]));
let mongo, calls, sid, logs;

const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });
const invoke = async (handler, body, user) => { const res = response(); await handler({ body, user, header: () => undefined }, res); return res; };

// Fake Twilio Verify: accepts sends, approves CODE for the most recent verification of each number.
const fakeTwilio = ({ sendStatus = 201, sendBody } = {}) => setTwilioFetch(async (url, init) => {
  const form = Object.fromEntries(new URLSearchParams(init.body));
  calls.push({ url, form, authorization: init.headers.Authorization });
  if (url.endsWith('/Verifications')) {
    sid += 1;
    return { status: sendStatus, ok: sendStatus < 300, json: async () => sendBody ?? { sid: `VE${sid}`, to: form.To, status: 'pending', channel: 'sms', valid: false } };
  }
  const approved = form.Code === CODE;
  return { status: 200, ok: true, json: async () => ({ sid: `VE${sid}`, to: form.To, status: approved ? 'approved' : 'pending', valid: approved }) };
});

before(async () => {
  mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  await User.init();
}, { timeout: 900000 });
after(async () => {
  for (const key of OTP_ENV_KEYS) { if (savedEnv[key] === undefined) delete process.env[key]; else process.env[key] = savedEnv[key]; }
  await mongoose.disconnect();
  if (mongo) await mongo.stop();
});
beforeEach((t) => {
  for (const key of OTP_ENV_KEYS) delete process.env[key];
  Object.assign(process.env, { NODE_ENV: 'production', ...TWILIO_ENV });
  calls = []; sid = 0; logs = [];
  t.after(setTwilioFetch(async () => { throw new Error('Unexpected Twilio call'); }));
  for (const level of ['log', 'info', 'warn', 'error']) t.mock.method(console, level, (...args) => logs.push(args.map(String).join(' ')));
});

test('missing Twilio configuration in production returns 503 before touching the database or Twilio', async (t) => {
  delete process.env.TWILIO_VERIFY_SERVICE_SID;
  t.mock.method(User, 'findOne', () => assert.fail('must not access database'));
  for (const handler of [requestMobileOtp, requestSessionMobileOtp]) {
    const res = await invoke(handler, { phoneNumber: '9876543210' }, { id: new mongoose.Types.ObjectId().toString() });
    assert.equal(res.statusCode, 503);
    assert.equal(res.body.code, 'SMS_NOT_CONFIGURED');
  }
  process.env.SMS_PROVIDER = 'local';
  process.env.TWILIO_VERIFY_SERVICE_SID = 'VAtest';
  assert.equal((await invoke(requestMobileOtp, { phoneNumber: '9876543210' })).statusCode, 503, 'local provider is never allowed in production');
});

test('login OTP: OTP_SENT only after Twilio accepts, without exposing the code', async (t) => {
  t.after(fakeTwilio());
  const res = await invoke(requestMobileOtp, { phoneNumber: '+91 98765 43211' });
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.code, 'OTP_SENT');
  assert.deepEqual(Object.keys(res.body.data).sort(), ['expiresInSeconds', 'phoneNumber']);
  assert.equal(res.body.data.phoneNumber, '9876543211');
  assert.ok(res.body.data.expiresInSeconds > 500 && res.body.data.expiresInSeconds <= 600);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, 'https://verify.twilio.com/v2/Services/VAtest/Verifications');
  assert.deepEqual(calls[0].form, { To: '+919876543211', Channel: 'sms' });
  assert.equal(calls[0].authorization, 'Basic ' + Buffer.from('SKtest:secret-test').toString('base64'));
  const user = await User.findOne({ phoneNumber: '9876543211' });
  assert.equal(user.phoneVerification.purpose, 'LOGIN');
  assert.equal(user.phoneVerification.verificationSid, 'VE1');
  assert.equal(String(user.phoneVerification.userId), String(user._id));
  assert.equal(user.phoneVerification.codeHash, undefined);
  assert.equal(JSON.parse(JSON.stringify(user)).phoneVerification, undefined);

  // A resend inside the cooldown reuses the pending Twilio verification instead of sending again.
  assert.equal((await invoke(requestMobileOtp, { phoneNumber: '9876543211' })).body.code, 'OTP_SENT');
  assert.equal(calls.length, 1);
});

test('login OTP: Twilio rejection returns an error and stores nothing', async (t) => {
  t.after(fakeTwilio({ sendStatus: 400, sendBody: { code: 60200, message: 'Invalid parameter' } }));
  const res = await invoke(requestMobileOtp, { phoneNumber: '9876543212' });
  assert.equal(res.statusCode, 502);
  assert.equal(res.body.code, 'OTP_SEND_FAILED');
  assert.equal(await User.findOne({ phoneNumber: '9876543212' }), null, 'no placeholder account for an unsent code');

  t.after(fakeTwilio({ sendStatus: 429, sendBody: { code: 60203, message: 'Max send attempts reached' } }));
  const limited = await invoke(requestMobileOtp, { phoneNumber: '9876543212' });
  assert.equal(limited.statusCode, 429);
  assert.equal(limited.body.code, 'OTP_RATE_LIMITED');

  t.after(setTwilioFetch(async () => { throw new TypeError('fetch failed'); }));
  assert.equal((await invoke(requestMobileOtp, { phoneNumber: '9876543212' })).statusCode, 502);
});

test('login OTP: wrong code is rejected, valid code logs in once', async (t) => {
  t.after(fakeTwilio());
  await invoke(requestMobileOtp, { phoneNumber: '9876543213' });
  const wrong = await invoke(verifyMobileOtp, { phoneNumber: '9876543213', otp: '000000' });
  assert.equal(wrong.statusCode, 400);
  assert.equal(wrong.body.code, 'INVALID_OTP');
  assert.deepEqual(calls.at(-1).form, { To: '+919876543213', Code: '000000' });
  assert.equal((await invoke(verifyMobileOtp, { phoneNumber: '9876543213', otp: 'abc' })).body.code, 'INVALID_OTP');

  const ok = await invoke(verifyMobileOtp, { phoneNumber: '9876543213', otp: CODE });
  assert.equal(ok.statusCode, 200);
  assert.equal(ok.body.code, 'LOGIN_SUCCESS');
  assert.ok(ok.body.token);
  assert.equal(ok.body.data.phoneNumber, '9876543213');
  assert.equal(ok.body.meta.isNewUser, true);
  assert.equal((await User.findOne({ phoneNumber: '9876543213' })).phoneVerification, undefined);

  const before = calls.length;
  assert.equal((await invoke(verifyMobileOtp, { phoneNumber: '9876543213', otp: CODE })).statusCode, 400, 'code is single-use');
  assert.equal(calls.length, before, 'consumed binding is rejected without asking Twilio');

  assert.ok(!logs.join('\n').includes(CODE), 'OTP never logged');
});

test('phone change OTP: bound to the signed-in user and number', async (t) => {
  t.after(fakeTwilio());
  const owner = await User.create({ firstname: 'Owner', lastname: 'Test', email: 'owner@example.invalid' });
  const other = await User.create({ firstname: 'Other', lastname: 'Test', email: 'other@example.invalid' });
  const sent = await invoke(requestSessionMobileOtp, { phoneNumber: '9876543214' }, { id: owner.id });
  assert.equal(sent.statusCode, 200);
  assert.deepEqual(Object.keys(sent.body.data).sort(), ['expiresInSeconds', 'phoneNumber']);
  const binding = (await User.findById(owner.id)).phoneVerification;
  assert.equal(binding.purpose, 'PHONE_CHANGE');
  assert.equal(String(binding.userId), owner.id);

  assert.equal((await invoke(verifySessionMobileOtp, { phoneNumber: '9876543214', otp: CODE }, { id: other.id })).statusCode, 400, 'another user cannot use it');
  assert.equal((await invoke(verifySessionMobileOtp, { phoneNumber: '9876543299', otp: CODE }, { id: owner.id })).statusCode, 400, 'another number cannot use it');
  assert.equal((await invoke(verifySessionMobileOtp, { phoneNumber: '9876543214', otp: '000000' }, { id: owner.id })).statusCode, 400);

  const ok = await invoke(verifySessionMobileOtp, { phoneNumber: '9876543214', otp: CODE }, { id: owner.id });
  assert.equal(ok.statusCode, 200);
  assert.equal(ok.body.code, 'PHONE_VERIFIED');
  assert.equal(ok.body.data.phoneNumber, '9876543214');
  const updated = await User.findById(owner.id);
  assert.equal(updated.phoneNumber, '9876543214');
  assert.equal(updated.phoneVerification, undefined);
});

test('login and phone change codes cannot be used in each other\'s flow', async (t) => {
  t.after(fakeTwilio());
  const user = await User.create({ firstname: 'Cross', lastname: 'Flow', email: 'cross@example.invalid', phoneNumber: '9876543215' });

  // Phone-change binding on a number this user already owns must not log anyone in.
  await invoke(requestSessionMobileOtp, { phoneNumber: '9876543215' }, { id: user.id });
  let before = calls.length;
  assert.equal((await invoke(verifyMobileOtp, { phoneNumber: '9876543215', otp: CODE })).statusCode, 400);
  assert.equal(calls.length, before, 'rejected before Twilio is asked');

  // A login binding must not complete a phone change.
  await User.updateOne({ _id: user._id }, { $unset: { phoneVerification: 1 } });
  await invoke(requestMobileOtp, { phoneNumber: '9876543215' });
  before = calls.length;
  assert.equal((await invoke(verifySessionMobileOtp, { phoneNumber: '9876543215', otp: CODE }, { id: user.id })).statusCode, 400);
  assert.equal(calls.length, before);

  // Separate Verify service for phone changes, when configured.
  process.env.TWILIO_VERIFY_PHONE_CHANGE_SERVICE_SID = 'VAphonechange';
  await invoke(requestSessionMobileOtp, { phoneNumber: '9876543216' }, { id: user.id });
  assert.equal(calls.at(-1).url, 'https://verify.twilio.com/v2/Services/VAphonechange/Verifications');
});

test('Twilio approval for a different verification or number is rejected', async (t) => {
  await User.create({ firstname: 'Sid', lastname: 'Check', email: 'sid@example.invalid', phoneNumber: '9876543217' });
  t.after(fakeTwilio());
  await invoke(requestMobileOtp, { phoneNumber: '9876543217' });
  t.after(setTwilioFetch(async () => ({ status: 200, ok: true, json: async () => ({ sid: 'VEsomethingElse', to: '+919876543217', status: 'approved', valid: true }) })));
  assert.equal((await invoke(verifyMobileOtp, { phoneNumber: '9876543217', otp: CODE })).statusCode, 400);
  t.after(setTwilioFetch(async () => ({ status: 404, ok: false, json: async () => ({ code: 20404 }) })));
  assert.equal((await invoke(verifyMobileOtp, { phoneNumber: '9876543217', otp: CODE })).statusCode, 400, 'expired at Twilio');
  t.after(setTwilioFetch(async () => ({ status: 500, ok: false, json: async () => ({}) })));
  const failed = await invoke(verifyMobileOtp, { phoneNumber: '9876543217', otp: CODE });
  assert.equal(failed.statusCode, 502);
  assert.equal(failed.body.code, 'OTP_VERIFY_FAILED');
});

test('development fallback: SMS_PROVIDER=local returns a test code without calling Twilio', async () => {
  process.env.NODE_ENV = 'development';
  process.env.SMS_PROVIDER = 'local';
  const sent = await invoke(requestMobileOtp, { phoneNumber: '9876543218' });
  assert.equal(sent.statusCode, 200);
  assert.match(sent.body.data.otp, /^\d{6}$/);
  assert.equal(calls.length, 0);
  assert.equal((await User.findOne({ phoneNumber: '9876543218' })).phoneVerification.codeHash.length, 64);
  assert.equal((await invoke(verifyMobileOtp, { phoneNumber: '9876543218', otp: sent.body.data.otp })).body.code, 'LOGIN_SUCCESS');
});
