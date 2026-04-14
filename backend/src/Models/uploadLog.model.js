import mongoose from "mongoose";

const uploadLogSchema = new mongoose.Schema(
  {
    totalRows: {
      type: Number,
    },
    processedRows: {
      type: Number,
      default: 0,
    },
    successCount: {
      type: Number,
      default: 0,
    },
    failedCount: {
      type: Number,
      default: 0,
    },
    status: {
      type: String,
      enum: ["processing", "completed", "failed"],
      default: "processing",
    },
    logs: [
      {
        row: Number,
        message: String,
      },
    ],
  },
  { timestamps: true },
);

export const UploadLog = mongoose.model("UploadLog", uploadLogSchema);
