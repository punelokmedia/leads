import mongoose from 'mongoose';

const schema = new mongoose.Schema({
  referrer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  referredUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  code: { type: String, required: true },
  status: { type: String, enum: ['PENDING', 'QUALIFIED', 'REVIEW'], default: 'PENDING' },
  qualifyingOrder: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  qualifiedAt: Date,
}, { timestamps: true });
export const Referral = mongoose.model('Referral', schema);
