import mongoose, { Schema } from "mongoose";

const CategorySchema = new Schema({
    name: {
      type: String,
      required: true,
      unique: true,
    },
    icon: String,
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true },
);

export const Category = mongoose.model("Category", CategorySchema);
