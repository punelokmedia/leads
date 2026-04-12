import mongoose, { Schema } from "mongoose";

const CartSchema = new Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
  leads: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Lead",
    },
  ],
});

export const Cart = mongoose.model("Cart", CartSchema);
