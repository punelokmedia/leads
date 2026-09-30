import mongoose, { Schema } from "mongoose";

const LeadPurchaseSchema = new Schema({
  order: { type: Schema.Types.ObjectId, ref: "Order" },
  fulfillmentVersion: Number,
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
// Preserve legacy records while enforcing uniqueness for the new checkout flow.
LeadPurchaseSchema.index({ lead: 1, user: 1 }, {
  unique: true, partialFilterExpression: { fulfillmentVersion: 2 },
});

export const LeadPurchase = mongoose.model("LeadPurchase", LeadPurchaseSchema);
