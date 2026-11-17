import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import express from 'express';
import jwt from 'jsonwebtoken';
import { MongoMemoryReplSet } from 'mongodb-memory-server';
import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs';
import { Order } from '../src/Models/orders.models.js';
import { User } from '../src/Models/user.model.js';
import { Lead } from '../src/Models/leads.model.js';
import { Category } from '../src/Models/category.model.js';
import { auth } from '../src/Middlewares/auth.middleware.js';
import { downloadReceipt, loadReceipt, renderReceipt } from '../src/Services/payment-receipt.js';

let mongo, server, base, user, token;
const oid = () => new mongoose.Types.ObjectId();
before(async () => {
  process.env.JWT_SECRET = 'receipt-test-only';
  mongo = await MongoMemoryReplSet.create({ replSet: { count: 1 }, binary: { version: '7.0.24' } });
  await mongoose.connect(mongo.getUri());
  assert.match(mongoose.connection.host, /^(127\.0\.0\.1|localhost)$/);
  user = await User.create({ firstname: 'Receipt', lastname: 'Test', email: 'receipt@example.invalid' });
  token = jwt.sign({ id: user.id }, process.env.JWT_SECRET);
  const app = express();
  app.get('/receipt/:orderId', auth, downloadReceipt);
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
}, { timeout: 300000 });
after(async () => { if (server) await new Promise(resolve => server.close(resolve)); await mongoose.disconnect(); if (mongo) await mongo.stop(); });

async function order(overrides = {}) {
  return Order.create({ user: user._id, leads: [{ lead: oid(), price: 499, quantity: 1, title: 'AC enquiry', categoryName: 'AC Service & Repair', serviceLocation: 'Kharadi, Pune' }], totalAmount: 499, currency: 'INR', status: 'PAID', paymentMethod: 'WALLET', paidAt: new Date('2026-11-17T10:39:21.762Z'), ...overrides });
}
const request = (id, credential = token) => fetch(`${base}/receipt/${id}`, { headers: credential ? { Authorization: `Bearer ${credential}` } : {} });
async function readPdf(bytes) {
  const loading = getDocument({ data: new Uint8Array(bytes), useSystemFonts: false });
  const pdf = await loading.promise;
  let text = '';
  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    assert.deepEqual(page.view.map(Math.round), [0, 0, 595, 842]);
    const content = await page.getTextContent();
    text += content.items.map(item => item.str).join(' ') + '\n';
    for (const item of content.items) if (item.str?.trim()) assert.ok(item.transform[5] >= 25 && item.transform[5] <= 817, `text outside page: ${item.str}`);
  }
  const pages = pdf.numPages;
  await loading.destroy();
  return { text, pages };
}

test('authenticated paid order returns A4 PDF with trusted data, INR and Indian date', async () => {
  const paid = await order();
  const response = await request(paid.id + '?amount=1&status=PAID');
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /application\/pdf/);
  assert.equal(response.headers.get('content-disposition'), `attachment; filename="NextLead_Receipt_${paid.id}.pdf"`);
  assert.match(response.headers.get('cache-control'), /no-store/);
  const bytes = Buffer.from(await response.arrayBuffer());
  assert.equal(bytes.subarray(0, 5).toString(), '%PDF-');
  const { text, pages } = await readPdf(bytes);
  assert.equal(pages, 1);
  for (const value of ['Payment Receipt', paid.id, `NL-${paid.id}`, 'AC Service & Repair', 'Kharadi, Pune', '₹ 499', '17 November 2026', 'NextLead Wallet']) assert.ok(text.includes(value), value);
  assert.ok(!text.includes('GST'));
});

test('missing authentication, another owner, invalid IDs and non-paid statuses cannot download', async () => {
  const paid = await order();
  assert.equal((await request(paid.id, null)).status, 401);
  const other = await order({ user: oid() });
  assert.equal((await request(other.id)).status, 404);
  assert.equal((await request('bad-id')).status, 400);
  for (const status of ['CREATED', 'RESERVED', 'PROCESSING', 'FAILED', 'CANCELLED', 'REFUND_PENDING', 'REFUNDED']) {
    const pending = await order({ status });
    assert.equal((await request(pending.id)).status, 409, status);
  }
});

test('repeat and concurrent downloads retain a single snapshot even after lead changes or deletion', async () => {
  const category = await Category.create({ name: `Plumbing-${oid()}` });
  const lead = await Lead.create({ title: 'Pipe replacement', category: category._id, city: 'Mumbai', state: 'Maharashtra', areaLocality: 'Andheri', description: 'Fixture', price: 150, createdBy: user._id, expiresAt: new Date('2099-01-01') });
  const paid = await order({ leads: [{ lead: lead._id, price: 150, quantity: 1 }], totalAmount: 150, paidAt: null, paymentMethod: 'RAZORPAY' });
  const [a, b] = await Promise.all([loadReceipt(paid.id, user.id), loadReceipt(paid.id, user.id)]);
  assert.deepEqual(a, b);
  assert.equal(a.items[0].title, 'Pipe replacement');
  await Lead.deleteOne({ _id: lead._id });
  assert.deepEqual(await loadReceipt(paid.id, user.id), a);
  const { text } = await readPdf(await renderReceipt(a));
  assert.match(text, /₹ 150/);
  assert.match(text, /Not provided/);
  assert.ok(!text.includes(user.email));
});

test('future categories, long titles and multi-line orders wrap and paginate', async () => {
  const paid = await order({ leads: Array.from({ length: 18 }, (_, i) => ({ lead: oid(), quantity: 1, price: 1234.5, title: `Project ${i}: ${'Long service description '.repeat(12)}`, categoryName: `New category ${i} ${'category '.repeat(9)}`, serviceLocation: 'Baner, Pune, Maharashtra' })), totalAmount: 22221 });
  const receipt = await loadReceipt(paid.id, user.id);
  const { text, pages } = await readPdf(await renderReceipt(receipt));
  assert.ok(pages > 1);
  assert.match(text, /Project 17:/);
  assert.match(text, /New category 17/);
  assert.match(text, /₹ 22,221/);
});
