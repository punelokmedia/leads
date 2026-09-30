import mongoose, { Schema } from "mongoose";
import { BUYER_LIMIT, inventory } from "../Services/lead-inventory.js";

const LeadSchema = new Schema(
  {
    leadDisplayId: {
      type: String,
      unique: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },

    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Category",
      required: true,
    },

    city: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    state: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },

    address: {
      type: String,
      trim: true,
    },

    price: {
      type: Number,
      required: true,
      min: 1,
    },
    originalPrice: {
      type: Number,
      min: 1,
    },

    budget: {
      min: Number,
      max: Number,
    },

    customerName: {
      type: String,
      trim: true,
      default: "",
    },
    clientType: {
      type: String,
      trim: true,
      default: "",
    },
    primaryPhone: {
      type: String,
      validate: {
        validator: (v) => !v || /^[6-9]\d{9}$/.test(v),
      },
    },
    alternatePhone: {
      type: String,
      validate: {
        validator: (v) => !v || /^[6-9]\d{9}$/.test(v),
      },
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      default: "",
    },
    areaLocality: {
      type: String,
      trim: true,
      default: "",
    },
    requirement: {
      type: String,
      trim: true,
      default: "",
    },
    propertyType: {
      type: String,
      trim: true,
      default: "",
    },
    areaSize: {
      type: String,
      trim: true,
      default: "",
    },
    budgetRange: {
      type: String,
      trim: true,
      default: "",
    },
    timeline: {
      type: String,
      trim: true,
      default: "",
    },
    phone: {
      type: String,
      validate: {
        validator: (v) => !v || /^[6-9]\d{9}$/.test(v),
      },
    },

    buyersCount: {
      type: Number,
      default: 0,
    },

    maxBuyers: {
      type: Number,
      default: BUYER_LIMIT,
      enum: [BUYER_LIMIT],
    },
    reservations: [{
      _id: false,
      order: { type: Schema.Types.ObjectId, ref: "Order", required: true },
      user: { type: Schema.Types.ObjectId, ref: "User", required: true },
      expiresAt: { type: Date, required: true },
    }],

    expiresAt: {
      type: Date,
      required: true,
    },

    status: {
      type: String,
      enum: ["ACTIVE", "RESERVED", "SOLD_OUT", "EXPIRED"],
      default: "ACTIVE",
      index: true,
    },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true },
);

LeadSchema.index({ expiresAt: 1 });
LeadSchema.index({ maxBuyers: 1, buyersCount: 1 });

LeadSchema.virtual("remainingSlots").get(function () {
  return inventory(this).remainingSlots;
});

const resolveLeadStatus = (lead) => {
  return inventory(lead).status;
};

const buildLeadDisplayId = (leadId) =>
  `NL${String(leadId || "").slice(-8).toUpperCase()}`;

LeadSchema.pre("validate", function () {
  this.maxBuyers = BUYER_LIMIT;
  if (this._id) {
    this.leadDisplayId = buildLeadDisplayId(this._id);
  }
});

LeadSchema.pre("save", function () {
  this.status = resolveLeadStatus(this);
});

export const Lead = mongoose.model("Lead", LeadSchema);
export { resolveLeadStatus };
