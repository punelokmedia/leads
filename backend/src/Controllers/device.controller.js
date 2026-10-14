import { User } from '../Models/user.model.js';
import { parseCoordinates } from '../Utils/location.js';

// These values report device state; they do not grant operating-system access.
export async function updateDevicePermissions(req, res) {
  const body = req.body || {};
  const statuses = ['granted', 'denied', 'not_requested', 'limited'];
  const fields = ['location', 'files'];
  const supplied = fields.filter((field) => Object.hasOwn(body, field));
  if (!supplied.length || supplied.some((field) => !statuses.includes(body[field]) || (field === 'location' && body[field] === 'limited'))) {
    return res.status(400).json({ success: false, message: 'Supply location or files permission: granted, denied, or not_requested (files also accepts limited).' });
  }
  const update = { $set: { 'devicePermissions.updatedAt': new Date() } };
  if ((body.latitude !== undefined || body.longitude !== undefined) && body.location !== 'granted') {
    return res.status(400).json({ success: false, message: 'Location consent must be granted when sending coordinates.' });
  }
  for (const field of supplied) update.$set[`devicePermissions.${field}`] = body[field];
  if (body.location && body.location !== 'granted') {
    update.$unset = { currentLocation: '', locationUpdatedAt: '' };
  } else if (body.latitude !== undefined || body.longitude !== undefined) {
    if (body.location !== 'granted') return res.status(400).json({ success: false, message: 'Location consent must be granted when sending coordinates.' });
    try { update.$set.currentLocation = parseCoordinates(body.latitude, body.longitude); }
    catch (error) { return res.status(400).json({ success: false, message: error.message }); }
    update.$set.locationUpdatedAt = new Date();
  }
  try {
    const user = await User.findByIdAndUpdate(req.user.id, update, { returnDocument: 'after', runValidators: true }).select('devicePermissions currentLocation locationUpdatedAt');
    if (!user) return res.status(404).json({ success: false, message: 'User not found.' });
    return res.json({ success: true, data: user });
  } catch {
    return res.status(500).json({ success: false, message: 'Unable to update device permissions.' });
  }
}

export async function uploadProfilePicture(req, res) {
  const file = req.file;
  const bytes = file?.buffer;
  const valid = bytes && (
    (file.mimetype === 'image/jpeg' && bytes.subarray(0, 3).equals(Buffer.from([255, 216, 255]))) ||
    (file.mimetype === 'image/png' && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) ||
    (file.mimetype === 'image/webp' && bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP')
  );
  if (!valid) return res.status(400).json({ success: false, message: 'Upload a JPEG, PNG or WebP picture in profilePic (maximum 2 MB).' });
  try {
    const user = await User.findByIdAndUpdate(req.user.id, { $set: { profilePic: `data:${file.mimetype};base64,${bytes.toString('base64')}` } }, { returnDocument: 'after', runValidators: true }).select('profilePic');
    if (!user) return res.status(404).json({ success: false, message: 'User not found.' });
    return res.json({ success: true, data: user });
  } catch {
    return res.status(500).json({ success: false, message: 'Unable to upload profile picture.' });
  }
}
