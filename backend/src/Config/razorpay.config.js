import Razorpay from "razorpay";

const keyId = (process.env.RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY || "").trim();
const keySecret = (process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_SECRET || "").trim();

const razorpay = new Razorpay({
  key_id: keyId,
  key_secret: keySecret,
});

export { razorpay };
