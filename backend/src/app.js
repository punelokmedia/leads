import express from "express";
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

const app = express();

const allowedOrigins = [
  process.env.FRONTEND_URL,
  process.env.ADMIN_FRONTEND_URL,
  "http://localhost:5173",
  "http://localhost:5174",
  "http://localhost:5000",
  "http://localhost:3000",

].filter(Boolean).map((origin) => origin.trim().replace(/\/+$/, ""));

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);

    const isAllowed =
      allowedOrigins.includes(origin) ||
      origin.startsWith("chrome-extension://");

    if (isAllowed) {
      return callback(null, true);
    }

    return callback(new Error(`CORS blocked for origin: ${origin}`));
  },
  credentials: true,
};

app.use(cookieParser());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(cors(corsOptions));

app.use(passport.initialize());

const API_VERSION = process.env.API_VERSION;

app.use(`/api/${API_VERSION}/auth`, Auth);
app.use(`/api/${API_VERSION}/admin`, Admin);
app.use(`/api/${API_VERSION}/payments`, Payment);
app.use(`/api/${API_VERSION}/leads`, Lead);
app.use(`/api/${API_VERSION}/categories`, category);
app.use(`/api/${API_VERSION}/cities`, city);
app.use(`/api/${API_VERSION}/cart`, cart);

app.get("/", (req, res) => {
  return res.json({
    success: true,
    message: "welcome to dash-leads Backend",
  });
});

export { app };
