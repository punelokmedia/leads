import mongoose, { Schema } from "mongoose";

const LeadSchema = new Schema(
  {
    // 🔹 Basic Info
    title: {
      type: String,
      required: true,
    },

    description: {
      type: String,
      required: true,
    },

    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Category",
      required: true,
    },

    // 📍 Location (Important)
    city: {
      type: String,
      required: true,
      index: true,
    },

    state: {
      type: String,
      required: true,
      index: true,
    },

    address: {
      type: String, // full address (hidden initially)
    },

    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [lng, lat]
      },
    },

    // 💰 Pricing
    price: {
      type: Number,
      required: true,
    },

    budget: {
      min: Number,
      max: Number,
    },

    // 👤 Customer Info (hidden before purchase)
    customerName: String,
    phone: String,

    // 🔐 Lead Access Logic
    buyers: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
        },
        purchasedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],

    maxBuyers: {
      type: Number,
      default: 3,
    },

    // ⏳ Expiry
    expiresAt: {
      type: Date,
      required: true,
    },

    // 📊 Status
    status: {
      type: String,
      enum: ["ACTIVE", "SOLD_OUT", "EXPIRED"],
      default: "ACTIVE",
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User", // admin
    },
  },
  { timestamps: true },
);

LeadSchema.index({ location: "2dsphere" });
LeadSchema.index({ category: 1 });
LeadSchema.index({ city: 1, state: 1 });
LeadSchema.index({ expiresAt: 1 });
LeadSchema.index({ status: 1 });

export const Lead = mongoose.model("Lead", LeadSchema);
