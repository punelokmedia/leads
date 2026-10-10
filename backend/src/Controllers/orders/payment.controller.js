import { exportSecurityAudit } from '../../Services/security-audit.js';
import { WalletTopup } from '../../Models/wallet.model.js';
import { creditCapturedTopup, reverseTopup } from '../../Services/wallet.service.js';
﻿import crypto from 'node:crypto';
import mongoose from 'mongoose';
import { User } from '../../Models/user.model.js';
import { Order } from '../../Models/orders.models.js';
import { razorpay } from '../../Config/razorpay.config.js';
import { reserveCheckout, cancelCheckout, settleCapturedPayment, processRefunds } from '../../Services/checkout.service.js';
import { CheckoutError } from '../../Services/lead-inventory.js';

function respondError(res, error) {
  if (error instanceof CheckoutError) return res.status(error.status).json({ success: false, code: error.code, message: error.message });
  console.error('Checkout error:', error.message);
  return res.status(503).json({ success: false, message: 'Checkout could not be completed. Please retry; check your purchases before paying again.' });
}

export function validSignature(body, signature, secret) {
  if (!secret || typeof signature !== 'string' || !/^[a-f0-9]{64}$/i.test(signature)) return false;
  const expected = crypto.createHmac('sha256', secret).update(body).digest();
  return crypto.timingSafeEqual(expected, Buffer.from(signature, 'hex'));
}

export async function createOrder(req, res) {
  let reserved;
  try {
    const user = await User.findById(req.user.id).select('registrationFeePaid');
    if (!user) throw new CheckoutError('USER_NOT_FOUND', 'User not found.', 404);
    const hasPurchased = await Order.exists({ user: req.user.id, status: 'PAID' });
    if (!user.registrationFeePaid && !hasPurchased) {
      throw new CheckoutError('MEMBERSHIP_REQUIRED', 'Activate lifetime membership for ₹1 before your first lead purchase. No recurring subscription; lead prices are separate.', 403);
    }
    const keyId = process.env.RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY;
    if (!keyId) throw new CheckoutError('PAYMENTS_UNAVAILABLE', 'Payments are not configured.', 503);
    reserved = await reserveCheckout(req.user.id, req.body?.leadIds ?? req.body?.ids);
    let order = reserved.order;
    if (!reserved.reused) {
      const gatewayOrder = await razorpay.orders.create({
        amount: Math.round(order.totalAmount * 100), currency: order.currency,
        receipt: String(order._id), notes: { internalOrderId: String(order._id) },
      });
      await Order.updateOne({ _id: order._id }, { $set: { razorpayOrderId: gatewayOrder.id } });
      order = await Order.findOneAndUpdate({ _id: order._id, status: 'RESERVED', reservationExpiresAt: { $gt: new Date() } }, { $set: { status: 'CREATED' } }, { returnDocument: "after" });
      if (!order) throw new CheckoutError('RESERVATION_EXPIRED', 'Checkout expired or was cancelled. Please start again.');
    }
    return res.status(reserved.reused ? 200 : 201).json({ success: true, message: 'Your slot is reserved for checkout.', data: {
      keyId, razorpayOrderId: order.razorpayOrderId, internalOrderId: order._id,
      amount: order.totalAmount, currency: order.currency, leadsCount: order.leads.length,
      expiresAt: order.reservationExpiresAt,
      expiresIn: Math.max(0, Math.floor((order.reservationExpiresAt.getTime() - Date.now()) / 1000)),
    } });
  } catch (error) {
    if (reserved && !reserved.reused) {
      try { await cancelCheckout(reserved.order._id, req.user.id, 'FAILED'); }
      catch (releaseError) { console.error('Reservation release failed:', releaseError.message); }
    }
    return respondError(res, error);
  }
}

export async function verifyPayment(req, res) {
  try {
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;
    if (typeof razorpayOrderId !== 'string' || typeof razorpayPaymentId !== 'string' || !validSignature(`${razorpayOrderId}|${razorpayPaymentId}`, razorpaySignature, process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_SECRET)) {
      throw new CheckoutError('INVALID_SIGNATURE', 'Invalid payment signature.', 400);
    }
    const order = await Order.findOne({ razorpayOrderId, user: req.user.id });
    if (!order) throw new CheckoutError('ORDER_NOT_FOUND', 'Payment order not found.', 404);
    const payment = await razorpay.payments.fetch(razorpayPaymentId);
    if (payment.order_id !== razorpayOrderId) throw new CheckoutError('PAYMENT_MISMATCH', 'Payment does not belong to this order.', 400);
    const result = await settleCapturedPayment(payment, req.user.id);
    return res.status(result.status === 'PAID' ? 200 : 409).json({ success: result.status === 'PAID', code: result.status, message: result.message, data: result });
  } catch (error) { return respondError(res, error); }
}

