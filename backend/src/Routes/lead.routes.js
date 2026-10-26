import express from "express";
import mongoose from 'mongoose';
import { Lead } from '../Models/leads.model.js';
import {
  createLead,
  updateLead,
  deleteLead,
  getLeadDetailsById,
  getAllLeads,
  uploadLeadsFromExcel,
  getUploadStatus,
  getUserHistory,
  downloadLeads
} from "../Controllers/Admin/leads.controller.js";
import { auth, isAdmin, optionalAuth } from "../Middlewares/auth.middleware.js";
import upload from "../Middlewares/fileupload.middleware.js";

const router = express.Router();
router.get('/filter-options', async (req, res) => {
  const query = {};
  if (req.query.category !== undefined) {
    if (typeof req.query.category !== 'string' || !mongoose.isValidObjectId(req.query.category)) return res.status(400).json({ success: false, message: 'Invalid category.' });
    query.category = req.query.category;
  }
  if (req.query.search !== undefined) {
    if (typeof req.query.search !== 'string' || req.query.search.length > 200) return res.status(400).json({ success: false, message: 'Invalid search.' });
    const escaped = req.query.search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    query.$or = [{ title: new RegExp(escaped, 'i') }, { city: new RegExp(escaped, 'i') }];
  }
  try {
    const [projects, properties] = await Promise.all([Lead.distinct('requirement', query), Lead.distinct('propertyType', query)]);
    const options = values => [...new Set(values.filter(value => typeof value === 'string' && value.trim()).map(value => value.trim()))].sort();
    return res.json({ success: true, data: { projectTypes: options(projects), propertyTypes: options(properties) } });
  } catch { return res.status(500).json({ success: false, message: 'Unable to load category filters.' }); }
});

router.get("/get-all-leads", optionalAuth, getAllLeads);
router.get("/get-lead/:id", optionalAuth, getLeadDetailsById);
router.get("/history", auth, getUserHistory );
router.get("/download/:orderId", auth, downloadLeads);

router.post("/create-lead", auth, isAdmin, createLead);
router.put("/update-lead/:id", auth, isAdmin, updateLead);
router.delete("/delete-lead", auth, isAdmin, deleteLead);



router.post("/upload-leads",
  auth,
  isAdmin,
  upload.single("file"),
  uploadLeadsFromExcel,
);
router.get("/upload-status/:id", getUploadStatus);

export default router;
