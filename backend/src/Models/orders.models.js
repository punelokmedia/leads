import mongoose from "mongoose";

const OrderSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    leads: [
      {
        lead: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Lead",
          required: true,
        },
        price: {
          type: Number,
          required: true,
        },
        quantity: { 
          type: Number,
          required: true,
        },
      },
    ],

    totalAmount: {
      type: Number,
      required: true,
      min: 1,
    },

    currency: {
      type: String,
      default: "INR",
    },

    razorpayOrderId: {
      type: String,
      index: true,
    },

    razorpayPaymentId: String,
    razorpaySignature: String,

    status: {
      type: String,
      enum: ["RESERVED", "CREATED", "PROCESSING", "PAID", "FAILED", "EXPIRED", "CANCELLED", "REFUND_PENDING", "REFUNDED"],
      default: "CREATED",
      index: true,
    },

    paymentMethod: { type: String, enum: ['RAZORPAY', 'WALLET'], default: 'RAZORPAY' },
    paidAt: Date,
    reservationExpiresAt: Date,
    cartHash: String,
    fulfillmentVersion: Number,
    failureReason: String,
    lastReconciledAt: Date,

    isDownloaded: {
      type: Boolean,
      default: false,
    },

    downloadedAt: Date,
  },
  { timestamps: true }
);

export const Order = mongoose.model("Order", OrderSchema);
