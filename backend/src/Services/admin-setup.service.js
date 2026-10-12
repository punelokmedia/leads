import { User } from '../Models/user.model.js';
import { hashPassword } from '../Utils/hash.js';

// Explicit setup operation only; never called by public login endpoints.
export async function setupAdmin({ email, password, firstname = 'Super', lastname = 'Admin', resetPassword = false }) {
  if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim()) || typeof password !== 'string' || !password.trim()) {
    throw new Error('ADMIN_EMAIL and a non-empty ADMIN_PASSWORD are required.');
  }
  const normalizedEmail = email.trim().toLowerCase();
  const literalEmail = normalizedEmail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const existing = await User.findOne({ email: { $regex: `^${literalEmail}$`, $options: 'i' } });
  if (existing) {
    if (existing.role !== 'ADMIN') throw new Error('Account exists without ADMIN role. Use the authorized admin promotion workflow first.');
    if (existing.password && !resetPassword) return { status: 'EXISTS' };
    const result = await User.updateOne({ _id: existing._id, role: 'ADMIN', ...(resetPassword ? { password: existing.password ?? null } : { $or: [{ password: null }, { password: '' }] }) }, {
      $set: { password: await hashPassword(password), resetOtp: null, resetOtpExpire: null },
      $inc: { sessionVersion: 1 }, $addToSet: { providers: 'LOCAL' },
    });
    if (resetPassword && !result.modifiedCount) throw new Error('Account changed during password reset. Recheck the target account before retrying.');
    return { status: result.modifiedCount ? (resetPassword ? 'PASSWORD_RESET' : 'PASSWORD_INITIALIZED') : 'EXISTS' };
  }
  await User.create({ firstname, lastname, email: normalizedEmail, password: await hashPassword(password), role: 'ADMIN', providers: ['LOCAL'] });
  return { status: 'CREATED' };
}
