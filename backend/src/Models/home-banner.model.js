import mongoose from 'mongoose';

const schema = new mongoose.Schema({
  _id: { type: String, enum: ['business', 'membership'] },
  title: { type: String, required: true, maxlength: 150 },
  target: { type: String, enum: ['leads', 'membership'], required: true },
  image: { type: Buffer, required: true, select: false },
  contentType: { type: String, enum: ['image/png', 'image/jpeg', 'image/webp'], required: true },
  version: { type: String, required: true },
}, { timestamps: true });

export const HomeBanner = mongoose.model('HomeBanner', schema);
