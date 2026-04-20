import { Cart } from "../../Models/cart.mode.js";
import { Lead, resolveLeadStatus } from "../../Models/leads.model.js";

const addToCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId } = req.body;

    if (!leadId) {
      return res
        .status(400)
        .json({ success: false, message: "Lead ID required" });
    }

    const lead = await Lead.findById(leadId);
    if (!lead)
      return res
        .status(404)
        .json({ success: false, message: "Lead not found" });

    if (lead.maxBuyers <= 0) {
      return res
        .status(400)
        .json({ success: false, message: "Lead not available" });
    }

    const remaining = lead.maxBuyers - lead.buyers.length;

    if (lead.expiresAt < new Date()) {
      return res.status(400).json({ success: false, message: "Lead expired" });
    }

    if (remaining <= 0) {
      return res.status(400).json({ success: false, message: "Lead sold out" });
    }

    let cart = await Cart.findOne({ user: userId });

    if (!cart) {
      cart = await Cart.create({
        user: userId,
        leads: [{ lead: leadId, quantity: 1 }],
      });
    } else {
      const item = cart.leads.find((i) => i.lead.toString() === leadId);

      if (item) {
        if (item.quantity >= 3) {
          return res
            .status(400)
            .json({ success: false, message: "Max 3 allowed" });
        }
        item.quantity += 1;
      } else {
        cart.leads.push({ lead: leadId, quantity: 1 });
      }

      await cart.save();
    }

    return res.json({ success: true, message: "Cart updated", data: cart });
  } catch (err) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

const removeFromCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId, removeAll = false } = req.body;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required",
      });
    }

    const cart = await Cart.findOne({ user: userId });

    if (!cart) {
      return res.status(404).json({
        success: false,
        message: "Cart not found",
      });
    }

    const itemIndex = cart.leads.findIndex(
      (item) => item.lead.toString() === leadId,
    );

    if (itemIndex === -1) {
      return res.status(400).json({
        success: false,
        message: "Lead not found in cart",
      });
    }

    const item = cart.leads[itemIndex];

    if (removeAll || item.quantity === 1) {
      cart.leads.splice(itemIndex, 1);
    } else {
      item.quantity -= 1;
    }

    await cart.save();

    return res.status(200).json({
      success: true,
      message: removeAll
        ? "Lead removed completely from cart"
        : "Lead quantity updated",
      data: cart,
    });
  } catch (error) {
    console.error("Remove From Cart Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to remove lead from cart",
    });
  }
};

const clearCart = async (req, res) => {
  try {
    const userId = req.user.id;

    const cart = await Cart.findOne({ user: userId });

    if (!cart) {
      return res.status(404).json({
        success: false,
        message: "Cart not found",
      });
    }

    cart.leads = [];
    await cart.save();

    return res.status(200).json({
      success: true,
      message: "Cart cleared successfully",
      data: cart,
    });
  } catch (error) {
    console.error("Clear Cart Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to clear cart",
    });
  }
};

const getCart = async (req, res) => {
  try {
    const userId = req.user.id;

    let cart = await Cart.findOne({ user: userId }).populate({
      path: "leads.lead",
      select: "-phone -customerName",
    });

    if (!cart || cart.leads.length === 0) {
      return res.status(200).json({
        success: true,
        data: { leads: [] },
      });
    }

    const updatedLeads = [];
    const removedLeads = [];

    for (let item of cart.leads) {
      const lead = item.lead;

      if (!lead) continue;

      const remainingSlots = lead.maxBuyers - lead.buyers.length;
      const isExpired = lead.expiresAt < new Date();
      const isSoldOut = remainingSlots <= 0;

      if (isExpired || isSoldOut) {
        removedLeads.push({
          leadId: lead._id,
          title: lead.title,
          reason: isExpired ? "EXPIRED" : "SOLD_OUT",
        });
      } else {
        const allowedQty = Math.min(item.quantity, remainingSlots);

        updatedLeads.push({
          lead: lead._id,
          quantity: allowedQty,
        });
      }
    }

    if (removedLeads.length > 0 || updatedLeads.length !== cart.leads.length) {
      cart.leads = updatedLeads;
      await cart.save();
    }

    cart = await Cart.findOne({ user: userId }).populate({
      path: "leads.lead",
      select: "-phone -customerName",
    });

    const formattedLeads = cart.leads.map((item) => {
      const lead = item.lead;
      const remainingSlots = lead.maxBuyers - lead.buyers.length;

      return {
        _id: lead._id,
        title: lead.title,
        price: lead.price,
        quantity: item.quantity,
        city: lead.city,
        state: lead.state,
        remainingSlots,
        totalSlots: lead.maxBuyers,
        expiresAt: lead.expiresAt,
        totalPrice: lead.price * item.quantity,
      };
    });

    return res.status(200).json({
      success: true,
      message:
        removedLeads.length > 0
          ? "Some unavailable leads were removed from your cart"
          : "Cart fetched successfully",
      data: {
        leads: formattedLeads,
        removedLeads,
        totalItems: formattedLeads.reduce((sum, l) => sum + l.quantity, 0),
        totalAmount: formattedLeads.reduce((sum, l) => sum + l.totalPrice, 0),
      },
    });
  } catch (error) {
    console.error("Get Cart Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch cart",
    });
  }
};

export { addToCart, clearCart, getCart, removeFromCart };
