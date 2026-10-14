import '../src/Config/env.config.js';
import mongoose from 'mongoose';
import { connectDB } from '../src/Config/db.connection.config.js';
import { SupportTicket } from '../src/Models/supportTicket.model.js';
import { SupportMessage } from '../src/Models/supportMessage.model.js';
try {
  await connectDB();
  for (const model of [SupportTicket, SupportMessage]) await model.createIndexes();
  console.log('Support ticket and message indexes ready.');
} catch (error) {
  console.error('Support index initialization failed:', error.name);
  process.exitCode = 1;
} finally { await mongoose.disconnect(); }
