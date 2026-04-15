import mongoose from "mongoose";

const OrderSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    leads: [
      {
        lead: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Lead",
        },
        price: {
          type: Number,
          required: true,
        },
      },
    ],
    totalAmount: {
      type: Number,
      required: true,
    },
    currency: {
      type: String,
      default: "INR",
    },
    razorpayOrderId: {
      type: String,
      required: true,
    },
    razorpayPaymentId: {
      type: String,
    },
    razorpaySignature: {
      type: String,
    },
    status: {
      type: String,
      enum: ["CREATED", "PAID", "FAILED"],
      default: "CREATED",
    },
    paidAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  },
);

OrderSchema.index({ user: 1 });
OrderSchema.index({ razorpayOrderId: 1 });
OrderSchema.index({ status: 1 });

export const Order = mongoose.model("Order", OrderSchema);
