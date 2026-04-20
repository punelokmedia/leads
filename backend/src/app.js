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

const app = express();

const corsOptions = {
  origin: ["http://localhost:5173"],
  methods: ["POST", "GET", "PUT", "DELETE", "OPTIONS"],
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
app.use(`/api/${API_VERSION}/cart`, cart);

app.get("/", (req, res) => {
  return res.json({
    success: true,
    message: "welcome to dash-leads Backend",
  });
});

export { app };
