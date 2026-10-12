import '../src/Config/env.config.js';
import mongoose from 'mongoose';
import { connectDB } from '../src/Config/db.connection.config.js';
import { Notification, NotificationDevice, NotificationPreference } from '../src/Models/notification.model.js';
import { reconcileLeadNotifications } from '../src/Services/notification.service.js';

try {
  await connectDB();
  await Promise.all([Notification.init(), NotificationDevice.init(), NotificationPreference.init()]);
  let after;
  let processed = 0;
  for (;;) {
    const batch = await reconcileLeadNotifications({ after });
    processed += batch.processed;
    if (!batch.processed) break;
    after = batch.next;
  }
  console.log(`Reconciled ${processed} active leads. Existing notifications were preserved.`);
} catch (error) {
  console.error('Notification reconciliation failed:', error.name);
  process.exitCode = 1;
} finally {
  await mongoose.disconnect();
}
