import { ledgerSignature, SecurityAudit } from '../Services/security-audit.js';
import mongoose from 'mongoose';
const { Schema } = mongoose;
const entrySchema = new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  key: { type: String, required: true, unique: true },
  kind: { type: String, enum: ['TOPUP', 'REFERRAL', 'LEAD', 'MEMBERSHIP', 'REVERSAL'], required: true },
  signature: { type: String, select: false },
  amountPaise: { type: Number, required: true, validate: Number.isSafeInteger },
}, { timestamps: true });
entrySchema.pre('save', function () {
  if (!this.isNew) throw new Error('Ledger entries are append-only');
  this.signature = ledgerSignature(this);
});
entrySchema.pre('insertMany', function () { throw new Error('Use audited ledger creation'); });
entrySchema.pre('bulkWrite', function () { throw new Error('Ledger entries are append-only'); });
for (const operation of ['updateOne', 'updateMany', 'findOneAndUpdate', 'replaceOne', 'findOneAndReplace', 'deleteOne', 'deleteMany', 'findOneAndDelete']) entrySchema.pre(operation, function () { throw new Error('Ledger entries are append-only'); });
entrySchema.post('save', async function (doc) {
  await SecurityAudit.updateOne({ eventKey: 'ledger:' + doc.id }, { $setOnInsert: { event: 'WALLET_' + doc.kind, subject: String(doc.user), detail: { entryId: doc.id, key: doc.key, amountPaise: doc.amountPaise, signature: doc.signature } } }, { upsert: true, session: doc.$session() });
});
export const WalletEntry = mongoose.model('WalletEntry', entrySchema);
export const WalletTopup = mongoose.model('WalletTopup', new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  amountPaise: { type: Number, required: true, min: 100, max: 1000000, validate: Number.isSafeInteger },
  gatewayOrderId: { type: String, unique: true, sparse: true },
  paymentId: { type: String, unique: true, sparse: true },
  reversedPaise: { type: Number, default: 0 },
  disputed: { type: Boolean, default: false },
  status: { type: String, enum: ['CREATED', 'PAID'], default: 'CREATED' },
}, { timestamps: true }));
