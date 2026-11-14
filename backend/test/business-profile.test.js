import test from 'node:test';
import assert from 'node:assert/strict';
process.env.RESEND_API_KEY = 're_test_only';
process.env.RAZORPAY_KEY_ID = 'test_key';
process.env.RAZORPAY_KEY_SECRET = 'test_secret';
const { updateUserProfile } = await import('../src/Controllers/auth.controller.js');
const { User } = await import('../src/Models/user.model.js');
const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });

test('business profile fields are persisted for the authenticated user', async (t) => {
  const fields = { businessName: 'Interior Co', businessType: 'Partnership', gstNumber: '27ABCDE1234F1Z5',
    businessAddress: '42 Park Road', serviceArea: 'Pune and nearby areas', yearsInBusiness: '3–5 years', website: 'https://example.com' };
  let saved;
  t.mock.method(User, 'findByIdAndUpdate', (id, update, options) => {
    assert.equal(id, 'authenticated-user');
    assert.equal(options.runValidators, true);
    saved = update.$set;
    return { select: async () => saved };
  });
  const res = response();
  await updateUserProfile({ user: { id: 'authenticated-user' }, body: { ...fields, role: 'ADMIN' } }, res);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(saved, fields);
  const model = new User(fields);
  for (const [key, value] of Object.entries(fields)) assert.equal(model[key], value);
});

test('invalid GSTIN and unsafe website schemes are rejected before saving', async (t) => {
  t.mock.method(User, 'findByIdAndUpdate', () => assert.fail('invalid fields must not be saved'));
  for (const body of [{ gstNumber: 'invalid' }, { website: 'javascript:alert(1)' }, { website: 'not-a-url' }]) {
    const res = response();
    await updateUserProfile({ user: { id: 'authenticated-user' }, body }, res);
    assert.equal(res.statusCode, 400);
  }
});

test('service category updates accept only arrays of IDs and deduplicate', async (t) => {
  const id = '507f1f77bcf86cd799439011';
  let saved;
  t.mock.method(User, 'findByIdAndUpdate', (_, update) => {
    saved = update.$set;
    return { select: async () => saved };
  });
  const res = response();
  await updateUserProfile({ user: { id: 'authenticated-user' }, body: { categories: [id, id] } }, res);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(saved, { categories: [id] });
  for (const categories of ['invalid', ['invalid'], [12], Array(101).fill(id)]) {
    const bad = response();
    await updateUserProfile({ user: { id: 'authenticated-user' }, body: { categories } }, bad);
    assert.equal(bad.statusCode, 400);
  }
});

test('location preferences validate radius and localities before saving', async (t) => {
  let saved;
  t.mock.method(User, 'findByIdAndUpdate', (_, update) => {
    saved = update.$set;
    return { select: async () => saved };
  });
  const res = response();
  await updateUserProfile({ user: { id: 'user' }, body: {
    city: 'Pune', serviceRadiusKm: 50, additionalAreas: [' Baner ', 'Baner', 'Wakad'],
  } }, res);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(saved, { city: 'Pune', serviceRadiusKm: 50, additionalAreas: ['Baner', 'Wakad'] });
  for (const body of [{ serviceRadiusKm: 99 }, { serviceRadiusKm: '25' },
    { additionalAreas: 'Baner' }, { additionalAreas: [''] }, { additionalAreas: ['a'.repeat(101)] }]) {
    const bad = response();
    await updateUserProfile({ user: { id: 'user' }, body }, bad);
    assert.equal(bad.statusCode, 400);
  }
});
