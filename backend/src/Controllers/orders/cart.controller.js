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
    if (['EXPIRED', 'SOLD_OUT'].includes(available.status) || (available.remainingSlots === 0 && !ownReservation)) return res.status(409).json({ success: false, code: available.status, message: available.status === 'SOLD_OUT' ? 'Out of stock: two buyers already purchased this lead.' : available.status === 'EXPIRED' ? 'This lead has expired.' : 'Currently unavailable: checkout slots are reserved.' });
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
    const cart = await Cart.findOne({ user: req.user.id });
    const data = { leads: [], removedLeads: [], totalItems: 0, totalAmount: 0 };
    const leadIds = (cart?.leads ?? []).map(item => item.lead);
    const [leads, purchases, paidOrders] = await Promise.all([
      Lead.find({ _id: { $in: leadIds } }),
      LeadPurchase.find({ user: req.user.id, lead: { $in: leadIds } }).select('lead'),
      Order.find({ user: req.user.id, status: 'PAID', 'leads.lead': { $in: leadIds } }).select('leads.lead'),
    ]);
    const byId = new Map(leads.map(lead => [String(lead._id), lead]));
    const ownedIds = new Set([
      ...purchases.map(item => String(item.lead)),
      ...paidOrders.flatMap(order => order.leads.map(item => String(item.lead))),
    ]);
    const now = new Date();
    for (const item of cart?.leads ?? []) {
      const lead = byId.get(String(item.lead));
      const info = lead ? inventory(lead, now) : null;
      const ownReservation = lead?.reservations.some(r => String(r.user) === String(req.user.id) && r.expiresAt > now);
      const code = !lead ? 'MISSING' : ownedIds.has(String(lead._id)) ? 'ALREADY_PURCHASED'
        : ['EXPIRED', 'SOLD_OUT'].includes(info.status) ? info.status
        : info.remainingSlots === 0 && !ownReservation ? 'RESERVED' : null;
      if (code) {
        const reasons = { MISSING: 'This lead is no longer available.', ALREADY_PURCHASED: 'Already purchased.', EXPIRED: 'This lead has expired.', SOLD_OUT: 'This lead is sold out.', RESERVED: 'Currently reserved by other buyers.' };
        data.removedLeads.push({ _id: item.lead, title: lead?.title || 'Unavailable lead', code, reason: reasons[code] });
        continue;
      }
      data.leads.push({ _id: lead._id, title: lead.title, price: lead.price, quantity: 1, city: lead.city, state: lead.state, remainingSlots: info.remainingSlots, totalSlots: 2, expiresAt: lead.expiresAt });
      data.totalAmount += lead.price;
    }
    // Remove only the entries observed as unavailable; never overwrite concurrent additions.
    // Checkout still validates every explicitly confirmed ID and never substitutes a new set.
    if (data.removedLeads.length) await Cart.updateOne({ user: req.user.id }, {
      $pull: { leads: { lead: { $in: data.removedLeads.map(item => item._id) } } },
    });
    data.totalItems = data.leads.length;
    return res.json({ success: true, message: 'Cart fetched.', data });
  } catch (error) { return res.status(500).json({ success: false, message: 'Could not load cart.' }); }
};

export { addToCart, removeFromCart, clearCart, getCart };
