import { test } from 'node:test';
import assert from 'node:assert/strict';
import { deleteCategory } from '../src/Controllers/Admin/category.controller.js';
import { Category } from '../src/Models/category.model.js';
import { Lead } from '../src/Models/leads.model.js';

const categoryId = '507f1f77bcf86cd799439011';
function response() {
  return {
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
}

test('admin category deletion removes only its leads before removing the category', async (t) => {
  const order = [];
  t.mock.method(Category, 'findById', async () => ({ _id: categoryId }));
  const leads = t.mock.method(Lead, 'deleteMany', async () => {
    order.push('leads');
    return { deletedCount: 3 };
  });
  const category = t.mock.method(Category, 'findByIdAndDelete', async () => {
    order.push('category');
    return { _id: categoryId };
  });
  const res = response();
  await deleteCategory({ body: { categoryId } }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.deletedLeadsCount, 3);
  assert.deepEqual(leads.mock.calls[0].arguments, [{ category: categoryId }]);
  assert.deepEqual(category.mock.calls[0].arguments, [categoryId]);
  assert.deepEqual(order, ['leads', 'category']);
});

test('empty categories can also be deleted', async (t) => {
  t.mock.method(Category, 'findById', async () => ({ _id: categoryId }));
  t.mock.method(Lead, 'deleteMany', async () => ({ deletedCount: 0 }));
  const deleted = t.mock.method(Category, 'findByIdAndDelete', async () => ({}));
  const res = response();
  await deleteCategory({ body: { categoryId } }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.data.deletedLeadsCount, 0);
  assert.equal(deleted.mock.callCount(), 1);
});

test('missing categories cannot trigger lead deletion', async (t) => {
  t.mock.method(Category, 'findById', async () => null);
  const leads = t.mock.method(Lead, 'deleteMany', async () => ({}));
  const category = t.mock.method(Category, 'findByIdAndDelete', async () => ({}));
  const res = response();
  await deleteCategory({ body: { categoryId } }, res);
  assert.equal(res.statusCode, 404);
  assert.equal(leads.mock.callCount(), 0);
  assert.equal(category.mock.callCount(), 0);
});
