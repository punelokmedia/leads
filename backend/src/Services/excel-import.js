import ExcelJS from 'exceljs';
import JSZip from 'jszip';

export async function readLeadSpreadsheet(buffer) {
  const fail = () => { throw Object.assign(new Error('Invalid or oversized spreadsheet.'), { status: 400 }); };
  if (!Buffer.isBuffer(buffer) || buffer.length < 4 || buffer.length > 5 * 1024 * 1024 || buffer.readUInt32LE(0) !== 0x04034b50) fail();
  const zip = await JSZip.loadAsync(buffer);
  const entries = Object.values(zip.files).filter(entry => !entry.dir);
  if (entries.length > 200 || !zip.file('[Content_Types].xml') || !zip.file('xl/workbook.xml')) fail();
  let expanded = 0;
  for (const entry of entries) {
    const size = entry._data?.uncompressedSize;
    if (!Number.isSafeInteger(size) || size > 10 * 1024 * 1024) fail();
    expanded += size;
    if (expanded > 20 * 1024 * 1024 || /vbaProject|externalLinks/i.test(entry.name)) fail();
    const content = await entry.async('nodebuffer');
    if (content.length !== size || (entry.name.endsWith('.xml') && /<!DOCTYPE|<!ENTITY/i.test(content.toString('utf8')))) fail();
  }
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  const sheet = workbook.worksheets[0];
  if (!sheet || sheet.rowCount > 5001 || sheet.columnCount > 100) fail();
  const headers = [];
  sheet.getRow(1).eachCell((cell, column) => {
    const key = cell.text.trim();
    if (!key || key.length > 100 || ['__proto__', 'constructor', 'prototype'].includes(key) || key.startsWith('$') || key.includes('.') || headers.includes(key)) fail();
    headers[column] = key;
  });
  const rows = [];
  sheet.eachRow((row, index) => {
    if (index === 1) return;
    const data = Object.create(null);
    row.eachCell((cell, column) => {
      if (!headers[column]) return;
      if (cell.type === ExcelJS.ValueType.Formula || cell.text.length > 10000) fail();
      data[headers[column]] = cell.value instanceof Date ? cell.value : typeof cell.value === 'number' ? cell.value : cell.text;
    });
    if (Object.keys(data).length) rows.push(data);
  });
  return rows;
}
