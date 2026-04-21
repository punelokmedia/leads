import mongoose from "mongoose";
import { Cart } from "../../Models/cart.mode.js";
import { Lead, resolveLeadStatus } from "../../Models/leads.model.js";

const addToCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId, quantity = 1 } = req.body;

    if (!leadId) {
      return res.status(400).json({ success: false, message: "Lead ID is required." });
    }

    if (quantity <= 0) {
      return res.status(400).json({ success: false, message: "Quantity must be at least 1." });
    }

    const lead = await Lead.findById(leadId);

    if (!lead) {
      return res.status(404).json({ success: false, message: "Lead not found." });
    }

    if (lead.expiresAt < new Date()) {
      return res.status(400).json({ success: false, message: "Lead expired." });
    }

    const remaining = lead.maxBuyers - (lead.buyersCount || 0);
    console.log("lead",lead);
    
    console.log("remaining",remaining);
    console.log("quantity",quantity);
    

    if (remaining <= 0) {
      return res.status(400).json({ success: false, message: "Lead sold out." });
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

// const addToCart = async (req, res) => {
//   try {
//     const userId = req.user.id;
//     let { leadId, quantity = 1 } = req.body;

//     // ✅ Validate input
//     if (!leadId || !mongoose.Types.ObjectId.isValid(leadId)) {
//       return res.status(400).json({
//         success: false,
//         message: "Valid Lead ID is required.",
//       });
//     }

//     if (quantity <= 0) {
//       return res.status(400).json({
//         success: false,
//         message: "Quantity must be at least 1.",
//       });
//     }

//     // ✅ Fetch lead
//     const lead = await Lead.findById(leadId);
//     if (!lead) {
//       return res.status(404).json({
//         success: false,
//         message: "Lead not found.",
//       });
//     }

//     if (lead.expiresAt < new Date()) {
//       return res.status(400).json({
//         success: false,
//         message: "Lead expired.",
//       });
//     }

//     const buyersCount = lead.buyersCount || 0;
//     const remaining = lead.maxBuyers - buyersCount;

//     if (remaining <= 0) {
//       return res.status(400).json({
//         success: false,
//         message: "Lead sold out.",
//       });
//     }

//     // Cap max quantity per user
//     quantity = Math.min(quantity, 3);

//     if (quantity > remaining) {
//       return res.status(400).json({
//         success: false,
//         message: `Only ${remaining} slots available.`,
//       });
//     }

//     // ✅ Ensure cart exists
//     await Cart.updateOne(
//       { user: userId },
//       { $setOnInsert: { user: userId, leads: [] } },
//       { upsert: true }
//     );

//     // 🔥 STEP 1: Try atomic update if item exists
//     let cart = await Cart.findOneAndUpdate(
//       {
//         user: userId,
//         "leads.lead": leadId,
//         "leads.quantity": { $lt: 3 },
//       },
//       {
//         $inc: { "leads.$.quantity": quantity },
//       },
//       { new: true }
//     );

//     if (!cart) {
//       // 🔥 STEP 2: Check if already exists but max reached
//       const existingCart = await Cart.findOne({ user: userId });

//       const existingItem = existingCart.leads.find(
//         (i) => i.lead.toString() === leadId
//       );

//       console.log("existingItem",existingItem);
      
//       if (existingItem) {
//         return res.status(400).json({
//           success: false,
//           message: "Max 3 quantity allowed per lead.",
//         });
//       }

//       // 🔥 STEP 3: Push new item
//       cart = await Cart.findOneAndUpdate(
//         { user: userId },
//         {
//           $push: {
//             leads: {
//               lead: leadId,
//               quantity,
//             },
//           },
//         },
//         { new: true }
//       );
//     }

//     // ✅ Populate
//     await cart.populate("leads.lead", "title price");

//     return res.status(200).json({
//       success: true,
//       message: "Cart updated successfully.",
//       data: cart,
//     });
//   } catch (err) {
//     console.error("Add to cart error:", err);

//     return res.status(500).json({
//       success: false,
//       message: "Failed to update cart.",
//     });
//   }
// };

const removeFromCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { leadId, removeAll = false } = req.body;

    const cart = await Cart.findOne({ user: userId });

    if (!cart) {
      return res
        .status(404)
        .json({ success: false, message: "Cart not found." });
    }

    const index = cart.leads.findIndex((i) => i.lead.toString() === leadId);

    if (index === -1) {
      return res
        .status(400)
        .json({ success: false, message: "Lead not in cart." });
    }

    const item = cart.leads[index];

    if (removeAll || item.quantity === 1) {
      cart.leads.splice(index, 1);
    } else {
      item.quantity -= 1;
    }

    await cart.save();

    return res.json({ success: true, message: "Cart updated.", data: cart });
  } catch (err) {
    return res.status(500).json({ success: false, message: "Remove failed." });
  }
};

