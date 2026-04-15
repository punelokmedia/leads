import express from "express";
import { addToCart } from "../Controllers/orders/cart.controller.js";
import { createOrder, verifyPayment, webhookSecret } from "../Controllers/orders/payment.controller.js";
import { auth } from "../Middlewares/auth.middleware.js";

const router = express.Router();


router.post("/create", auth, createOrder);

router.post("/verify", auth, verifyPayment);

router.post("/razorpay-webhook", webhookSecret);

export default router;
