import express from "express";
import { addToCart } from "../Controllers/orders/cart.controller.js";
import { createOrder, verifyPayment, webhookSecret } from "../Controllers/orders/order.controller.js";
import { auth } from "../Middlewares/auth.middleware.js";

const router = express.Router();

router.post("/cart", auth, addToCart);

router.post("/create", auth, createOrder);

router.post("/verify", auth, verifyPayment);

router.post("/razorpay-webhook", auth, webhookSecret);

export default router;