const clearCart = async (req, res) => {
  const cart = await Cart.findOneAndUpdate(
    { user: req.user.id },
    { leads: [] },
    { new: true },
  );

  return res.json({ success: true, message: "Cart cleared.", data: cart });
};

const getCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id }).populate(
      "leads.lead",
    );

    // 🟡 Case: No cart found
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

      // ❌ Removed leads (expired or sold out)
      if (remaining <= 0) {
        removedLeads.push({
          _id: lead._id,
          title: lead.title,
          reason: "This lead is no longer available (fully booked).",
        });
        continue;
      }

      if (lead.expiresAt < new Date()) {
        removedLeads.push({
          _id: lead._id,
          title: lead.title,
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
        city: lead.city,
        state: lead.state,
        remainingSlots: remaining,
        totalSlots: lead.maxBuyers,
        expiresAt: lead.expiresAt,
      });
    }

    // 🟡 Case: All leads invalid
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

    // 🟢 Case: Some leads removed
    if (removedLeads.length > 0) {
      return res.json({
        success: true,
        message:
          "Cart fetched successfully. Some items were removed as they are no longer available.",
        data: {
          leads: validLeads,
          removedLeads,
          totalItems: validLeads.length,
          totalAmount,
        },
      });
    }

    // 🟢 Case: All good
    return res.json({
      success: true,
      message: "Cart fetched successfully.",
      data: {
        leads: validLeads,
        removedLeads: [],
        totalItems: validLeads.length,
        totalAmount,
      },
    });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch cart at the moment. Please try again later.",
    });
  }
};

//  const addToCart = async (req, res) => {
//   try {
//     const userId = req.user.id;
//     const { leadId } = req.body;

//     if (!leadId) {
//       return res
//         .status(400)
//         .json({ success: false, message: "Lead ID required" });
//     }

//     const lead = await Lead.findById(leadId);
//     if (!lead)
//       return res
//         .status(404)
//         .json({ success: false, message: "Lead not found" });

//     if (lead.maxBuyers <= 0) {
//       return res
//         .status(400)
//         .json({ success: false, message: "Lead not available" });
//     }

//     const remaining = lead.maxBuyers - lead.buyersCount;

//     console.log("lead.maxBuyers",lead.maxBuyers);

//     console.log("remaining",remaining);

//     if (lead.expiresAt < new Date()) {
//       return res.status(400).json({ success: false, message: "Lead expired" });
//     }

//     if (remaining <= 0) {
//       return res.status(400).json({ success: false, message: "Lead sold out" });
//     }

//     let cart = await Cart.findOne({ user: userId });

//     if (!cart) {
//       cart = await Cart.create({
//         user: userId,
//         leads: [{ lead: leadId, quantity: 1 }],
//       });
//     } else {
//       const item = cart.leads.find((i) => i.lead.toString() === leadId);
//       console.log("item.quantity",item.quantity);

//       if (item) {
//         if (item.quantity >= 3) {
//           return res
//             .status(400)
//             .json({ success: false, message: "Max 3 allowed" });
//         }
//         item.quantity += 1;
//       } else {
//         cart.leads.push({ lead: leadId, quantity: 1 });
//       }

//       await cart.save();
//     }

//     return res.json({ success: true, message: "Cart updated", data: cart });
//   } catch (err) {
//     return res.status(500).json({ success: false, message: "Server error" });
//   }
// };

export { addToCart, clearCart, getCart, removeFromCart };
