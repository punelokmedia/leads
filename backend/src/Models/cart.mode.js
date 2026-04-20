import mongoose, { Schema } from "mongoose";

const CartSchema = new Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
    },
    leads: [
      {
        lead: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Lead",
          required: true,
        },
        quantity: {
          type: Number,
          default: 1,
          min: 1,
          max: 3,
        },
      },
    ],
  },
  { timestamps: true }
);


export const Cart = mongoose.model("Cart", CartSchema);