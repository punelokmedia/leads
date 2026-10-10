import { User } from '../Models/user.model.js';
export async function inspectPhoneIndexReadiness(collection = User.collection) {
  const duplicates = await collection.aggregate([
    { $match: { phoneNumber: { $type: 'string', $gt: '' } } },
    { $project: { phoneNumber: { $trim: { input: '$phoneNumber' } } } },
    { $match: { phoneNumber: { $gt: '' } } },
    { $group: { _id: '$phoneNumber', count: { $sum: 1 } } },
    { $match: { count: { $gt: 1 } } },
    { $project: { _id: 0, count: 1 } },
  ]).toArray();
  const emptyPhones = await collection.countDocuments({ phoneNumber: { $type: 'string', $regex: '^\\s*$' } });
  return { duplicateGroups: duplicates.length, duplicateDocuments: duplicates.reduce((sum, entry) => sum + entry.count, 0), emptyPhones };
}
