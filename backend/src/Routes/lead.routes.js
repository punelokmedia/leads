import express from "express";
import {
  createLead,
  updateLead,
  deleteLead,
  getLeadDetailsById,
  getAllLeads,
  uploadLeadsFromExcel,
  getUploadStatus,
 
} from "../Controllers/Admin/leads.controller.js";
import { auth, isAdmin } from "../Middlewares/auth.middleware.js";
import upload from "../Middlewares/fileupload.middleware.js";

const router = express.Router();

router.get("/get-all-leads", auth, getAllLeads);
router.get("/get-lead/:id", auth, getLeadDetailsById);

router.post("/create-lead", auth, isAdmin, createLead);
router.put("/update-lead/:id", auth, isAdmin, updateLead); 
router.delete("/delete-lead", auth, isAdmin, deleteLead);

router.post(
  "/upload-leads",
  auth,
  isAdmin,
  upload.single("file"),
  uploadLeadsFromExcel,
);

router.get("/upload-status/:id", getUploadStatus);

export default router;
