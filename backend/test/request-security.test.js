import test from 'node:test';
import assert from 'node:assert/strict';
import express from 'express';
import helmet from 'helmet';
import { requestSecurity, safeErrors } from '../src/Middlewares/request-security.js';
import { readLeadSpreadsheet } from '../src/Services/excel-import.js';
import ExcelJS from 'exceljs';
import JSZip from 'jszip';

test('HTTP guards reject Mongo operators, prototype paths, malformed and oversized bodies', async () => {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet(), express.json({ limit: '256kb' }), requestSecurity);
  app.post('/', (_req, res) => res.json({ success: true }));
  app.use(safeErrors);
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {
    const url = `http://127.0.0.1:${server.address().port}/`;
    for (const body of ['{"email":{"$ne":null}}', '{"nested":{"__proto__":{"admin":true}}}', '{"wallet.balance":100}', '{broken']) {
      const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body });
      assert.equal(res.status, 400);
      assert.equal(res.headers.get('x-powered-by'), null);
      assert.equal(res.headers.get('x-content-type-options'), 'nosniff');
      assert.doesNotMatch(await res.text(), /SyntaxError|stack|node_modules/);
    }
    const oversized = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ value: 'a'.repeat(270000) }) });
    assert.equal(oversized.status, 413);
    const valid = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{"email":"user@example.com"}' });
    assert.equal(valid.status, 200);
  } finally { await new Promise(resolve => server.close(resolve)); }
});

test('spreadsheet import rejects formulas, prototype headers, macros and archive expansion', async () => {
  for (const [header, value] of [['Price', { formula: '1+1', result: 2 }], ['__proto__', 'attack']]) {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Leads');
    sheet.addRow([header]); sheet.addRow([value]);
    await assert.rejects(readLeadSpreadsheet(Buffer.from(await workbook.xlsx.writeBuffer())));
  }
  const zip = new JSZip();
  zip.file('[Content_Types].xml', '<Types/>');
  zip.file('xl/workbook.xml', '<workbook/>');
  zip.file('xl/vbaProject.bin', 'macro');
  await assert.rejects(readLeadSpreadsheet(await zip.generateAsync({ type: 'nodebuffer' })));
  zip.remove('xl/vbaProject.bin');
  zip.file('xl/huge.xml', 'a'.repeat(11 * 1024 * 1024));
  await assert.rejects(readLeadSpreadsheet(await zip.generateAsync({ type: 'nodebuffer', compression: 'DEFLATE' })));
  await assert.rejects(readLeadSpreadsheet(Buffer.from('bad')));
});

test('ExcelJS compatible uuid override preserves conditional-format export', async () => {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Leads');
  sheet.addRow(['Price']); sheet.addRow([100]);
  sheet.addConditionalFormatting({ ref: 'A2', rules: [{ type: 'dataBar', minLength: 0, maxLength: 100, cfvo: [{ type: 'min' }, { type: 'max' }], color: { argb: 'FF00FF00' } }] });
  const buffer = await workbook.xlsx.writeBuffer();
  const read = new ExcelJS.Workbook();
  await read.xlsx.load(buffer);
  assert.equal(read.worksheets[0].getCell('A2').value, 100);
});
