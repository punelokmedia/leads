import '../src/Config/env.config.js';
import mongoose from 'mongoose';
import { connectDB } from '../src/Config/db.connection.config.js';
import { Notification, NotificationDevice, NotificationPreference, NotificationReceipt } from '../src/Models/notification.model.js';

try {
  await connectDB();
  // Explicitly create additive indexes, even when autoIndex is disabled.
  for (const model of [Notification, NotificationDevice, NotificationPreference, NotificationReceipt]) await model.createIndexes();
  console.log('Notification indexes ready.');
} catch (error) {
  console.error('Notification index initialization failed:', error.name);
  process.exitCode = 1;
} finally {
  await mongoose.disconnect();
}
