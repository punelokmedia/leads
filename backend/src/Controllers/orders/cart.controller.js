import mongoose from "mongoose";
import { Cart } from "../../Models/cart.mode.js";
import { Lead, resolveLeadStatus } from "../../Models/leads.model.js";

const addToCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId, quantity = 1 } = req.body;

    if (!leadId) {
      return res
        .status(400)
        .json({ success: false, message: "Lead ID is required." });
    }

    if (quantity <= 0) {
      return res
        .status(400)
        .json({ success: false, message: "Quantity must be at least 1." });
    }

    const lead = await Lead.findById(leadId);

    if (!lead) {
      return res
        .status(404)
        .json({ success: false, message: "Lead not found." });
    }

    if (lead.expiresAt < new Date()) {
      return res.status(400).json({ success: false, message: "Lead expired." });
    }

    const remaining = lead.maxBuyers - (lead.buyersCount || 0);

    if (remaining <= 0) {
      return res
        .status(400)
        .json({ success: false, message: "Lead sold out." });
    }

    if (quantity > remaining) {
      return res.status(400).json({
        success: false,
        message: `Only ${remaining} slots available.`,
      });
    }

    let cart = await Cart.findOne({ user: userId });

    if (!cart) {
      cart = await Cart.create({
        user: userId,
        leads: [{ lead: leadId, quantity }],
      });
    } else {
      const item = cart.leads.find((i) => i.lead.toString() === leadId);

      if (item) {
        const newQty = item.quantity + quantity;

        if (newQty > 3) {
          return res.status(400).json({
            success: false,
            message: "Max 3 quantity allowed per lead.",
          });
        }

        if (newQty > remaining) {
          return res.status(400).json({
            success: false,
            message: `Only ${remaining} slots available.`,
          });
        }

        item.quantity = newQty;
      } else {
        if (quantity > 3) {
          return res.status(400).json({
            success: false,
            message: "Max 3 quantity allowed per lead.",
          });
        }

        cart.leads.push({ lead: leadId, quantity });
      }

      await cart.save();
    }

    await cart.populate("leads.lead", "title price");

    return res.status(200).json({
      success: true,
      message: "Cart updated successfully.",
      data: cart,
    });
  } catch (err) {
    console.error("Add to cart error:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to update cart.",
    });
  }
};

const removeFromCart = async (req, res) => {
  try {
    const userId = req.user.id;
    let { leadId, quantity = 1 } = req.body;

    if (!leadId || !mongoose.Types.ObjectId.isValid(leadId)) {
      return res.status(400).json({
        success: false,
        message: "Valid Lead ID is required.",
      });
    }

    if (quantity <= 0) {
      return res.status(400).json({
        success: false,
        message: "Quantity must be at least 1.",
      });
    }

    const cart = await Cart.findOne({ user: userId });

    if (!cart) {
      return res.status(404).json({
        success: false,
        message: "Cart not found.",
      });
    }

    const item = cart.leads.find((i) => i.lead.toString() === leadId);

    if (!item) {
      return res.status(400).json({
        success: false,
        message: "Lead not found in cart.",
      });
    }

    if (quantity >= item.quantity) {
      cart.leads = cart.leads.filter((i) => i.lead.toString() !== leadId);
    } else {
      item.quantity -= quantity;
    }

    await cart.save();

    await cart.populate("leads.lead", "title price");

    return res.json({
      success: true,
      message: "Cart updated successfully.",
      data: cart,
    });
  } catch (err) {
    console.error("Remove from cart error:", err);

    return res.status(500).json({
      success: false,
      message: "Failed to update cart.",
    });
  }
};

const clearCart = async (req, res) => {
  const cart = await Cart.findOneAndUpdate(
    { user: req.user.id },
    { leads: [] },
    { new: true },
  );

  return res.json({
    success: true,
    message: "Cart cleared.",
    data: cart,
  });
};

const getCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id }).populate(
      "leads.lead",
    );

    if (!cart) {
      return res.json({
        success: true,
        message: "Cart is empty. Start adding leads to proceed.",
        data: {
          leads: [],
          removedLeads: [],
          totalItems: 0,
          totalAmount: 0,
        },
      });
    }

    const validLeads = [];
    const removedLeads = [];
    let totalAmount = 0;

    for (let item of cart.leads) {
      const lead = item.lead;

      if (!lead) continue;

      const remaining = lead.maxBuyers - (lead.buyersCount || 0);

      if (remaining <= 0) {
        removedLeads.push({
          _id: lead._id,
          title: lead.title,
          quantity: item.quantity,
          reason: "This lead is no longer available (fully booked).",
        });
        continue;
      }

      if (lead.expiresAt < new Date()) {
        removedLeads.push({
          _id: lead._id,
          title: lead.title,
          quantity: item.quantity,
          reason: "This lead has expired.",
        });
        continue;
      }

      const quantity = Math.min(item.quantity, remaining);

      totalAmount += lead.price * quantity;

      validLeads.push({
        _id: lead._id,
        title: lead.title,
        price: lead.price,
        quantity,
        city: lead.city,
        state: lead.state,
        remainingSlots: remaining,
        totalSlots: lead.maxBuyers,
        expiresAt: lead.expiresAt,
      });
    }

    const totalItems = validLeads.reduce((sum, item) => sum + item.quantity, 0);

    if (validLeads.length === 0 && removedLeads.length > 0) {
      return res.json({
        success: true,
        message:
          "All items in your cart are no longer available. Please add new leads.",
        data: {
          leads: [],
          removedLeads,
          totalItems: 0,
          totalAmount: 0,
        },
      });
    }

    if (removedLeads.length > 0) {
      return res.json({
        success: true,
        message:
          "Cart fetched successfully. Some items were removed as they are no longer available.",
        data: {
          leads: validLeads,
          removedLeads,
          totalItems,
          totalAmount,
        },
      });
    }

    return res.json({
      success: true,
      message: "Cart fetched successfully.",
      data: {
        leads: validLeads,
        removedLeads: [],
        totalItems,
        totalAmount,
      },
    });
  } catch (err) {
    console.error("Get cart error:", err);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch cart at the moment. Please try again later.",
    });
  }
};

// const getCart = async (req, res) => {
//   try {
//     const cart = await Cart.findOne({ user: req.user.id }).populate(
//       "leads.lead",
//     );

//     // 🟡 Case: No cart found
//     if (!cart) {
//       return res.json({
//         success: true,
//         message: "Cart is empty. Start adding leads to proceed.",
//         data: {
//           leads: [],
//           removedLeads: [],
//           totalItems: 0,
//           totalAmount: 0,
//         },
//       });
//     }

//     const validLeads = [];
//     const removedLeads = [];
//     let totalAmount = 0;

//     for (let item of cart.leads) {
//       const lead = item.lead;

//       if (!lead) continue;

//       const remaining = lead.maxBuyers - (lead.buyersCount || 0);

//       // ❌ Removed leads (expired or sold out)
//       if (remaining <= 0) {
//         removedLeads.push({
//           _id: lead._id,
//           title: lead.title,
//           reason: "This lead is no longer available (fully booked).",
//         });
//         continue;
//       }

//       if (lead.expiresAt < new Date()) {
//         removedLeads.push({
//           _id: lead._id,
//           title: lead.title,
//           reason: "This lead has expired.",
//         });
//         continue;
//       }

//       const quantity = Math.min(item.quantity, remaining);

//       totalAmount += lead.price * quantity;

//       validLeads.push({
//         _id: lead._id,
//         title: lead.title,
//         price: lead.price,
//         city: lead.city,
//         state: lead.state,
//         remainingSlots: remaining,
//         totalSlots: lead.maxBuyers,
//         expiresAt: lead.expiresAt,
//       });
//     }

//     // 🟡 Case: All leads invalid
//     if (validLeads.length === 0 && removedLeads.length > 0) {
//       return res.json({
//         success: true,
//         message:
//           "All items in your cart are no longer available. Please add new leads.",
//         data: {
//           leads: [],
//           removedLeads,
//           totalItems: 0,
//           totalAmount: 0,
//         },
//       });
//     }

//     // 🟢 Case: Some leads removed
//     if (removedLeads.length > 0) {
//       return res.json({
//         success: true,
//         message:
//           "Cart fetched successfully. Some items were removed as they are no longer available.",
//         data: {
//           leads: validLeads,
//           removedLeads,
//           totalItems: validLeads.length,
//           totalAmount,
//         },
//       });
//     }

//     // 🟢 Case: All good
//     return res.json({
//       success: true,
//       message: "Cart fetched successfully.",
//       data: {
//         leads: validLeads,
//         removedLeads: [],
//         totalItems: validLeads.length,
//         totalAmount,
//       },
//     });
//   } catch (err) {
//     console.error(err);

//     return res.status(500).json({
//       success: false,
//       message: "Unable to fetch cart at the moment. Please try again later.",
//     });
//   }
// };

export { addToCart, clearCart, getCart, removeFromCart };
