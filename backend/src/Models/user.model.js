import mongoose, { Schema } from "mongoose";

const AddressSchema = new Schema(
  {
    label: {
      type: String,
      enum: ["HOME", "OFFICE", "OTHER"],
      default: "HOME",
    },
    street: {
      type: String,
      required: true,
      trim: true,
    },
    landmark: {
      type: String,
      trim: true,
    },
    city: {
      type: String,
      required: true,
      trim: true,
    },
    state: {
      type: String,
      required: true,
      trim: true,
    },
    country: {
      type: String,
      default: "India",
    },
    zipcode: {
      type: String,
      required: true,
    },
  },
  { _id: false },
);

const UserSchema = new Schema(
  {
    firstname: {
      type: String,
      required: true,
      trim: true,
    },

    lastname: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    password: {
      type: String,
      default: null,
    },
    googleId: {
      type: String,
    },

    providers: {
      type: [String],
      enum: ["LOCAL", "GOOGLE"],
      default: [],
    },

    phoneNumber: String,
    businessName: {
      type: String,
      trim: true,
      default: "",
    },
    workType: {
      type: String,
      trim: true,
      default: "",
    },
    city: {
      type: String,
      trim: true,
      default: "",
    },
    profilePic: String,

    role: {
      type: String,
      enum: ["ADMIN", "USER"],
      default: "USER",
    },
    isBlocked: {
      type: Boolean,
      default: false,
    },

    address: {
      type: AddressSchema,
      default: null,
    },

    resetOtp: String,
    resetOtpExpire: Date,
    loginOtp: String,
    loginOtpExpire: Date,
    pendingPhoneNumber: {
      type: String,
      default: "",
    },
    registrationFeePaid: {
      type: Boolean,
      default: false,
    },
    registrationFeePaidAt: Date,
    registrationPayment: {
      razorpayOrderId: String,
      razorpayPaymentId: String,
      razorpaySignature: String,
      amount: Number,
      currency: String,
    },
  },
  { timestamps: true },
);

UserSchema.index(
  { googleId: 1 },
  {
    unique: true,
    partialFilterExpression: { googleId: { $exists: true } },
  },
);

UserSchema.index({ "address.city": 1, "address.state": 1 });
UserSchema.index(
  { phoneNumber: 1 },
  {
    unique: true,
    partialFilterExpression: { phoneNumber: { $type: "string", $ne: "" } },
  },
);

export const User = mongoose.model("User", UserSchema);
