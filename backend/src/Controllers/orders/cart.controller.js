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

    if (status === "EXPIRED") {
      return res.status(400).json({
        success: false,
        message: "This lead has expired and cannot be added to cart",
      });
    }

    if (status === "SOLD_OUT") {
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
      message: "Lead added to cart successfully",
      data: cart,
    });
  } catch (error) {
    console.error("Add To Cart Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to add lead to cart",
      error: error.message,
    });
  }
};

const removeFromCart = async (req, res) => {
  const cart = await Cart.findOne({ user: req.user.id });

  if (!cart) return res.status(404).json({ success: false });

  cart.leads = cart.leads.filter((id) => id.toString() !== req.body.leadId);

  await cart.save();

  res.json({ success: true, message: "Removed" });
};

const clearCart = async (req, res) => {
  await Cart.findOneAndUpdate({ user: req.user.id }, { leads: [] });

  res.json({ success: true, message: "Cart cleared" });
};

const getCart = async (req, res) => {
  const cart = await Cart.findOne({ user: req.user.id }).populate({
    path: "leads",
    select: "-phone -customerName -buyers",
  });

  res.json({
    success: true,
    data: cart || { leads: [] },
  });
};

export { addToCart, clearCart, getCart, removeFromCart };
