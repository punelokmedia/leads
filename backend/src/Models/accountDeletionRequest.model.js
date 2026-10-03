import mongoose from 'mongoose';

const schema = new mongoose.Schema({
  email: { type: String, required: true, trim: true, lowercase: true, maxlength: 254 },
  phoneNumber: { type: String, required: true, maxlength: 16 },
  reason: { type: String, trim: true, maxlength: 2000, default: '' },
  status: { type: String, enum: ['pending', 'verified', 'completed', 'rejected'], default: 'pending' },
}, { timestamps: true });
schema.index({ status: 1, createdAt: -1 });

export const AccountDeletionRequest = mongoose.model('AccountDeletionRequest', schema);
