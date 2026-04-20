import mongoose, { Schema } from "mongoose";

const LeadSchema = new Schema(
  {
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

    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number],
        required: true,
      },
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
    },

    phone: {
      type: String,
      validate: {
        validator: (v) => !v || /^[6-9]\d{9}$/.test(v),
      },
    },

    buyers: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        purchasedAt: { type: Date, default: Date.now },
      },
    ],

    maxBuyers: {
      type: Number,
      default: 3,
      min: 1,
    },

    expiresAt: {
      type: Date,
      required: true,
    },

    status: {
      type: String,
      enum: ["ACTIVE", "SOLD_OUT", "EXPIRED"],
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

LeadSchema.index({ location: "2dsphere" });
LeadSchema.index({ expiresAt: 1 });

LeadSchema.virtual("remainingSlots").get(function () {
  return this.maxBuyers - this.buyers.length;
});

const resolveLeadStatus = (lead) => {
  if (lead.expiresAt < new Date()) return "EXPIRED";
  if (lead.buyers.length >= lead.maxBuyers) return "SOLD_OUT";
  return "ACTIVE";
};

LeadSchema.pre("save", function () {
  this.status = resolveLeadStatus(this);
});

export const Lead = mongoose.model("Lead", LeadSchema);
export { resolveLeadStatus };
