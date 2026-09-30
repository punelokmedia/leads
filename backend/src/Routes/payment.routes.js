import express from "express";
import { createOrder, verifyPayment, webhookHandler, cancelOrder } from "../Controllers/orders/payment.controller.js";
import { auth } from "../Middlewares/auth.middleware.js";

const router = express.Router();


router.post("/create", auth, createOrder);

router.post("/verify", auth, verifyPayment);
router.post("/cancel", auth, cancelOrder);

router.post("/razorpay-webhook", webhookHandler);

export default router;
