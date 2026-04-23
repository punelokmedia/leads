import mongoose, { Schema } from "mongoose";

const LeadPurchaseSchema = new Schema({
  lead: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Lead",
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  quantity: {
    type: Number,
    required: true,
  },
  purchasedAt: {
    type: Date,
    default: Date.now,
  },
});

export const LeadPurchase = mongoose.model("LeadPurchase", LeadPurchaseSchema);
