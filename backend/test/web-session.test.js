import test from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import { auth } from '../src/Middlewares/auth.middleware.js';
import { User } from '../src/Models/user.model.js';

process.env.JWT_SECRET = 'web-session-test-secret';
const user = { _id: 'test-user', role: 'USER', sessionVersion: 2 };
const token = (age, lifetime = 5 * 86400) => jwt.sign({ id: user._id, sv: 2, iat: Math.floor(Date.now() / 1000) - age }, process.env.JWT_SECRET, { expiresIn: lifetime });
const response = () => ({ headers: {}, statusCode: 200, set(key, value) { this.headers[key] = value; return this; }, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });
async function request(value, web = true) {
  const res = response(); let accepted = false;
  await auth({ header: name => name === 'Authorization' ? `Bearer ${value}` : web ? '1' : undefined }, res, () => { accepted = true; });
  return { res, accepted };
}

test('returning after one day renews web session for five days', async t => {
  t.mock.method(User, 'findById', async () => user);
  const { res, accepted } = await request(token(86400));
  assert.equal(accepted, true);
  const renewed = jwt.verify(res.headers['X-Session-Token'], process.env.JWT_SECRET);
  assert.equal(renewed.exp - renewed.iat, 5 * 86400);
  assert.equal(renewed.sv, 2);
  assert.equal(res.headers['Cache-Control'], 'no-store');
});
test('five inactive days reject before database access', async t => {
  t.mock.method(User, 'findById', () => assert.fail('expired token must not access database'));
  const { res, accepted } = await request(token(5 * 86400 + 1));
  assert.equal(accepted, false);
  assert.equal(res.statusCode, 401);
  assert.equal(res.body.code, 'SESSION_EXPIRED');
});
test('revoked sessions cannot renew', async t => {
  t.mock.method(User, 'findById', async () => ({ ...user, sessionVersion: 3 }));
  const { res } = await request(token(86400));
  assert.equal(res.body.code, 'SESSION_REVOKED');
  assert.equal(res.headers['X-Session-Token'], undefined);
});
test('database failure is unavailable rather than expired', async t => {
  t.mock.method(User, 'findById', async () => { throw new Error('test database unavailable'); });
  const { res } = await request(token(86400));
  assert.equal(res.statusCode, 503);
  assert.equal(res.body.code, 'AUTH_UNAVAILABLE');
});
test('legacy web tokens migrate but mobile and admin are not renewed', async t => {
  t.mock.method(User, 'findById', async () => user);
  assert.ok((await request(token(0, 7 * 86400))).res.headers['X-Session-Token']);
  assert.equal((await request(token(86400), false)).res.headers['X-Session-Token'], undefined);
  t.mock.method(User, 'findById', async () => ({ ...user, role: 'ADMIN' }));
  assert.equal((await request(token(86400))).res.headers['X-Session-Token'], undefined);
});
test('recently renewed tokens do not trigger a render renewal loop', async t => {
  t.mock.method(User, 'findById', async () => user);
  assert.equal((await request(token(0))).res.headers['X-Session-Token'], undefined);
});
