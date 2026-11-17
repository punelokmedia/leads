import PDFDocument from 'pdfkit';
import { fileURLToPath } from 'node:url';
import mongoose from 'mongoose';
import { Order } from '../Models/orders.models.js';

// Explicit URLs let serverless packagers trace all bundled receipt assets.
const assets = {
  regular: fileURLToPath(new URL('../assets/receipts/NotoSans-Regular.ttf', import.meta.url)),
  bold: fileURLToPath(new URL('../assets/receipts/NotoSans-Bold.ttf', import.meta.url)),
  logo: fileURLToPath(new URL('../assets/receipts/logo.png', import.meta.url)),
};
const fail = (status, message) => { throw Object.assign(new Error(message), { status }); };
const money = value => `₹ ${new Intl.NumberFormat('en-IN', { maximumFractionDigits: 2 }).format(value)}`;

export async function loadReceipt(orderId, userId) {
  if (!mongoose.isValidObjectId(orderId)) fail(400, 'Invalid order reference.');
  let order = await Order.findOne({ _id: orderId, user: userId }).populate({
    path: 'leads.lead', select: 'title category city state areaLocality',
    populate: { path: 'category', select: 'name' },
  }).lean();
  if (!order) fail(404, 'Order not found.');
  if (order.status !== 'PAID') fail(409, 'Receipts are available only for successfully paid orders.');
  if (order.receiptSnapshot) return order.receiptSnapshot;
  if (!Number.isFinite(order.totalAmount) || order.totalAmount <= 0 || !order.leads?.length) fail(409, 'Payment details are incomplete.');
  if (order.currency !== 'INR') fail(409, 'Unsupported receipt currency.');
  if (order.leads.some(item => !Number.isFinite(item.price) || item.price < 0 || !Number.isSafeInteger(item.quantity) || item.quantity < 1)) fail(409, 'Order details are incomplete.');
  const snapshot = {
    receiptNumber: `NL-${order._id}`, orderId: String(order._id), status: 'PAID',
    paidAt: order.paidAt ?? null, amount: order.totalAmount, currency: 'INR',
    paymentMethod: order.paymentMethod === 'WALLET' ? 'NextLead Wallet'
      : order.razorpayPaymentId ? 'Razorpay' : 'Not provided',
    items: order.leads.map(item => ({
      title: item.title || item.lead?.title || 'Lead details unavailable',
      category: item.categoryName || item.lead?.category?.name || 'Not provided',
      location: item.serviceLocation || [item.lead?.areaLocality, item.lead?.city, item.lead?.state].filter(Boolean).join(', ') || 'Not provided',
      price: item.price, quantity: item.quantity,
    })),
  };
  // A single atomic write freezes legacy metadata and resolves simultaneous downloads.
  const saved = await Order.findOneAndUpdate({ _id: order._id, user: userId, status: 'PAID', receiptSnapshot: null },
    { $set: { receiptSnapshot: snapshot } }, { returnDocument: 'after' }).lean();
  if (saved) return saved.receiptSnapshot;
  order = await Order.findOne({ _id: order._id, user: userId, status: 'PAID' }).lean();
  if (!order?.receiptSnapshot) fail(409, 'Payment status changed. Please refresh your order.');
  return order.receiptSnapshot;
}

