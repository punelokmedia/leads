import crypto from "crypto";
import { Cart } from "../../Models/cart.mode.js";
import { Order } from "../../Models/orders.models.js";
import { Lead } from "../../Models/leads.model.js";
import { razorpay } from "../../Config/razorpay.config.js";

const ORDER_EXPIRY_MINUTES = 15;

const generateCartHash = (leads) => {
  const sorted = leads
    .map((l) => `${l._id}-${l.price}`)
    .sort()
    .join("|");

  return crypto.createHash("sha256").update(sorted).digest("hex");
};

const createOrder = async (req, res) => {
  try {
    const userId = req.user.id;

    const cart = await Cart.findOne({
      user: userId,
    }).populate("leads");

    if (!cart || cart.leads.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Cart is empty",
      });
    }

    const cartHash = generateCartHash(cart.leads);

    const existingOrder = await Order.findOne({
      user: userId,
      status: "CREATED",
    }).sort({ createdAt: -1 });

    if (existingOrder) {
      const isExpired =
        Date.now() - existingOrder.createdAt.getTime() >
        ORDER_EXPIRY_MINUTES * 60 * 1000;

      if (existingOrder.cartHash === cartHash && !isExpired) {
        return res.status(200).json({
          success: true,
          message: "Reusing existing order",
          data: {
            razorpayOrderId: existingOrder.razorpayOrderId,
            internalOrderId: existingOrder._id,
            amount: existingOrder.totalAmount,
            currency: existingOrder.currency,
            expiresIn: ORDER_EXPIRY_MINUTES * 60,
          },
        });
      }

      existingOrder.status = "FAILED";
      await existingOrder.save();
    }

    const leadIds = cart.leads.map((l) => l._id);

    const leads = await Lead.find({ _id: { $in: leadIds } });

    for (let lead of leads) {
      const remainingSlots = lead.maxBuyers - lead.buyers.length;

      if (remainingSlots <= 0) {
        return res.status(400).json({
          success: false,
          message: `Lead "${lead.title}" is sold out`,
        });
      }

      if (lead.expiresAt < new Date()) {
        return res.status(400).json({
          success: false,
          message: `Lead "${lead.title}" is expired`,
        });
      }
    }

    const totalAmount = leads.reduce((sum, lead) => sum + lead.price, 0);

    const razorpayOrder = await razorpay.orders.create({
      amount: totalAmount * 100,
      currency: "INR",
    });

    const order = await Order.create({
      user: userId,
      leads: leads.map((l) => ({
        lead: l._id,
        price: l.price,
      })),
      totalAmount,
      razorpayOrderId: razorpayOrder.id,
      cartHash,
      status: "CREATED",
    });

    return res.status(201).json({
      success: true,
      message: "Order created successfully",
      data: {
        razorpayOrderId: razorpayOrder.id,
        internalOrderId: order._id,
        amount: totalAmount,
        currency: "INR",
        expiresIn: ORDER_EXPIRY_MINUTES * 60,
        leadsCount: leads.length,
      },
    });
  } catch (error) {
    console.error("Create Order Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to create order",
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
        message: "Missing payment details",
      });
    }

    const generatedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (generatedSignature !== razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "Invalid signature",
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
        message: "Already processed",
      });
    }

    order.status = "PAID";
    order.razorpayPaymentId = razorpayPaymentId;
    order.razorpaySignature = razorpaySignature;
    order.paidAt = new Date();
    await order.save();

    const failedLeads = [];

    for (const item of order.leads) {
      const updated = await Lead.findOneAndUpdate(
        {
          _id: item.lead,
          $expr: { $lt: [{ $size: "$buyers" }, "$maxBuyers"] },
        },
        {
          $push: {
            buyers: {
              user: userId,
              purchasedAt: new Date(),
            },
          },
        },
        { new: true },
      );

      if (!updated) {
        failedLeads.push(item.lead);
      }
    }

    await Cart.findOneAndUpdate(
      {
        user: userId,
      },
      {
        $set: {
          leads: [],
        },
      },
    );

    return res.status(200).json({
      success: true,
      message:
        failedLeads.length > 0
          ? "Payment done, but some leads were sold out"
          : "Payment successful",
      failedLeads,
    });
  } catch (error) {
    console.error("Verify Error:", error);

    return res.status(500).json({
      success: false,
      message: "Payment verification failed",
    });
  }
};

const webhookHandler = async (req, res) => {
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

      const order = await Order.findOne({
        razorpayOrderId: payment.order_id,
      });

      if (!order || order.status === "PAID") {
        return res.status(200).json({ success: true });
      }

      order.status = "PAID";
      order.razorpayPaymentId = payment.id;
      order.paidAt = new Date();
      await order.save();

      for (const item of order.leads) {
        try {
          await markLeadAsPurchased(item.lead, order.user);
        } catch (err) {
          console.warn(err.message);
        }
      }

      await Cart.findOneAndUpdate(
        { user: order.user },
        { $set: { leads: [] } },
      );
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("Webhook Error:", error);
    return res.status(500).json({ success: false });
  }
};

const markLeadAsPurchased = async (leadId, userId) => {
  const updatedLead = await Lead.findOneAndUpdate(
    {
      _id: leadId,
      $expr: { $lt: [{ $size: "$buyers" }, "$maxBuyers"] },
    },
    {
      $push: {
        buyers: {
          user: userId,
          purchasedAt: new Date(),
        },
      },
    },
    { new: true },
  );

  if (!updatedLead) {
    throw new Error("Lead sold out");
  }

  return updatedLead;
};

export { createOrder, verifyPayment, webhookHandler };
