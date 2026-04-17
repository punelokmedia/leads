import { Cart } from "../../Models/cart.mode.js";
import { Lead, resolveLeadStatus } from "../../Models/leads.model.js";

const addToCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId } = req.body;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required",
      });
    }

    const lead = await Lead.findById(leadId);

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    const status = resolveLeadStatus(lead);
    const remainingSlots = lead.maxBuyers - lead.buyers.length;

    if (status === "EXPIRED") {
      return res.status(400).json({
        success: false,
        message: "This lead has expired",
        remainingSlots: 0,
      });
    }

    if (status === "SOLD_OUT") {
      return res.status(400).json({
        success: false,
        message: "This lead is already sold out",
        remainingSlots: 0,
      });
    }

    let cart = await Cart.findOne({ user: userId });

    if (!cart) {
      cart = await Cart.create({ user: userId, leads: [leadId] });

      return res.status(201).json({
        success: true,
        message: `Lead added to cart. Only ${remainingSlots} slots left`,
        data: cart,
        remainingSlots,
        totalSlots: lead.maxBuyers,
      });
    }

    const exists = cart.leads.some((id) => id.toString() === leadId);

    if (exists) {
      return res.status(400).json({
        success: false,
        message: "This lead is already in your cart",
      });
    }

    cart.leads.push(leadId);
    await cart.save();

    return res.status(200).json({
      success: true,
      message: `Lead added to cart. Only ${remainingSlots} slots left`,
      data: cart,
      remainingSlots,
      totalSlots: lead.maxBuyers,
    });
  } catch (error) {
    console.error("Add To Cart Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to add lead to cart",
    });
  }
};

const removeFromCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId } = req.body;

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

    const exists = cart.leads.some((id) => id.toString() === leadId);

    if (!exists) {
      return res.status(400).json({
        success: false,
        message: "Lead not found in cart",
      });
    }

    cart.leads = cart.leads.filter((id) => id.toString() !== leadId);

    await cart.save();

    return res.status(200).json({
      success: true,
      message: "Lead removed from cart successfully",
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
      path: "leads",
      select: "-phone -customerName",
    });

    if (!cart || cart.leads.length === 0) {
      return res.status(200).json({
        success: true,
        data: { leads: [] },
      });
    }

    const validLeads = [];
    const removedLeads = [];

    for (let lead of cart.leads) {
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
        validLeads.push(lead._id);
      }
    }

    if (removedLeads.length > 0) {
      cart.leads = validLeads;
      await cart.save();
    }

    cart = await Cart.findOne({ user: userId }).populate({
      path: "leads",
      select: "-phone -customerName",
    });

    const formattedLeads = cart.leads.map((lead) => {
      const remainingSlots = lead.maxBuyers - lead.buyers.length;

      return {
        _id: lead._id,
        title: lead.title,
        price: lead.price,
        city: lead.city,
        state: lead.state,
        remainingSlots,
        totalSlots: lead.maxBuyers,
        expiresAt: lead.expiresAt,
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
        totalItems: formattedLeads.length,
        totalAmount: formattedLeads.reduce((sum, l) => sum + l.price, 0),
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
