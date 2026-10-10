import mongoose from 'mongoose';
export const OAuthHandoff = mongoose.model('OAuthHandoff', new mongoose.Schema({
  codeHash: { type: String, unique: true, required: true },
  challenge: { type: String, required: true },
  user: { type: mongoose.Schema.Types.ObjectId, required: true },
  sessionVersion: { type: Number, required: true },
  expiresAt: { type: Date, required: true, index: { expireAfterSeconds: 0 } },
}));
