import mongoose from 'mongoose';
const schema = new mongoose.Schema({
  requestId: { type: String, required: true, unique: true },
  name: { type: String, required: true, maxlength: 100 },
  phone: { type: String, required: true },
  email: { type: String, required: true, maxlength: 254 },
  city: { type: String, required: true, maxlength: 100 },
  message: { type: String, required: true, maxlength: 5000 },
  status: { type: String, enum: ['NEW', 'READ', 'RESOLVED'], default: 'NEW' },
}, { timestamps: true });
export const ContactMessage = mongoose.model('ContactMessage', schema);
