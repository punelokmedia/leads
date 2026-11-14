import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import router from '../src/Routes/home-banner.routes.js';
import { User } from '../src/Models/user.model.js';
import { readFile } from 'node:fs/promises';

test('server banners expose defaults, restrict uploads and refresh versioned images without app changes', async () => {
  process.env.JWT_SECRET = 'banner-test-secret';
  const mongo = await MongoMemoryServer.create({ binary: { version: '7.0.24' } });
  let server;
  try {
    await mongoose.connect(mongo.getUri());
    const admin = new mongoose.Types.ObjectId(), member = new mongoose.Types.ObjectId();
    await User.collection.insertMany([{ _id: admin, role: 'ADMIN', email: 'banner-admin@example.com', phoneNumber: '9876543210' }, { _id: member, role: 'USER', email: 'banner-member@example.com', phoneNumber: '9876543211' }]);
    const token = id => jwt.sign({ id, mfa: true }, process.env.JWT_SECRET);
    const app = express();
    app.use('/api/v1/banners', router);
    server = app.listen(0, '127.0.0.1');
    await new Promise(resolve => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    const manifest = async () => {
      const response = await fetch(`${base}/api/v1/banners/home`);
      assert.equal(response.status, 200);
      assert.equal(response.headers.get('cache-control'), 'no-store');
      return (await response.json()).data;
    };
    const first = await manifest();
    assert.deepEqual(first.map(row => row.id), ['business', 'membership']);
    assert.deepEqual(first.map(row => row.target), ['leads', 'membership']);
    const image = await fetch(base + first[0].imageUrl);
    const original = await readFile(new URL('../public/home-banners/business.png', import.meta.url));
    assert.equal(image.headers.get('content-type'), 'image/png');
    assert.deepEqual(Buffer.from(await image.arrayBuffer()), original);
    const conditional = await fetch(base + first[0].imageUrl, { headers: { 'If-None-Match': `"${first[0].version}"` } });
    assert.equal(conditional.status, 304);
    const newImage = await readFile(new URL('../public/home-banners/membership.webp', import.meta.url));
    const upload = async (authorization, bytes = newImage, filename = 'new.webp') => {
      const body = new FormData();
      body.append('image', new Blob([bytes]), filename);
      body.append('title', 'Updated server campaign');
      return fetch(`${base}/api/v1/banners/home/business`, { method: 'PUT', headers: authorization ? { Authorization: `Bearer ${authorization}` } : {}, body });
    };
    assert.equal((await upload()).status, 401);
    assert.equal((await upload(token(member))).status, 403);
    assert.equal((await upload(token(admin), Buffer.from('<svg/>'), 'bad.svg')).status, 400);
    assert.equal((await upload(token(admin))).status, 200);
    const second = await manifest();
    assert.notEqual(second[0].imageUrl, first[0].imageUrl);
    assert.equal(second[0].title, 'Updated server campaign');
    assert.equal(second[1].version, first[1].version);
    const updated = await fetch(base + second[0].imageUrl);
    assert.equal(updated.headers.get('content-type'), 'image/webp');
    assert.deepEqual(Buffer.from(await updated.arrayBuffer()), newImage);
    assert.equal((await fetch(`${base}/api/v1/banners/home/unknown/image`)).status, 404);
  } finally {
    if (server) await new Promise(resolve => server.close(resolve));
    await mongoose.disconnect();
    await mongo.stop();
  }
});
