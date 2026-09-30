import mongoose from 'mongoose';

const schema = new mongoose.Schema({
  paymentId: { type: String, required: true, unique: true },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
  amount: { type: Number, required: true }, // paise, always the full captured payment
  status: { type: String, enum: ['PENDING', 'PROCESSING', 'SUBMITTED', 'REFUNDED'], default: 'PENDING', index: true },
  refundId: String,
  lockedUntil: Date,
  nextAttemptAt: { type: Date, default: Date.now },
  attempts: { type: Number, default: 0 },
  lastError: String,
}, { timestamps: true });

export const PaymentRefund = mongoose.model('PaymentRefund', schema);
