import mongoose, { Schema } from "mongoose";

const CitySchema = new Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
    },
  },
  { timestamps: true },
);

export const City = mongoose.model("City", CitySchema);
