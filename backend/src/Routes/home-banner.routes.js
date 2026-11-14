import express from 'express';
import multer from 'multer';
import { readFile, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { HomeBanner } from '../Models/home-banner.model.js';
import { auth, isAdmin } from '../Middlewares/auth.middleware.js';

const router = express.Router();
const defaults = {
  business: { title: 'Grow Your Business with NextLead', target: 'leads', file: new URL('../../public/home-banners/business.png', import.meta.url), contentType: 'image/png' },
  membership: { title: 'NextLead Lifetime Membership at ₹499', target: 'membership', file: new URL('../../public/home-banners/membership.webp', import.meta.url), contentType: 'image/webp' },
};
const cache = new Map();
const versionOf = image => createHash('sha256').update(image).digest('hex');
async function fallback(id) {
  const metadata = defaults[id], info = await stat(metadata.file);
  const key = `${info.mtimeMs}:${info.size}`;
  if (cache.get(id)?.key !== key) {
    const image = await readFile(metadata.file);
    cache.set(id, { key, banner: { _id: id, ...metadata, image, version: versionOf(image) } });
  }
  return cache.get(id).banner;
}
const knownSlot = (req, res, next) => Object.hasOwn(defaults, req.params.id)
  ? next() : res.status(404).json({ success: false, message: 'Unknown banner slot.' });

router.get('/home', async (req, res) => {
  try {
    const stored = new Map((await HomeBanner.find().lean()).map(row => [row._id, row]));
    const data = await Promise.all(Object.keys(defaults).map(async id => {
      const row = stored.get(id) ?? await fallback(id);
      return { id, title: row.title, target: row.target, version: row.version,
        imageUrl: `${req.baseUrl}/home/${id}/image?v=${row.version}` };
    }));
    res.set('Cache-Control', 'no-store');
    return res.json({ success: true, data });
  } catch {
    return res.status(503).json({ success: false, message: 'Home banners unavailable. Please retry.' });
  }
});

router.get('/home/:id/image', knownSlot, async (req, res) => {
  try {
    const row = await HomeBanner.findById(req.params.id).select('+image') ?? await fallback(req.params.id);
    res.set({ 'Content-Type': row.contentType, 'Cache-Control': 'public, max-age=0, must-revalidate',
      'ETag': `"${row.version}"`, 'X-Content-Type-Options': 'nosniff' });
    if (req.get('If-None-Match')?.split(',').some(value => value.trim().replace(/^W\//, '') === `"${row.version}"` || value.trim() === '*')) return res.status(304).end();
    return res.send(row.image);
  } catch {
    return res.status(503).json({ success: false, message: 'Banner image unavailable.' });
  }
});

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 4 * 1024 * 1024, files: 1, fields: 2 } }).single('image');
router.put('/home/:id', auth, isAdmin, knownSlot, (req, res, next) => upload(req, res, error => error
  ? res.status(400).json({ success: false, message: 'Upload one PNG, JPEG or WebP image up to 4 MB.' }) : next()), async (req, res) => {
  const image = req.file?.buffer;
  const contentType = !image ? null
    : image.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) ? 'image/png'
    : image.subarray(0, 3).equals(Buffer.from([255, 216, 255])) ? 'image/jpeg'
    : image.subarray(0, 4).toString() === 'RIFF' && image.subarray(8, 12).toString() === 'WEBP' ? 'image/webp' : null;
  const title = req.body.title ?? defaults[req.params.id].title;
  const target = req.body.target ?? defaults[req.params.id].target;
  if (!contentType || typeof title !== 'string' || !title.trim() || title.length > 150 || !['leads', 'membership'].includes(target)) {
    return res.status(400).json({ success: false, message: 'Provide a valid banner image, title and target.' });
  }
  try {
    const version = versionOf(image);
    await HomeBanner.findByIdAndUpdate(req.params.id, { $set: { title: title.trim(), target, image, contentType, version } }, { upsert: true, runValidators: true });
    return res.json({ success: true, data: { id: req.params.id, version } });
  } catch {
    return res.status(503).json({ success: false, message: 'Could not update banner. Please retry.' });
  }
});

export default router;
