import 'dotenv/config';
import mongoose from 'mongoose';
import { readFileSync } from 'node:fs';
import { Category } from '../Models/category.model.js';

const catalog = JSON.parse(readFileSync(new URL('./data/categories.json', import.meta.url)));
const apply = process.argv.includes('--apply');
try {
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  await mongoose.connect(process.env.DATABASE_URL, { serverSelectionTimeoutMS: 15000 });
  let added = 0;
  for (const item of catalog) {
    const escaped = item.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const existing = await Category.findOne({ name: new RegExp(`^${escaped}$`, 'i') });
    if (existing) continue;
    console.log(`${apply ? 'Adding' : 'Would add'}: ${item.displayName}`);
    if (apply) await Category.updateOne({ name: item.name }, { $setOnInsert: item }, { upsert: true });
    added++;
  }
  console.log(JSON.stringify({ applied: apply, catalog: catalog.length, missing: added, database: mongoose.connection.name }));
} catch (error) {
  console.error('Category import failed:', error.name);
  process.exitCode = 1;
} finally {
  await mongoose.disconnect();
}
