import mongoose from 'mongoose';
import { Cart } from '../../Models/cart.mode.js';
import { Lead } from '../../Models/leads.model.js';
import { LeadPurchase } from '../../Models/lead.purchase.model.js';
import { Order } from '../../Models/orders.models.js';
import { inventory } from '../../Services/lead-inventory.js';

const addToCart = async (req, res) => {
  try {
    const user = req.user.id;
    const { leadId, quantity = 1 } = req.body;
    if (!mongoose.isValidObjectId(leadId) || quantity !== 1) return res.status(400).json({ success: false, message: 'Choose one access slot per lead. Each buyer can purchase a lead only once.' });
    const lead = await Lead.findById(leadId);
    if (!lead) return res.status(404).json({ success: false, message: 'Lead not found.' });
    const owned = await LeadPurchase.exists({ user, lead: leadId }) || await Order.exists({ user, status: 'PAID', 'leads.lead': leadId });
    if (owned) return res.status(409).json({ success: false, message: 'You already purchased this lead.' });
    const available = inventory(lead);
    const ownReservation = lead.reservations.some((r) => String(r.user) === String(user) && r.expiresAt > new Date());
    if (available.remainingSlots === 0 && !ownReservation) return res.status(409).json({ success: false, code: available.status, message: available.status === 'SOLD_OUT' ? 'Out of stock: two buyers already purchased this lead.' : available.status === 'EXPIRED' ? 'This lead has expired.' : 'Currently unavailable: checkout slots are reserved.' });
    try { await Cart.updateOne({ user }, { $setOnInsert: { user, leads: [] } }, { upsert: true }); }
    catch (error) { if (error.code !== 11000) throw error; }
    await Cart.updateOne({ user, 'leads.lead': { $ne: lead._id } }, { $push: { leads: { lead: lead._id, quantity: 1 } } });
    const cart = await Cart.findOne({ user }).populate('leads.lead', 'title price');
    return res.json({ success: true, message: 'Lead added to cart. One purchase per buyer.', data: cart });
  } catch (error) { console.error('Cart error:', error.message); return res.status(500).json({ success: false, message: 'Could not update cart.' }); }
};

const removeFromCart = async (req, res) => {
  if (!mongoose.isValidObjectId(req.body.leadId)) return res.status(400).json({ success: false, message: 'Valid lead ID required.' });
  const cart = await Cart.findOneAndUpdate({ user: req.user.id }, { $pull: { leads: { lead: req.body.leadId } } }, { returnDocument: "after" });
  return res.json({ success: true, message: 'Lead removed.', data: cart });
};

const clearCart = async (req, res) => {
  const cart = await Cart.findOneAndUpdate({ user: req.user.id }, { $set: { leads: [] } }, { returnDocument: "after" });
  return res.json({ success: true, message: 'Cart cleared.', data: cart });
};

const getCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id }).populate('leads.lead');
    const data = { leads: [], removedLeads: [], totalItems: 0, totalAmount: 0 };
    for (const item of cart?.leads ?? []) {
      const lead = item.lead;
      if (!lead) continue;
      const info = inventory(lead);
      const owned = await LeadPurchase.exists({ user: req.user.id, lead: lead._id });
      const ownReservation = lead.reservations.some((r) => String(r.user) === String(req.user.id) && r.expiresAt > new Date());
      if (owned || (info.remainingSlots === 0 && !ownReservation)) {
        data.removedLeads.push({ _id: lead._id, title: lead.title, reason: owned ? 'Already purchased' : info.status === 'RESERVED' ? 'Currently reserved by other buyers' : 'Out of stock or expired' });
        continue;
      }
      data.leads.push({ _id: lead._id, title: lead.title, price: lead.price, quantity: 1, city: lead.city, state: lead.state, remainingSlots: info.remainingSlots, totalSlots: 2, expiresAt: lead.expiresAt });
      data.totalAmount += lead.price;
    }
    data.totalItems = data.leads.length;
    return res.json({ success: true, message: 'Cart fetched.', data });
  } catch (error) { return res.status(500).json({ success: false, message: 'Could not load cart.' }); }
};

export { addToCart, removeFromCart, clearCart, getCart };
