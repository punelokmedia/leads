import { ContactMessage } from '../Models/contact.model.js';

export async function submitContact(req, res) {
  const body = req.body || {};
  const fields = ['name', 'phone', 'email', 'city', 'message', 'requestId'];
  if (fields.some(key => typeof body[key] !== 'string')) return res.status(400).json({ success: false, message: 'Name, phone, email, city and message are required.' });
  const data = Object.fromEntries(fields.map(key => [key, body[key].trim()]));
  data.email = data.email.toLowerCase();
  data.phone = data.phone.replace(/[\s()+-]/g, '').replace(/^91(?=\d{10}$)/, '');
  if (!data.name || data.name.length > 100 || !data.city || data.city.length > 100 || !data.message || data.message.length > 5000 || data.email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email) || !/^[6-9]\d{9}$/.test(data.phone) || !/^[a-f\d]{8}-[a-f\d]{4}-4[a-f\d]{3}-[89ab][a-f\d]{3}-[a-f\d]{12}$/i.test(data.requestId)) {
    return res.status(400).json({ success: false, message: 'Enter a valid name, Indian mobile number, email, city and message (maximum 5,000 characters).' });
  }
  try {
    const existing = await ContactMessage.findOne({ requestId: data.requestId });
    if (existing) {
      if (['name', 'phone', 'email', 'city', 'message'].some(key => existing[key] !== data[key])) return res.status(409).json({ success: false, message: 'This submission reference is already used. Refresh and try again.' });
      return res.json({ success: true, message: 'Your enquiry has been received.', data: { reference: existing._id } });
    }
    const saved = await ContactMessage.create(data);
    return res.status(201).json({ success: true, message: 'Your enquiry has been received. Our team will contact you.', data: { reference: saved._id } });
  } catch (error) {
    if (error.code === 11000) return res.status(409).json({ success: false, message: 'Submission is already being processed. Retry to check confirmation.' });
    return res.status(503).json({ success: false, message: 'Unable to save your enquiry. Please retry or contact us by phone.' });
  }
}