export function renderReceipt(receipt) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 36, bufferPages: true,
      info: { Title: 'NextLead Payment Receipt', Author: 'NextLead', CreationDate: receipt.paidAt ? new Date(receipt.paidAt) : new Date(0) } });
    const chunks = [];
    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    try {
      doc.registerFont('Regular', assets.regular);
      doc.registerFont('Bold', assets.bold);
      const navy = '#071D49', blue = '#0066FF', light = '#E4F1FF';
      const text = (value, x, y, width, size = 11, bold = false, color = navy, align = 'left') => {
        doc.font(bold ? 'Bold' : 'Regular').fontSize(size).fillColor(color).text(String(value), x, y, { width, align, lineGap: 3 });
        return doc.y;
      };
      const wave = () => {
        doc.save().path('M0 0 L195 0 C110 35 60 115 0 92 Z').fill('#DDF3FF').restore();
        doc.save().path('M0 800 C130 737 225 852 380 808 C475 781 525 755 596 778 L596 842 L0 842 Z').fill('#55BCFF').restore();
        doc.save().path('M0 825 C195 763 300 877 596 800 L596 842 L0 842 Z').fill(blue).restore();
      };
      wave();
      doc.image(assets.logo, 187, 36, { fit: [221, 115], align: 'center', valign: 'center' });
      doc.roundedRect(112, 171, 371, 48, 24).fill(light);
      doc.circle(148, 195, 13).fill('#08A52B');
      doc.save().lineWidth(3).strokeColor('white').moveTo(141, 195).lineTo(146, 200).lineTo(155, 189).stroke().restore();
      text('Payment Receipt', 174, 178, 290, 25, true);
      text('Your payment has been received successfully.', 36, 234, 523, 13, false, '#536176', 'center');
      doc.roundedRect(36, 273, 523, 155, 12).lineWidth(0.8).stroke('#A7CFFF');
      doc.moveTo(298, 289).lineTo(298, 411).stroke('#BCD3ED');
      text('Order ID', 54, 290, 230, 10, false, '#536176');
      text(receipt.orderId, 54, 307, 230, 11, true);
      text('Receipt Number', 54, 338, 230, 10, false, '#536176');
      text(receipt.receiptNumber, 54, 355, 230, 10, true);
      text('Payment Method', 54, 385, 230, 9, false, '#536176');
      text(receipt.paymentMethod, 151, 385, 133, 10, true);
      text('Status', 317, 290, 220, 10, false, '#536176');
      doc.roundedRect(317, 310, 68, 26, 6).fill('#079A26');
      text('PAID', 317, 312, 68, 13, true, 'white', 'center');
      text('Paid at', 317, 350, 220, 10, false, '#536176');
      const date = receipt.paidAt ? new Date(receipt.paidAt) : null;
      text(date && Number.isFinite(date.getTime()) ? new Intl.DateTimeFormat('en-IN', { dateStyle: 'long', timeStyle: 'short', timeZone: 'Asia/Kolkata' }).format(date) + ' IST' : 'Not provided', 317, 370, 220, 10, true);
      let y = 448;
      const heading = () => {
        doc.roundedRect(36, y, 523, 36, 9).fill(light);
        text('Order Details', 54, y + 6, 480, 17, true); y += 49;
      };
      heading();
      for (const item of receipt.items) {
        const title = `${item.title}`;
        const details = `Category: ${item.category}\nService location: ${item.location}`;
        doc.font('Bold').fontSize(12);
        const titleHeight = doc.heightOfString(title, { width: 377, lineGap: 3 });
        doc.font('Regular').fontSize(10);
        const detailHeight = doc.heightOfString(details, { width: 377, lineGap: 3 });
        const height = titleHeight + detailHeight + 27;
        if (y + height > 708) { doc.addPage(); wave(); y = 50; heading(); }
        text(title, 54, y, 377, 12, true);
        text(money(item.price * item.quantity), 437, y, 104, 12, true, navy, 'right');
        text(details, 54, y + titleHeight + 8, 377, 10, false, '#536176');
        y += height;
        doc.moveTo(54, y - 8).lineTo(541, y - 8).stroke('#D8E7F7');
      }
      if (y + 145 > 760) { doc.addPage(); wave(); y = 70; }
      y += 12;
      doc.roundedRect(36, y, 523, 46, 12).fill(light);
      doc.roundedRect(390, y, 169, 46, 12).fill(blue);
      text('Amount Paid (INR)', 54, y + 11, 320, 17, true);
      text(money(receipt.amount), 400, y + 8, 149, 21, true, 'white', 'center');
      text('Thank You!', 36, y + 68, 523, 25, true, blue, 'center');
      text('for choosing NextLead', 36, y + 109, 523, 12, false, '#536176', 'center');
      text('Automatically generated payment receipt', 36, y + 133, 523, 8, false, '#536176', 'center');
      doc.end();
    } catch (error) { doc.destroy(); reject(error); }
  });
}

export async function downloadReceipt(req, res) {
  res.set('Cache-Control', 'private, no-store');
  try {
    const receipt = await loadReceipt(req.params.orderId, req.user.id);
    const pdf = await renderReceipt(receipt);
    return res.set('Content-Type', 'application/pdf')
      .set('Content-Disposition', `attachment; filename="NextLead_Receipt_${receipt.orderId}.pdf"`)
      .send(pdf);
  } catch (error) {
    return res.status(error.status || 500).json({ success: false, message: error.status ? error.message : 'Unable to generate receipt. Please retry.' });
  }
}
