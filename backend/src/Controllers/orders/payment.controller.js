import crypto from "crypto";
import mongoose from "mongoose";
import { Cart } from "../../Models/cart.mode.js";
import { Order } from "../../Models/orders.models.js";
import { Lead } from "../../Models/leads.model.js";
import { razorpay } from "../../Config/razorpay.config.js";
import { LeadPurchase } from "../../Models/lead.purchase.model.js";

const ORDER_EXPIRY = 15 * 60 * 1000;
const RAZORPAY_PUBLIC_KEY =
  process.env.RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY || "";

const generateCartHash = (items) => {
  const sorted = items
    .map((i) => `${i.lead}-${i.quantity}`)
    .sort()
    .join("|");

  return crypto.createHash("sha256").update(sorted).digest("hex");
};

const createOrder = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized access",
      });
    }

    const cart = await Cart.findOne({ user: userId }).populate("leads.lead");

    if (!cart || cart.leads.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Your cart is empty",
      });
    }

    const cartHash = generateCartHash(cart.leads);

    const existing = await Order.findOne({
      user: userId,
      status: "CREATED",
    }).sort({ createdAt: -1 });

    if (existing) {
      const elapsed = Date.now() - existing.createdAt.getTime();
      const isExpired = elapsed > ORDER_EXPIRY;

      if (existing.cartHash === cartHash && !isExpired) {
        return res.status(200).json({
          success: true,
          message: "Using existing pending order",
          data: {
            keyId: RAZORPAY_PUBLIC_KEY,
            razorpayOrderId: existing.razorpayOrderId,
            internalOrderId: existing._id,
            amount: existing.totalAmount,
            currency: existing.currency || "INR",
            leadsCount: existing.leads.length,
            expiresIn: Math.max(0, Math.floor((ORDER_EXPIRY - elapsed) / 1000)),
          },
        });
      }

      existing.status = "FAILED";
      await existing.save();
    }

    let total = 0;
    const leads = [];

    for (let item of cart.leads) {
      const lead = item.lead;

      if (!lead) {
        return res.status(400).json({
          success: false,
          message: "Some items in your cart are invalid. Please refresh cart.",
        });
      }

      const remaining = lead.maxBuyers - (lead.buyersCount || 0);

      if (lead.maxBuyers <= 0) {
        return res.status(400).json({
          success: false,
          message: `"${lead.title}" is not available for purchase`,
        });
      }

      if (lead.expiresAt < new Date()) {
        return res.status(400).json({
          success: false,
          message: `"${lead.title}" has expired`,
        });
      }

      if (remaining <= 0) {
        return res.status(400).json({
          success: false,
          message: `"${lead.title}" is already sold out`,
        });
      }

      if (remaining < item.quantity) {
        return res.status(400).json({
          success: false,
          message: `Only ${remaining} slots left for "${lead.title}"`,
        });
      }

      total += lead.price * item.quantity;

      leads.push({
        lead: lead._id,
        price: lead.price,
        quantity: item.quantity,
      });
    }

    if (total <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid cart total",
      });
    }

    let rzOrder;
    try {
      rzOrder = await razorpay.orders.create({
        amount: total * 100,
        currency: "INR",
      });
    } catch (err) {
      console.error("Razorpay Error:", err);
      const errorDescription = err?.error?.description || err?.message || "";
      const isAuthError =
        Number(err?.statusCode) === 401 ||
        String(errorDescription).toLowerCase().includes("authentication failed");

      return res.status(502).json({
        success: false,
        message: isAuthError
          ? "Razorpay authentication failed. Please verify backend Razorpay key and secret."
          : "Payment gateway error. Please try again.",
      });
    }

    const order = await Order.create({
      user: userId,
      leads,
      totalAmount: total,
      currency: "INR",
      razorpayOrderId: rzOrder.id,
      cartHash,
      status: "CREATED",
    });

    const expiryInSeconds = Math.floor(ORDER_EXPIRY / 1000);

    return res.status(201).json({
      success: true,
      message: "Order created successfully",
      data: {
        keyId: RAZORPAY_PUBLIC_KEY,
        razorpayOrderId: order.razorpayOrderId,
        internalOrderId: order._id,
        amount: order.totalAmount,
        currency: order.currency,
        leadsCount: order.leads.length,
        expiresIn: expiryInSeconds,
      },
    });
  } catch (error) {
    console.error("Create Order Error:", error);

    return res.status(500).json({
      success: false,
      message: "Something went wrong while creating order",
    });
  }
};

