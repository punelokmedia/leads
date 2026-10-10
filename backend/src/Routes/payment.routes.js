import express from "express";
import { paymentLimit } from '../Middlewares/security-limits.js';
import { createOrder, verifyPayment, webhookHandler, cancelOrder } from "../Controllers/orders/payment.controller.js";
import { auth } from "../Middlewares/auth.middleware.js";

const router = express.Router();


router.post("/create", auth, paymentLimit, createOrder);

router.post("/verify", auth, paymentLimit, verifyPayment);
router.post("/cancel", auth, paymentLimit, cancelOrder);

router.post("/razorpay-webhook", webhookHandler);

export default router;
