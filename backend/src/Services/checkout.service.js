import crypto from 'node:crypto';
import mongoose from 'mongoose';
import { Lead } from '../Models/leads.model.js';
import { Order } from '../Models/orders.models.js';
import { Cart } from '../Models/cart.mode.js';
import { LeadPurchase } from '../Models/lead.purchase.model.js';
import { PaymentRefund } from '../Models/payment-refund.model.js';
import { BUYER_LIMIT, RESERVATION_MS, CheckoutError, inventory } from './lead-inventory.js';

const activeStates = ['RESERVED', 'CREATED'];
const transactionOptions = { readConcern: { level: 'snapshot' }, writeConcern: { w: 'majority' } };
const sameId = (a, b) => String(a) === String(b);

async function transaction(work) {
  const session = await mongoose.startSession();
  try { return await session.withTransaction(() => work(session), transactionOptions); }
  finally { await session.endSession(); }
}

async function release(order, session) {
  await Lead.updateMany({ 'reservations.order': order._id }, {
    $pull: { reservations: { order: order._id } },
  }, { session });
}

export async function reserveCheckout(userId, selectedIds) {
  return transaction(async (session) => {
    const now = new Date();
    const cart = await Cart.findOne({ user: userId }).session(session);
    if (!cart?.leads.length) throw new CheckoutError('EMPTY_CART', 'Your cart is empty.', 400);
    if (selectedIds !== undefined && (!Array.isArray(selectedIds) || !selectedIds.length || selectedIds.some((id) => !mongoose.isValidObjectId(id)))) {
      throw new CheckoutError('INVALID_SELECTION', 'Select valid leads from your cart.', 400);
    }
    const ids = [...new Set((selectedIds ?? cart.leads.map((i) => i.lead)).map(String))].sort();
    const items = ids.map((id) => cart.leads.find((item) => sameId(item.lead, id)));
    if (items.some((item) => !item || item.quantity !== 1)) {
      throw new CheckoutError('ONE_PER_BUYER', 'Each buyer can purchase a lead only once. Remove old quantities and add it again.', 400);
    }
    const hash = crypto.createHash('sha256').update(ids.join('|')).digest('hex');
    const existing = await Order.findOne({ user: userId, cartHash: hash, status: { $in: activeStates }, reservationExpiresAt: { $gt: now } }).session(session);
    if (existing) {
      if (!existing.razorpayOrderId) throw new CheckoutError('CHECKOUT_PREPARING', 'Checkout is being prepared. Please retry shortly.');
      return { order: existing, reused: true };
    }
    const orderId = new mongoose.Types.ObjectId();
    const deadline = new Date(now.getTime() + RESERVATION_MS);
    const lines = [];
    for (const item of items) {
      const owned = await LeadPurchase.exists({ lead: item.lead, user: userId }).session(session);
      // Also block repeat sales to legacy paid-order holders, even if old purchase records are incomplete.
      const legacyPaid = await Order.exists({ user: userId, status: 'PAID', 'leads.lead': item.lead }).session(session);
      if (owned || legacyPaid) throw new CheckoutError('ALREADY_PURCHASED', 'You have already purchased this lead.');
      await Lead.updateOne({ _id: item.lead }, { $pull: { reservations: { expiresAt: { $lte: now } } } }, { session });
      const lead = await Lead.findOneAndUpdate({
        _id: item.lead, expiresAt: { $gt: now },
        'reservations.user': { $ne: new mongoose.Types.ObjectId(String(userId)) },
        $expr: { $lt: [{ $add: [{ $ifNull: ['$buyersCount', 0] }, { $size: { $ifNull: ['$reservations', []] } }] }, BUYER_LIMIT] },
      }, {
        $set: { maxBuyers: BUYER_LIMIT },
        $push: { reservations: { order: orderId, user: userId, expiresAt: deadline } },
      }, { new: true, session });
      if (!lead) {
        const current = await Lead.findById(item.lead).session(session);
        const status = current ? inventory(current, now).status : 'MISSING';
        throw new CheckoutError(status, status === 'SOLD_OUT' ? 'Out of stock: two buyers already purchased this lead.' : status === 'EXPIRED' ? 'This lead has expired.' : 'Currently unavailable: checkout slots are reserved. Please try later.');
      }
      lines.push({ lead: lead._id, quantity: 1, price: lead.price });
    }
    const [order] = await Order.create([{
      _id: orderId, user: userId, leads: lines,
      totalAmount: Math.round(lines.reduce((total, l) => total + l.price, 0) * 100) / 100,
      currency: 'INR', status: 'RESERVED', cartHash: hash,
      reservationExpiresAt: deadline, fulfillmentVersion: 2,
    }], { session });
    return { order, reused: false };
  });
}

export async function cancelCheckout(orderId, userId, status = 'CANCELLED') {
  return transaction(async (session) => {
    const order = await Order.findOneAndUpdate({ _id: orderId, user: userId, status: { $in: activeStates } }, { $set: { status } }, { new: true, session });
    if (order) await release(order, session);
    return order;
  });
}

async function queueRefund(order, payment, reason, session) {
  await PaymentRefund.updateOne({ paymentId: payment.id }, { $setOnInsert: {
    order: order._id, amount: payment.amount, status: 'PENDING', nextAttemptAt: new Date(),
  } }, { upsert: true, session });
  if (order.status !== 'PAID') {
    order.status = 'REFUND_PENDING';
    order.razorpayPaymentId = payment.id;
    order.failureReason = reason;
    await order.save({ session });
    await release(order, session);
  }
  return { status: 'REFUND_PENDING', orderId: order._id, message: 'The reservation is no longer valid. Your payment is queued for a full refund; no contact access was granted.' };
}

