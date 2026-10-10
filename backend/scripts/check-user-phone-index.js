import mongoose from 'mongoose';
import { inspectPhoneIndexReadiness } from '../src/Services/user-index-readiness.js';
const uri = process.argv[process.argv.indexOf('--uri') + 1];
if (!process.argv.includes('--uri') || !/^mongodb:\/\/(127\.0\.0\.1|localhost)(:\d+)?\//.test(uri)) throw new Error('Supply an explicit disposable/local MongoDB URI with --uri. No environment database is used.');
await mongoose.connect(uri, { autoIndex: false, autoCreate: false });
try { const result = await inspectPhoneIndexReadiness(); console.log(JSON.stringify(result)); if (result.duplicateGroups) process.exitCode = 1; }
finally { await mongoose.disconnect(); }
