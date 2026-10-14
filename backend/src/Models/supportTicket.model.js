import mongoose from 'mongoose';
export const SUPPORT_ISSUES = ['PAYMENT', 'WALLET', 'LEAD_QUALITY', 'DOWNLOAD', 'MEMBERSHIP', 'REFERRAL', 'ACCOUNT', 'OTHER'];
export const SUPPORT_STATUSES = ['PENDING', 'ACTION_TAKEN', 'COMPLETED'];
const schema = new mongoose.Schema({
  ticketId: { type: String, required: true, unique: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  clientId: { type: String, required: true, maxlength: 100 },
  issue: { type: String, enum: SUPPORT_ISSUES, required: true },
  description: { type: String, required: true, maxlength: 2000 },
  status: { type: String, enum: SUPPORT_STATUSES, default: 'PENDING' },
  humanRequestedAt: { type: Date, default: null },
  humanReplyAt: { type: Date, default: null },
  statusHistory: [{ _id: false, status: { type: String, enum: SUPPORT_STATUSES }, actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, at: Date }],
}, { timestamps: true });
schema.index({ user: 1, clientId: 1 }, { unique: true });
schema.index({ user: 1, _id: -1 });
schema.index({ status: 1, _id: -1 });
export const SupportTicket = mongoose.model('SupportTicket', schema);
