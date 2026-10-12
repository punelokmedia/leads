import mongoose from 'mongoose';
const { Schema } = mongoose;
export const notificationTypes = ['NEW_LEAD', 'PAYMENT_SUCCESS', 'WALLET_CREDIT', 'REFUND_COMPLETED', 'MEMBERSHIP_ACTIVATED', 'SUPPORT_REPLY', 'ANNOUNCEMENT'];
const schema = new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  eventKey: { type: String, required: true, maxlength: 200 },
  type: { type: String, enum: notificationTypes, required: true },
  title: { type: String, required: true, maxlength: 150 },
  message: { type: String, required: true, maxlength: 1000 },
  targetId: { type: Schema.Types.ObjectId },
  readAt: { type: Date, default: null },
}, { timestamps: true });
schema.index({ user: 1, eventKey: 1 }, { unique: true });
schema.index({ user: 1, _id: -1 });
schema.index({ user: 1, readAt: 1 });
schema.index({ type: 1, _id: -1 });
export const Notification = mongoose.model('Notification', schema);

export const defaultPreferences = Object.freeze({ newLeads: true, announcements: true, push: false });
export const NotificationPreference = mongoose.model('NotificationPreference', new Schema({
  user: { type: Schema.Types.ObjectId, required: true, unique: true },
  newLeads: { type: Boolean, default: true },
  announcements: { type: Boolean, default: true },
  push: { type: Boolean, default: false },
}, { timestamps: true }));

const deviceSchema = new Schema({
  user: { type: Schema.Types.ObjectId, required: true, index: true },
  token: { type: String, required: true, maxlength: 4096, unique: true, select: false },
  platform: { type: String, enum: ['android', 'ios', 'web'], required: true },
  permission: { type: String, enum: ['granted'], required: true },
}, { timestamps: true });
export const NotificationDevice = mongoose.model('NotificationDevice', deviceSchema);

const receiptSchema = new Schema({
  notification: { type: Schema.Types.ObjectId, ref: 'Notification', required: true },
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  channel: { type: String, enum: ['mobile', 'web'], required: true },
  receivedAt: { type: Date, required: true },
});
receiptSchema.index({ notification: 1, channel: 1 }, { unique: true });
receiptSchema.index({ user: 1, receivedAt: -1 });
export const NotificationReceipt = mongoose.model('NotificationReceipt', receiptSchema);
