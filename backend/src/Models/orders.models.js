import mongoose from "mongoose";

const OrderSchema = new mongoose.Schema(
  {
    // 👤 User
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // 🛒 Leads Purchased
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

    // 💰 Pricing
    totalAmount: {
      type: Number,
      required: true,
    },

    currency: {
      type: String,
      default: "INR",
    },

    // 💳 Razorpay Integration
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

    // 📊 Payment Status
    status: {
      type: String,
      enum: ["CREATED", "PAID", "FAILED"],
      default: "CREATED",
    },

    // ⏳ Tracking
    paidAt: {
      type: Date,
    },
  },
  { timestamps: true }
);


OrderSchema.index({ user: 1 });
OrderSchema.index({ razorpayOrderId: 1 });
OrderSchema.index({ status: 1 });

export const Order = mongoose.model("Order", OrderSchema);