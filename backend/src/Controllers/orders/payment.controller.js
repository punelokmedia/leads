import crypto from "crypto";
import mongoose from "mongoose";
import { Cart } from "../../Models/cart.mode.js";
import { Order } from "../../Models/orders.models.js";
import { Lead } from "../../Models/leads.model.js";
import { razorpay } from "../../Config/razorpay.config.js";

const ORDER_EXPIRY = 15 * 60 * 1000;

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
            razorpayOrderId: existing.razorpayOrderId,
            internalOrderId: existing._id,
            amount: existing.totalAmount,
            currency: existing.currency || "INR",
            leadsCount: existing.leads.length,
            expiresIn: Math.max(
              0,
              Math.floor((ORDER_EXPIRY - elapsed) / 1000), 
            ),
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

      const remaining = lead.maxBuyers - lead.buyers.length;

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

      return res.status(502).json({
        success: false,
        message: "Payment gateway error. Please try again.",
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
        message: "Unauthorized",
      });
    }

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "Missing payment details",
      });
    }

    const generated = crypto
      .createHmac("sha256", process.env.RAZORPAY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (generated !== razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "Invalid payment signature",
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
        message: "Payment already processed",
      });
    }

    const failedLeads = [];

    for (const item of order.leads) {
      try {
        const updatedLead = await Lead.findOneAndUpdate(
          {
            _id: item.lead,
            $expr: {
              $gte: [
                { $subtract: ["$maxBuyers", { $size: "$buyers" }] },
                item.quantity,
              ],
            },
          },
          {
            $push: {
              buyers: {
                $each: Array.from({ length: item.quantity }).map(() => ({
                  user: userId,
                  purchasedAt: new Date(),
                })),
              },
            },
          },
          { new: true },
        );

        if (!updatedLead) {
          failedLeads.push({
            leadId: item.lead,
            reason: "Not enough slots available",
          });
          continue;
        }

        let newStatus = "ACTIVE";

        if (updatedLead.expiresAt < new Date()) {
          newStatus = "EXPIRED";
        } else if (updatedLead.buyers.length >= updatedLead.maxBuyers) {
          newStatus = "SOLD_OUT";
        }

        await Lead.updateOne({ _id: updatedLead._id }, { status: newStatus });
      } catch (err) {
        failedLeads.push({
          leadId: item.lead,
          reason: err.message,
        });
      }
    }

    order.status = "PAID";
    order.razorpayPaymentId = razorpayPaymentId;
    order.razorpaySignature = razorpaySignature;
    order.paidAt = new Date();
    order.failedLeads = failedLeads;

    await order.save();

    await Cart.updateOne({ user: order.user }, { $set: { leads: [] } });

    return res.status(200).json({
      success: true,
      message:
        failedLeads.length > 0
          ? "Payment successful, but some leads were unavailable"
          : "Payment successful",
      failedLeads,
    });
  } catch (err) {
    console.error("Verify Payment Error:", err);

    return res.status(500).json({
      success: false,
      message: "Payment verification failed",
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
        const order = await Order.findOne({
          razorpayOrderId: payment.order_id,
        }).session(session);

        if (!order || order.status === "PAID") return;

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
  const lead = await Lead.findById(leadId).session(session);

  if (!lead) throw new Error("Lead not found");

  const remaining = lead.maxBuyers - lead.buyers.length;

  if (remaining < quantity) {
    throw new Error("Slots exceeded");
  }

  const buyers = Array.from({ length: quantity }).map(() => ({
    user: userId,
    purchasedAt: new Date(),
  }));

  lead.buyers.push(...buyers);

  await lead.save({ session });

  return lead;
};

export { createOrder, verifyPayment, webhookHandler };
