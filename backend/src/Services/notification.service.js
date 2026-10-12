import { Notification, NotificationPreference } from '../Models/notification.model.js';
import { User } from '../Models/user.model.js';
import { Lead } from '../Models/leads.model.js';

// Called inside the business transaction for financial events: inbox writes
// commit with the payment, never before payment verification or after a rollback.
export async function notifyUser({ user, eventKey, type, title, message, targetId }, session = null) {
  const account = await User.findOne({ _id: user, isBlocked: { $ne: true } }).select('_id').session(session);
  if (!account) return null;
  const preference = await NotificationPreference.findOne({ user }).session(session).lean();
  if ((type === 'NEW_LEAD' && preference?.newLeads === false) || (type === 'ANNOUNCEMENT' && preference?.announcements === false)) return null;
  try {
    return await Notification.findOneAndUpdate({ user, eventKey }, { $setOnInsert: { user, eventKey, type, title, message, targetId } }, { upsert: true, returnDocument: 'after', runValidators: true, session });
  } catch (error) {
    // Transaction conflicts must propagate so MongoDB can retry the transaction.
    if (error.code !== 11000 || session) throw error;
    return Notification.findOne({ user, eventKey });
  }
}

const exactText = value => new RegExp(`^${value.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i');
export async function notifyNewLead(lead) {
  if (lead.status !== 'ACTIVE' || lead.expiresAt <= new Date() || lead.buyersCount >= 2) return;
  const users = User.find({ role: 'USER', isBlocked: { $ne: true }, categories: lead.category,
    city: exactText(lead.city), state: exactText(lead.state),
  }).select('_id').cursor();
  for await (const user of users) await notifyUser({ user: user._id, eventKey: `lead:${lead._id}`, type: 'NEW_LEAD',
    title: 'New lead available', message: `A new lead is available in ${lead.city}.`, targetId: lead._id });
}

// Reconcile persisted leads in bounded batches. A checkpoint advances only after
// fanout succeeds; unique event keys make interrupted/concurrent runs safe.
export async function reconcileLeadNotifications({ after, limit = 50 } = {}) {
  const leads = await Lead.find({ ...(after ? { _id: { $gt: after } } : {}), status: 'ACTIVE', expiresAt: { $gt: new Date() }, buyersCount: { $lt: 2 } }).sort({ _id: 1 }).limit(limit);
  for (const lead of leads) await notifyNewLead(lead);
  return { processed: leads.length, next: leads.at(-1)?._id || after || null };
}
