import "./Config/env.config.js";
import express from "express";
import { connectDB } from "./Config/db.connection.config.js";
import cookieParser from "cookie-parser";
import cors from "cors";
import passport from "./Config/passport.js";

import Auth from "./Routes/auth.routes.js";
import Admin from "./Routes/admin.routes.js";
import Payment from "./Routes/payment.routes.js";
import Lead from "./Routes/lead.routes.js";
import category from "./Routes/categories.routes.js";
import cart from "./Routes/cart.routes.js";
import city from "./Routes/city.routes.js";
import { supportRouter } from "./Routes/support.routes.js";
import { accountDeletionRouter } from "./Routes/accountDeletion.routes.js";
import { referralRouter } from "./Routes/referral.routes.js";

const app = express();

const allowedOrigins = [
  process.env.CLIENT_URL,
  process.env.FRONTEND_URL,
  process.env.ADMIN_FRONTEND_URL,
  ...(process.env.CORS_ALLOWED_ORIGINS || "").split(","),
  "http://localhost:5173",
  "http://localhost:5174",
  "http://localhost:5000",
  "http://localhost:3000",

].map((origin) => origin?.trim().replace(/\/+$/, "")).filter(Boolean);

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);

    const isAllowed =
      allowedOrigins.includes(origin) ||
      origin.startsWith("chrome-extension://");

    if (isAllowed) {
      return callback(null, true);
    }

    return callback(Object.assign(new Error('Origin is not allowed.'), { code: 'CORS_ORIGIN_DENIED' }));
  },
  credentials: true,
};

// Handle browser preflight before parsing bodies or accessing the database.
app.use(cors(corsOptions));
app.use((error, _req, res, next) => {
  if (error.code === 'CORS_ORIGIN_DENIED') {
    return res.status(403).json({ success: false, code: error.code, message: error.message });
  }
  return next(error);
});
app.use(cookieParser());
app.use(express.json({ limit: "10mb", verify: (req, _res, buffer) => {
  if (req.originalUrl.split('?')[0].endsWith('/payments/razorpay-webhook')) req.rawBody = Buffer.from(buffer);
} }));
app.use(express.urlencoded({ extended: true }));

app.use(passport.initialize());

const API_VERSION = process.env.API_VERSION || "v1";

// Reuse a database connection across requests in each Vercel instance.
if (process.env.VERCEL) {
  app.use(`/api/${API_VERSION}`, async (_req, res, next) => {
    try {
      await connectDB();
      next();
    } catch (error) {
      console.error("Database connection failed:", error.message);
      res.status(503).json({ success: false, message: "Database unavailable" });
    }
  });
}

app.use(`/api/${API_VERSION}/auth`, Auth);
app.use(`/api/${API_VERSION}/admin`, Admin);
app.use(`/api/${API_VERSION}/payments`, Payment);
app.use(`/api/${API_VERSION}/leads`, Lead);
app.use(`/api/${API_VERSION}/categories`, category);
app.use(`/api/${API_VERSION}/cities`, city);
app.use(`/api/${API_VERSION}/cart`, cart);
app.use(`/api/${API_VERSION}/support`, supportRouter);
app.use(`/api/${API_VERSION}/account-deletion-requests`, accountDeletionRouter);
app.use(`/api/${API_VERSION}/referrals`, referralRouter);

app.get("/", (req, res) => {
  return res.json({
    success: true,
    message: "welcome to dash-leads Backend",
  });
});

export { app };
export default app;
