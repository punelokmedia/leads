import mongoose from 'mongoose';

const schema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  sender: { type: String, enum: ['user', 'support'], required: true },
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  text: { type: String, required: true, trim: true, maxlength: 2000 },
  clientId: { type: String, required: true, maxlength: 100 },
}, { timestamps: true });
schema.index({ user: 1, author: 1, clientId: 1 }, { unique: true });
schema.index({ user: 1, _id: -1 });
export const SupportMessage = mongoose.model('SupportMessage', schema);
