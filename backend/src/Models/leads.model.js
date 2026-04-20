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
        validate: {
          validator: function (value) {
            if (!Array.isArray(value) || value.length !== 2) return false;

            const [lng, lat] = value;

            return (
              typeof lng === "number" &&
              typeof lat === "number" &&
              lng >= -180 &&
              lng <= 180 &&
              lat >= -90 &&
              lat <= 90
            );
          },
          message:
            "Coordinates must be [longitude, latitude] with valid geo range",
        },
      },
    },

    price: {
      type: Number,
      required: true,
      min: 1,
    },

    budget: {
      min: {
        type: Number,
        min: 0,
      },
      max: {
        type: Number,
        min: 0,
      },
    },

    customerName: {
      type: String,
      trim: true,
    },

    phone: {
      type: String,
      validate: {
        validator: function (v) {
          return !v || /^[6-9]\d{9}$/.test(v);
        },
        message: "Invalid Indian phone number",
      },
    },

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
      min: 1,
    },

    expiresAt: {
      type: Date,
      required: true,
      validate: {
        validator: function (value) {
          return value > new Date();
        },
        message: "Expiry date must be in the future",
      },
    },

    status: {
      type: String,
      enum: ["ACTIVE", "SOLD_OUT", "EXPIRED"],
      default: "ACTIVE",
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
LeadSchema.index({ category: 1 });
LeadSchema.index({ city: 1, state: 1 });
LeadSchema.index({ expiresAt: 1 });
LeadSchema.index({ status: 1 });

LeadSchema.pre("save", function (next) {
  if (this.expiresAt < new Date()) {
    this.status = "EXPIRED";
  }

  if (this.buyers.length >= this.maxBuyers) {
    this.status = "SOLD_OUT";
  }

  next();
});

LeadSchema.statics.safeInsertMany = async function (docs) {
  return this.insertMany(docs, { ordered: false });
};

export const Lead = mongoose.model("Lead", LeadSchema);
