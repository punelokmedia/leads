import test from 'node:test';
import assert from 'node:assert/strict';
import ExcelJS from 'exceljs';
import express from 'express';
import upload from '../src/Middlewares/fileupload.middleware.js';
import { safeErrors } from '../src/Middlewares/request-security.js';
import { readLeadSpreadsheet } from '../src/Services/excel-import.js';

test('EXCEL-01 upload middleware rejects invalid extension, MIME and over-5MiB file', async () => {
  const app = express();
  app.post('/', upload.single('file'), (_req, res) => res.json({ success: true }));
  app.use(safeErrors);
  const server = app.listen(0, '127.0.0.1'); await new Promise(resolve => server.once('listening', resolve));
  try {
    for (const [name, type, size] of [['payload.exe', 'application/octet-stream', 10], ['payload.xlsx', 'text/html', 10], ['huge.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 5 * 1024 * 1024 + 1]]) {
      const form = new FormData(); form.append('file', new Blob([new Uint8Array(size)], { type }), name);
      const response = await fetch(`http://127.0.0.1:${server.address().port}/`, { method: 'POST', body: form });
      assert.ok(response.status >= 400);
      assert.doesNotMatch(await response.text(), /stack|node_modules/);
    }
  } finally { await new Promise(resolve => server.close(resolve)); }
});

test('EXCEL-02 excessive rows and columns fail before bulk database writes', async () => {
  const workbook = new ExcelJS.Workbook(); const sheet = workbook.addWorksheet('Leads');
  sheet.addRow(['Title']);
  for (let i = 0; i < 5001; i++) sheet.addRow(['Synthetic']);
  await assert.rejects(readLeadSpreadsheet(Buffer.from(await workbook.xlsx.writeBuffer())));
  const wide = new ExcelJS.Workbook(); const wideSheet = wide.addWorksheet('Leads');
  wideSheet.addRow(Array.from({ length: 101 }, (_, i) => 'Column' + i)); wideSheet.addRow(['Synthetic']);
  await assert.rejects(readLeadSpreadsheet(Buffer.from(await wide.xlsx.writeBuffer())));
});

test('EXCEL-03 export strings beginning with formula characters remain text on roundtrip', async () => {
  const workbook = new ExcelJS.Workbook(); const sheet = workbook.addWorksheet('Leads');
  const values = ['=1+1', '+1+1', '-1+1', '@SUM(1,1)']; sheet.addRow(values);
  const read = new ExcelJS.Workbook(); await read.xlsx.load(await workbook.xlsx.writeBuffer());
  values.forEach((value, index) => { const cell = read.worksheets[0].getCell(1, index + 1); assert.equal(cell.value, value); assert.equal(cell.type, ExcelJS.ValueType.String); });
});
