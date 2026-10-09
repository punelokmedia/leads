import test from 'node:test';
import assert from 'node:assert/strict';
import XLSX from 'xlsx';
import { Category } from '../src/Models/category.model.js';
import { Lead } from '../src/Models/leads.model.js';
import { UploadLog } from '../src/Models/uploadLog.model.js';
import { uploadLeadsFromExcel } from '../src/Controllers/Admin/leads.controller.js';

test('bulk XLSX upload saves primary phone and normalized customer name, rejecting invalid phones', async (t) => {
  const categoryId = '507f1f77bcf86cd799439011';
  const row = {
    Title: 'Home interiors', Description: 'Full home interior project',
    Category: 'interior design', City: 'Pune', State: 'Maharashtra',
    'Customer Name': '  Sample Customer  ', 'Client Type': 'Individual',
    'Mobile Number (Primary)': '9876543210', 'Area / Locality': 'Baner',
    Requirement: 'Full interiors', 'Property Type': 'Apartment',
    'Budget Range': '5-8 lakh', Timeline: 'Within one month',
    Price: 100, 'Expires At': '2099-12-31',
  };
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet([
    row, { ...row, 'Mobile Number (Primary)': '123' },
  ]), 'Leads');
  const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
  t.mock.method(Category, 'find', async () => [{ _id: categoryId, name: 'interior design' }]);
  t.mock.method(UploadLog, 'create', async () => ({ _id: 'upload-test' }));
  let complete;
  const finished = new Promise(resolve => { complete = resolve; });
  const updates = [];
  t.mock.method(UploadLog, 'findByIdAndUpdate', async (_id, update) => {
    updates.push(update);
    if (update.status === 'completed') complete();
  });
  let inserted = [];
  t.mock.method(Lead, 'insertMany', async rows => {
    inserted = rows;
    // Exercise actual model validation before simulating successful persistence.
    for (const data of rows) await new Lead(data).validate();
    return rows;
  });
  const response = { statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };
  await uploadLeadsFromExcel({
    file: { buffer, originalname: 'leads.xlsx', mimetype: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' },
    user: { id: categoryId },
  }, response);
  assert.equal(response.statusCode, 202);
  assert.equal(response.body.totalRows, 2);
  await finished;
  assert.equal(inserted.length, 1);
  assert.equal(inserted[0].primaryPhone, '9876543210');
  assert.equal(inserted[0].phone, '9876543210');
  assert.equal(inserted[0].customerName, 'Sample Customer');
  const progress = updates.find(update => update.processedRows === 2);
  assert.equal(progress.successCount, 1);
  assert.equal(progress.failedCount, 1);
  assert.deepEqual(progress.$push.logs.$each, [{ row: 3, message: 'Invalid primary phone' }]);
}, { timeout: 10000 });
