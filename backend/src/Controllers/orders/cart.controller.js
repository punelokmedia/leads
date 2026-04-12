import { Cart } from "../../Models/cart.mode.js";
import { Lead } from "../../Models/leads.model.js";

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

    if (!lead || lead.status !== "ACTIVE") {
      return res.status(400).json({
        success: false,
        message: "This lead is not available",
      });
    }

    // ❌ Expired
    if (lead.expiresAt < new Date()) {
      return res.status(400).json({
        success: false,
        message: "This lead has expired",
      });
    }

    // ❌ Sold out
    if (lead.buyers.length >= lead.maxBuyers) {
      return res.status(400).json({
        success: false,
        message: "This lead is already sold out",
      });
    }

    let cart = await Cart.findOne({ user: userId });

    if (!cart) {
      cart = await Cart.create({ user: userId, leads: [leadId] });

      return res.status(201).json({
        success: true,
        message: "Lead added to cart successfully",
        data: cart,
      });
    }

    // ❌ Already in cart
    if (cart.leads.includes(leadId)) {
      return res.status(400).json({
        success: false,
        message: "Lead is already in your cart",
      });
    }

    cart.leads.push(leadId);
    await cart.save();

    return res.status(200).json({
      success: true,
      message: "Lead added to cart successfully",
      data: cart,
    });
  } catch (error) {
    console.error("Add To Cart Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to add lead to cart. Please try again.",
    });
  }
};

const removeFromCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId } = req.body;

    const cart = await Cart.findOne({ user: userId });

    if (!cart) {
      return res.status(404).json({
        success: false,
        message: "Cart not found",
      });
    }

    cart.leads = cart.leads.filter((id) => id.toString() !== leadId);

    await cart.save();

    return res.status(200).json({
      success: true,
      message: "Lead removed from cart",
      data: cart,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to remove lead",
    });
  }
};

const clearCart = async (req, res) => {
  try {
    const userId = req.user.id;

    await Cart.findOneAndUpdate({ user: userId }, { leads: [] }, { new: true });

    return res.status(200).json({
      success: true,
      message: "Cart cleared successfully",
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to clear cart",
    });
  }
};

const getCart = async (req, res) => {
  try {
    const userId = req.user.id;

    const cart = await Cart.findOne({ user: userId }).populate({
      path: "leads",
      select: "-buyers -phone -owner", // hide sensitive fields
    });

    if (!cart) {
      return res.status(200).json({
        success: true,
        data: { leads: [] },
      });
    }

    return res.status(200).json({
      success: true,
      data: cart,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch cart",
    });
  }
};

export { addToCart, clearCart, getCart, removeFromCart };
