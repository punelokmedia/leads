import { User } from '../Models/user.model.js';

export const referralCodeForId = (id) => `NL${id.toString().toUpperCase()}`;

export function normalizeReferralCode(value) {
  if (typeof value !== 'string') return null;
  const code = value.trim().toUpperCase();
  return /^NL[A-F0-9]{24}$/.test(code) ? code : null;
}

export async function ensureReferralCode(userId) {
  // Raw collection access avoids Mongoose defaults hiding a missing legacy field
  // and permits the one-time initialization of the immutable code.
  const users = User.collection;
  await users.updateOne(
    { _id: userId, $or: [{ referralCode: { $exists: false } }, { referralCode: null }] },
    { $set: { referralCode: referralCodeForId(userId) } },
  );
  const user = await users.findOne({ _id: userId }, { projection: { referralCode: 1 } });
  return user?.referralCode ?? null;
}

export async function findReferralOwner(code) {
  // Supports unbackfilled accounts without decoding a code into a mutable field.
  const userId = new User.base.Types.ObjectId(code.slice(2));
  const owner = await User.collection.findOne({
    isBlocked: { $ne: true }, role: 'USER',
    $or: [
      { referralCode: code },
      { _id: userId, $or: [{ referralCode: { $exists: false } }, { referralCode: null }] },
    ],
  }, { projection: { _id: 1 } });
  if (!owner) return null;
  await ensureReferralCode(owner._id);
  return owner._id;
}
