import crypto from "crypto";
import { Cart } from "../../Models/cart.mode.js";
import { Order } from "../../Models/orders.models.js";
import { Lead } from "../../Models/leads.model.js";
import { razorpay } from "../../Config/razorpay.config.js";

const createOrder = async (req, res) => {
  try {
    const userId = req.user.id;

    const cart = await Cart.findOne({ user: userId })
      .populate("leads")
      .select("-customerName -phone");

    if (!cart || cart.leads.length === 0) {
      return res.status(400).json({
        success: false,
        message:
          "Your cart is empty. Please add leads before placing an order.",
      });
    }

    const totalAmount = cart.leads.reduce((sum, lead) => sum + lead.price, 0);

    const razorpayOrder = await razorpay.orders.create({
      amount: totalAmount * 100,
      currency: "INR",
    });

    const order = await Order.create({
      user: userId,
      leads: cart.leads.map((l) => ({
        lead: l._id,
        price: l.price,
      })),
      totalAmount,
      razorpayOrderId: razorpayOrder.id,
    });

    return res.status(201).json({
      success: true,
      message: "Order created successfully",
      data: {
        razorpayOrderId: razorpayOrder.id,
        internalOrderId: order._id,
        amount: totalAmount,
        currency: "INR",
        leadsCount: cart.leads.length,
      },
    });
  } catch (error) {
    console.error("Create Order Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create order. Please try again later.",
    });
  }
};

const verifyPayment = async (req, res) => {
  try {
    const userId = req.user.id;
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "Missing payment verification details",
      });
    }

    const generatedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (generatedSignature !== razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "Payment verification failed. Invalid signature.",
      });
    }

    const order = await Order.findOne({ razorpayOrderId });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found",
      });
    }

    if (order.status === "PAID") {
      return res.status(200).json({
        success: true,
        message: "Payment already verified",
        data: {
          orderId: order._id,
          status: order.status,
        },
      });
    }

    order.status = "PAID";
    order.razorpayPaymentId = razorpayPaymentId;
    order.razorpaySignature = razorpaySignature;
    order.paidAt = new Date();

    await order.save();

    for (const item of order.leads) {
      const lead = await Lead.findById(item.lead);
      if (!lead) continue;

      const alreadyBought = lead.buyers.some(
        (b) => b.user.toString() === userId,
      );

      if (!alreadyBought) {
        lead.buyers.push({ user: userId });
      }

      if (lead.buyers.length >= lead.maxBuyers) {
        lead.status = "SOLD_OUT";
      }

      await lead.save();
    }

    await Cart.findOneAndUpdate({ user: userId }, { $set: { leads: [] } });

    return res.status(200).json({
      success: true,
      message: "Payment successful. Leads unlocked successfully.",
      data: {
        orderId: order._id,
        paymentId: razorpayPaymentId,
        status: order.status,
      },
    });
  } catch (error) {
    console.error("Verify Payment Error:", error);

    return res.status(500).json({
      success: false,
      message: "Payment verification failed. Please try again.",
    });
  }
};

const webhookSecret = async (req, res) => {
  try {
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    const signature = req.headers["x-razorpay-signature"];

    const body = JSON.stringify(req.body);

    const expectedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(body)
      .digest("hex");

    if (expectedSignature !== signature) {
      return res.status(400).json({
        success: false,
        message: "Invalid webhook signature",
      });
    }

    const event = req.body.event;

    // 🎯 Handle payment success
    if (event === "payment.captured") {
      const payment = req.body.payload.payment.entity;

      const razorpayOrderId = payment.order_id;
      const razorpayPaymentId = payment.id;

      const order = await Order.findOne({ razorpayOrderId });

      if (!order) {
        return res.status(200).json({
          success: true,
          message: "Order not found, skipping",
        });
      }

      // ⚠️ Idempotency
      if (order.status === "PAID") {
        return res.status(200).json({
          success: true,
          message: "Order already processed",
          data: {
            orderId: order._id,
          },
        });
      }

      // ✅ Update order
      order.status = "PAID";
      order.razorpayPaymentId = razorpayPaymentId;
      order.paidAt = new Date();

      await order.save();

      const userId = order.user;

      // 🔓 Unlock leads
      for (const item of order.leads) {
        const lead = await Lead.findById(item.lead);
        if (!lead) continue;

        const alreadyBought = lead.buyers.some(
          (b) => b.user.toString() === userId.toString(),
        );

        if (!alreadyBought) {
          lead.buyers.push({ user: userId });
        }

        if (lead.buyers.length >= lead.maxBuyers) {
          lead.status = "SOLD_OUT";
        }

        await lead.save();
      }

      // 🧹 Clear cart
      await Cart.findOneAndUpdate({ user: userId }, { $set: { leads: [] } });

      return res.status(200).json({
        success: true,
        message: "Webhook processed successfully",
        data: {
          orderId: order._id,
          paymentId: razorpayPaymentId,
        },
      });
    }

    // ℹ️ Other events
    return res.status(200).json({
      success: true,
      message: `Unhandled event: ${event}`,
    });
  } catch (error) {
    console.error("Webhook Error:", error);

    return res.status(500).json({
      success: false,
      message: "Webhook processing failed",
    });
  }
};

export { createOrder, verifyPayment, webhookSecret };
