import mongoose from "mongoose";

let connectionPromise;

const connectDB = async () => {
  if (mongoose.connection.readyState === 1) return mongoose;
  if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL is not configured");
  if (!connectionPromise) {
    connectionPromise = mongoose.connect(process.env.DATABASE_URL, {
      serverSelectionTimeoutMS: 10000,
    }).catch((error) => {
      connectionPromise = undefined;
      throw error;
    });
  }
  return connectionPromise;
};

export { connectDB };
