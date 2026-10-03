import { AccountDeletionRequest } from '../Models/accountDeletionRequest.model.js';

export async function requestAccountDeletion(req, res) {
  const { email, phoneNumber, reason = '' } = req.body || {};
  if (typeof email !== 'string' || email.trim().length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim()) ||
      typeof phoneNumber !== 'string' || phoneNumber.length > 30 || !/^\+?[\d\s()-]+$/.test(phoneNumber.trim()) ||
      typeof reason !== 'string' || reason.trim().length > 2000) {
    return res.status(400).json({ success: false, message: 'Enter a valid email, phone number and a reason of up to 2000 characters.' });
  }
  const phone = phoneNumber.trim().replace(/[\s()-]/g, '');
  if (!/^\+?\d{7,15}$/.test(phone)) {
    return res.status(400).json({ success: false, message: 'Enter a valid phone number (7–15 digits).' });
  }
  try {
    const request = await AccountDeletionRequest.create({ email: email.trim().toLowerCase(), phoneNumber: phone, reason: reason.trim() });
    return res.status(201).json({ success: true, requestId: request.id, message: 'Your account deletion request has been received. We will verify account ownership before processing it.' });
  } catch {
    return res.status(503).json({ success: false, message: 'Unable to save your request. Please try again later.' });
  }
}