const verifyPayment = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized access.",
      });
    }

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "Missing payment details.",
      });
    }

    const razorpaySecret =
      process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_SECRET || "";

    if (!razorpaySecret) {
      return res.status(500).json({
        success: false,
        message: "Razorpay is not configured on server.",
      });
    }

    const generated = crypto
      .createHmac("sha256", razorpaySecret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (generated !== razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "Invalid signature.",
      });
    }

    const order = await Order.findOneAndUpdate(
      { razorpayOrderId, status: "CREATED" },
      { status: "PROCESSING" },
      { new: true },
    );

    if (!order) {
      return res.json({
        success: true,
        message: "Payment already processed.",
      });
    }

    const successLeads = [];
    const failedLeads = [];

    for (const item of order.leads) {
      const qty = item.quantity || 1;

      try {
        const updatedLead = await Lead.findOneAndUpdate(
          {
            _id: item.lead,
            $expr: {
              $gte: [
                { $subtract: ["$maxBuyers", { $ifNull: ["$buyersCount", 0] }] },
                qty,
              ],
            },
          },
          { $inc: { buyersCount: qty } },
          { new: true },
        );

        if (!updatedLead) {
          failedLeads.push({
            leadId: item.lead,
            quantity: qty,
            reason: "Not enough slots",
          });
          continue;
        }

        await LeadPurchase.create({
          lead: item.lead,
          user: userId,
          quantity: qty,
        });

        const remaining =
          updatedLead.maxBuyers - (updatedLead.buyersCount || 0);

        let status = "ACTIVE";
        if (updatedLead.expiresAt < new Date()) status = "EXPIRED";
        else if (remaining === 0) status = "SOLD_OUT";

        await Lead.updateOne({ _id: updatedLead._id }, { status });

        successLeads.push({
          leadId: updatedLead._id,
          quantity: qty,
          remainingSlots: remaining,
        });
      } catch (err) {
        failedLeads.push({
          leadId: item.lead,
          quantity: qty,
          reason: "Processing error",
        });
      }
    }

    order.status = "PAID";
    order.razorpayPaymentId = razorpayPaymentId;
    order.paidAt = new Date();

    await order.save();

    if (successLeads.length > 0) {
      await Cart.updateOne({ user: order.user }, { $set: { leads: [] } });
    }

    return res.json({
      success: true,
      message:
        failedLeads.length > 0 ? "Partial success" : "Payment successful",
      data: { successLeads, failedLeads },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({
      success: false,
      message: "Verification failed",
    });
  }
};

const webhookHandler = async (req, res) => {
  const session = await mongoose.startSession();

  try {
    const signature = req.headers["x-razorpay-signature"];

    const expectedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_WEBHOOK_SECRET)
      .update(req.rawBody)
      .digest("hex");

    if (expectedSignature !== signature) {
      return res.status(400).json({ success: false });
    }

    const event = req.body.event;

    if (event === "payment.captured") {
      const payment = req.body.payload.payment.entity;

      await session.withTransaction(async () => {
        const order = await Order.findOneAndUpdate(
          { razorpayOrderId: payment.order_id, status: "CREATED" },
          { status: "PROCESSING" },
          { new: true, session },
        );

        if (!order) return;

        for (const item of order.leads) {
          await markLeadAsPurchased(
            item.lead,
            order.user,
            item.quantity,
            session,
          );
        }

        order.status = "PAID";
        order.razorpayPaymentId = payment.id;
        order.paidAt = new Date();

        await order.save({ session });

        await Cart.findOneAndUpdate(
          { user: order.user },
          { $set: { leads: [] } },
          { session },
        );
      });
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("Webhook Error:", error);
    return res.status(500).json({ success: false });
  } finally {
    session.endSession();
  }
};

const markLeadAsPurchased = async (leadId, userId, quantity, session) => {
  const updatedLead = await Lead.findOneAndUpdate(
    {
      _id: leadId,
      $expr: {
        $gte: [{ $subtract: ["$maxBuyers", "$buyersCount"] }, quantity],
      },
    },
    {
      $inc: { buyersCount: quantity },
    },
    { new: true, session },
  );

  if (!updatedLead) throw new Error("Slots exceeded");

  await LeadPurchase.create([{ lead: leadId, user: userId, quantity }], {
    session,
  });

  return updatedLead;
};

export { createOrder, verifyPayment, webhookHandler };
