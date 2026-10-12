import '../Config/env.config.js';
import mongoose from 'mongoose';
import { connectDB } from '../Config/db.connection.config.js';
import { setupAdmin } from '../Services/admin-setup.service.js';

try {
  if (!process.env.ADMIN_EMAIL || !process.env.ADMIN_PASSWORD) throw new Error('ADMIN_EMAIL and ADMIN_PASSWORD are required.');
  await connectDB();
  const result = await setupAdmin({ email: process.env.ADMIN_EMAIL, password: process.env.ADMIN_PASSWORD,
    firstname: process.env.ADMIN_FIRSTNAME || 'Super', lastname: process.env.ADMIN_LASTNAME || 'Admin' });
  const messages = {
    CREATED: 'Admin account created with a password.',
    PASSWORD_INITIALIZED: 'Existing admin password initialized. Previous sessions and OTPs revoked. Request a fresh OTP.',
    EXISTS: 'Admin already has a password. Existing password preserved; ADMIN_PASSWORD does not replace it. Use the password reset workflow if needed.',
  };
  console.log(messages[result.status]);
} catch (error) {
  console.error('Admin setup failed:', error.message);
  process.exitCode = 1;
} finally {
  await mongoose.disconnect();
}
