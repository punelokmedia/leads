import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import cookieParser from 'cookie-parser';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { User } from '../src/Models/user.model.js';
import { referralRouter } from '../src/Routes/referral.routes.js';

let mongo, server, base, users, tokens;
before(async () => {
  process.env.JWT_SECRET = 'referral-test-secret';
  // Test the new index independently of unrelated existing user indexes.
  User.schema.set('autoIndex', false);
  mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  await User.collection.createIndex({ referralCode: 1 }, {
    unique: true, partialFilterExpression: { referralCode: { $type: 'string' } },
  });
  users = await User.create([0, 1, 2].map(i => ({ firstname: 'Referral', lastname: 'Test', email: `referral${i}@example.invalid` })));
  tokens = users.map(user => jwt.sign({ id: user.id }, process.env.JWT_SECRET));
  const app = express();
  app.use(express.json());
  app.use(cookieParser());
  app.use('/referrals', referralRouter);
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}/referrals`;
}, { timeout: 900000 });
after(async () => {
  if (server) await new Promise(resolve => server.close(resolve));
  await mongoose.disconnect();
  if (mongo) await mongo.stop();
});

async function call(path, user = 0, body, cookie = false) {
  const response = await fetch(base + path, {
    method: body ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json', ...(user == null ? {} : cookie
      ? { Cookie: `token=${tokens[user]}` } : { Authorization: `Bearer ${tokens[user]}` }) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: response.status, ...(await response.json()) };
}

test('new users get distinct persisted immutable codes enforced by a unique index', async () => {
  assert.equal(new Set(users.map(u => u.referralCode)).size, users.length);
  for (const user of users) assert.match(user.referralCode, /^NL[A-F0-9]{24}$/);
  const original = users[0].referralCode;
  users[0].referralCode = users[1].referralCode;
  await users[0].save();
  assert.equal((await User.findById(users[0]._id)).referralCode, original);
  await assert.rejects(User.collection.updateOne({ _id: users[1]._id }, { $set: { referralCode: original } }), { code: 11000 });
});

test('legacy users get one stable code across concurrent requests', async () => {
  await User.collection.updateOne({ _id: users[0]._id }, { $unset: { referralCode: '' } });
  const responses = await Promise.all(Array.from({ length: 6 }, () => call('/me')));
  assert.ok(responses.every(r => r.status === 200));
  assert.equal(new Set(responses.map(r => r.data.referralCode)).size, 1);
  const stored = await User.collection.findOne({ _id: users[0]._id });
  assert.equal(stored.referralCode, responses[0].data.referralCode);
});

test('shared API requires authentication and validates normalized codes without exposing users', async () => {
  assert.equal((await call('/me', null)).status, 401);
  const ownCode = (await call('/me')).data.referralCode;
  const web = await call('/me', 0, undefined, true);
  assert.equal(web.status, 200);
  assert.equal(web.data.referralCode, ownCode);
  assert.equal((await call('/validate', 0, { referralCode: ownCode })).status, 400);
  const valid = await call('/validate', 1, { referralCode: ` ${ownCode.toLowerCase()} ` });
  assert.equal(valid.status, 200);
  assert.deepEqual(valid.data, { referralCode: ownCode, valid: true });
  assert.equal((await call('/validate', 1, { referralCode: { bad: 'input' } })).status, 400);
  assert.equal((await call('/validate', 1, { referralCode: `NL${new mongoose.Types.ObjectId().toString().toUpperCase()}` })).status, 404);
  await User.collection.updateOne({ _id: users[2]._id }, { $unset: { referralCode: '' } });
  assert.equal((await call('/validate', 1, { referralCode: users[2].referralCode })).status, 200);
  assert.equal((await User.collection.findOne({ _id: users[2]._id })).referralCode, users[2].referralCode);
  await User.updateOne({ _id: users[2]._id }, { $set: { isBlocked: true } });
  assert.equal((await call('/validate', 1, { referralCode: users[2].referralCode })).status, 404);
});
