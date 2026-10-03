import test from 'node:test';
import assert from 'node:assert/strict';
import { requestAccountDeletion } from '../src/Controllers/accountDeletion.controller.js';
import { AccountDeletionRequest } from '../src/Models/accountDeletionRequest.model.js';

const response = () => ({ statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });

test('rejects invalid contact details and non-string inputs before saving', async (t) => {
  t.mock.method(AccountDeletionRequest, 'create', () => assert.fail('Invalid requests must not be saved'));
  for (const body of [undefined, {}, { email: { $ne: null }, phoneNumber: '9876543210' },
    { email: 'bad', phoneNumber: '9876543210' }, { email: 'user@example.com', phoneNumber: '123' },
    { email: 'user@example.com', phoneNumber: '9876543210', reason: 'x'.repeat(2001) },
    { email: 'user@example.com', phoneNumber: '9876543210', reason: {} }]) {
    const res = response();
    await requestAccountDeletion({ body }, res);
    assert.equal(res.statusCode, 400);
  }
});

test('saves normalized contact details and reason without accepting a client-supplied status', async (t) => {
  let saved;
  t.mock.method(AccountDeletionRequest, 'create', async (values) => { saved = values; return { id: 'request-123' }; });
  const res = response();
  await requestAccountDeletion({ body: { email: ' USER@Example.com ', phoneNumber: '+91 (98765) 43210', reason: ' Leaving ', status: 'completed' } }, res);
  assert.deepEqual(saved, { email: 'user@example.com', phoneNumber: '+919876543210', reason: 'Leaving' });
  assert.equal(res.statusCode, 201);
  assert.equal(res.body.requestId, 'request-123');
  const document = new AccountDeletionRequest(saved);
  assert.equal(document.status, 'pending');
  assert.equal(document.validateSync(), undefined);
});

test('allows submitting without a reason', async (t) => {
  t.mock.method(AccountDeletionRequest, 'create', async (values) => { assert.equal(values.reason, ''); return { id: 'request-456' }; });
  const res = response();
  await requestAccountDeletion({ body: { email: 'user@example.com', phoneNumber: '9876543210' } }, res);
  assert.equal(res.statusCode, 201);
});

test('does not claim success when saving fails or expose database errors', async (t) => {
  t.mock.method(AccountDeletionRequest, 'create', async () => { throw new Error('private database details'); });
  const res = response();
  await requestAccountDeletion({ body: { email: 'user@example.com', phoneNumber: '9876543210' } }, res);
  assert.equal(res.statusCode, 503);
  assert.equal(res.body.success, false);
  assert.ok(!res.body.message.includes('private'));
});