export async function cancelOrder(req, res) {
  try {
    const { orderId } = req.body;
    if (!mongoose.isValidObjectId(orderId)) throw new CheckoutError('INVALID_ORDER', 'Invalid order ID.', 400);
    await cancelCheckout(orderId, req.user.id);
    return res.json({ success: true, message: 'Unpaid reservation released.' });
  } catch (error) { return respondError(res, error); }
}

export async function webhookHandler(req, res) {
  try {
    if (!Buffer.isBuffer(req.rawBody) || !validSignature(req.rawBody, req.headers['x-razorpay-signature'], process.env.RAZORPAY_WEBHOOK_SECRET)) {
      return res.status(400).json({ success: false, message: 'Invalid webhook signature.' });
    }
    if (['refund.processed', 'refund.created'].includes(req.body.event)) {
      const id = req.body.payload?.refund?.entity?.payment_id;
      if (typeof id !== 'string') return res.status(400).json({ success: false });
      await reverseTopup(await razorpay.payments.fetch(id));
    }
    if (req.body.event?.startsWith('payment.dispute.')) {
      const id = req.body.payload?.dispute?.entity?.payment_id;
      if (typeof id !== 'string') return res.status(400).json({ success: false });
      // Signed dispute events conservatively freeze and reverse the credited top-up.
      // Winning a dispute requires reviewed restoration; no automatic unlock.
      await reverseTopup(await razorpay.payments.fetch(id), true);
    }
    if (req.body.event === 'payment.captured') {
      const entity = req.body.payload?.payment?.entity;
      if (!entity?.id) return res.status(400).json({ success: false });
      if (await WalletTopup.exists({ gatewayOrderId: entity.order_id })) await creditCapturedTopup(await razorpay.payments.fetch(entity.id));
      // Registration orders have their own verification flow.
      const known = await Order.exists({ razorpayOrderId: entity.order_id });
      if (known) {
        const payment = await razorpay.payments.fetch(entity.id);
        await settleCapturedPayment(payment);
      }
    }
    return res.json({ success: true });
  } catch (error) { return respondError(res, error); }
}

export function startPaymentMaintenance() {
  let running = false;
  const tick = async () => {
    if (running) return;
    running = true;
    try {
      const orders = await Order.find({ fulfillmentVersion: 2, status: { $in: ['CREATED', 'EXPIRED', 'CANCELLED', 'FAILED'] }, razorpayOrderId: { $type: 'string' }, createdAt: { $gte: new Date(Date.now() - 7 * 86400000) } }).sort({ lastReconciledAt: 1 }).limit(20);
      for (const order of orders) {
        try {
          const payments = await razorpay.orders.fetchPayments(order.razorpayOrderId);
          for (const payment of payments.items ?? []) if (payment.status === 'captured') await settleCapturedPayment(payment);
          if (order.reservationExpiresAt <= new Date()) await cancelCheckout(order._id, order.user, 'EXPIRED');
        } catch (error) { console.error('Payment reconciliation failed:', error.message); }
        await Order.updateOne({ _id: order._id }, { $set: { lastReconciledAt: new Date() } });
      }
      const topups = await WalletTopup.find({ status: 'CREATED', gatewayOrderId: { $type: 'string' } }).sort({ updatedAt: 1 }).limit(20);
      for (const topup of topups) {
        try {
          const payments = await razorpay.orders.fetchPayments(topup.gatewayOrderId);
          for (const payment of payments.items ?? []) if (payment.status === 'captured') await creditCapturedTopup(await razorpay.payments.fetch(payment.id));
        } catch (error) { console.error('Top-up reconciliation failed:', error.message); }
        await WalletTopup.updateOne({ _id: topup._id }, { $set: { updatedAt: new Date() } });
      }
      await processRefunds(razorpay);
      await exportSecurityAudit();
    } catch (error) { console.error('Payment maintenance failed:', error.message); }
    finally { running = false; }
  };
  const timer = setInterval(tick, 30000);
  timer.unref();
  return () => clearInterval(timer);
}