// Both the app callback and signed webhook call this exact transaction.
export async function settleCapturedPayment(payment, userId) {
  if (payment.status !== 'captured') throw new CheckoutError('PAYMENT_PENDING', 'Payment is awaiting capture. Check your purchases shortly.', 202);
  return transaction(async (session) => {
    const now = new Date();
    const order = await Order.findOne({ razorpayOrderId: payment.order_id }).session(session);
    if (!order || (userId && !sameId(order.user, userId))) throw new CheckoutError('ORDER_NOT_FOUND', 'Payment order not found.', 404);
    if (order.status === 'PAID') {
      if (order.razorpayPaymentId === payment.id) return { status: 'PAID', orderId: order._id, message: 'Payment already confirmed.' };
      return queueRefund(order, payment, 'Duplicate payment', session);
    }
    if (order.status === 'REFUNDED' && order.razorpayPaymentId === payment.id) return { status: 'REFUNDED', orderId: order._id, message: 'Payment refunded.' };
    if (!activeStates.includes(order.status) || order.fulfillmentVersion !== 2 || !order.reservationExpiresAt || order.reservationExpiresAt <= now) {
      return queueRefund(order, payment, 'Reservation expired or cancelled', session);
    }
    if (payment.currency !== order.currency || payment.amount !== Math.round(order.totalAmount * 100)) {
      return queueRefund(order, payment, 'Payment amount or currency mismatch', session);
    }
    const leads = [];
    for (const item of order.leads) {
      const lead = await Lead.findById(item.lead).session(session);
      const owned = await LeadPurchase.exists({ lead: item.lead, user: order.user }).session(session);
      const hasReservation = lead?.reservations.some((r) => sameId(r.order, order._id) && sameId(r.user, order.user) && r.expiresAt > now);
      if (!lead || owned || item.quantity !== 1 || !hasReservation || lead.expiresAt <= now || lead.buyersCount >= BUYER_LIMIT) {
        return queueRefund(order, payment, 'Lead no longer available', session);
      }
      leads.push(lead);
    }
    // All lines are valid. These writes and the paid state commit together, or none do.
    for (const lead of leads) {
      const updated = await Lead.findOneAndUpdate({
        _id: lead._id, buyersCount: { $lt: BUYER_LIMIT },
        reservations: { $elemMatch: { order: order._id, user: order.user, expiresAt: { $gt: now } } },
      }, { $inc: { buyersCount: 1 }, $pull: { reservations: { order: order._id } }, $set: { maxBuyers: BUYER_LIMIT, status: lead.buyersCount + 1 >= BUYER_LIMIT ? 'SOLD_OUT' : 'ACTIVE' } }, { new: true, session });
      if (!updated) throw new Error('Reservation changed while completing purchase');
      await LeadPurchase.create([{ lead: lead._id, user: order.user, order: order._id, quantity: 1, fulfillmentVersion: 2 }], { session });
    }
    order.status = 'PAID';
    order.razorpayPaymentId = payment.id;
    order.paidAt = now;
    await order.save({ session });
    await Cart.updateOne({ user: order.user }, { $pull: { leads: { lead: { $in: order.leads.map((i) => i.lead) } } } }, { session });
    return { status: 'PAID', orderId: order._id, message: 'Payment confirmed. Contact access unlocked.' };
  });
}

// A durable refund queue survives app/webhook retries and server restarts.
export async function processRefunds(gateway) {
  const now = new Date();
  const jobs = await PaymentRefund.find({ status: { $ne: 'REFUNDED' }, nextAttemptAt: { $lte: now }, $or: [{ lockedUntil: { $exists: false } }, { lockedUntil: { $lte: now } }] }).limit(20).lean();
  for (const job of jobs) {
    const lockedUntil = new Date(Date.now() + 120000);
    const claimed = await PaymentRefund.findOneAndUpdate({ _id: job._id, $or: [{ lockedUntil: { $exists: false } }, { lockedUntil: { $lte: now } }] }, { $set: { lockedUntil }, $inc: { attempts: 1 } }, { new: true });
    if (!claimed) continue;
    try {
      const payment = await gateway.payments.fetch(job.paymentId);
      let refundId = claimed.refundId;
      let status = 'SUBMITTED';
      if (payment.amount_refunded >= job.amount && payment.status === 'refunded') {
        status = 'REFUNDED';
      } else if (!refundId && !payment.amount_refunded) {
        // Always request the FULL captured amount. The gateway rejects any request
        // exceeding the unrefunded amount, including a retry after a lost response.
        const refund = await gateway.payments.refund(job.paymentId, { amount: job.amount, receipt: String(job._id), notes: { reason: 'Lead reservation unavailable' } });
        refundId = refund.id;
        status = refund.status === 'processed' ? 'REFUNDED' : 'SUBMITTED';
      } else if (payment.amount_refunded < job.amount) {
        throw new Error('Partial refund requires reconciliation; no additional refund submitted');
      }
      await PaymentRefund.updateOne({ _id: job._id, lockedUntil }, { $set: { status, refundId, nextAttemptAt: new Date(Date.now() + 60000) }, $unset: { lockedUntil: 1, lastError: 1 } });
      if (status === 'REFUNDED') await Order.updateOne({ _id: job.order, status: 'REFUND_PENDING', razorpayPaymentId: job.paymentId }, { $set: { status: 'REFUNDED' } });
    } catch (error) {
      await PaymentRefund.updateOne({ _id: job._id, lockedUntil }, { $set: { lastError: error.message || 'Refund failed', nextAttemptAt: new Date(Date.now() + 60000) }, $unset: { lockedUntil: 1 } });
    }
  }
}
