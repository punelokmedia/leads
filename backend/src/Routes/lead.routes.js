import express from "express";
import {
  createLead,
  updateLead,
  deleteLead,
  getLeadDetailsById,
  getAllLeads,
} from "../Controllers/Admin/leads.controller.js";
import { auth, isAdmin } from "../Middlewares/auth.middleware.js";

const router = express.Router();

router.get("/get-all-leads", auth, getAllLeads);
router.get("/get-lead/:id", auth, getLeadDetailsById);

router.post("/create-lead", auth, isAdmin, createLead);
router.put("/update-lead", auth, isAdmin, updateLead); //need to update
router.delete("/delete-lead", auth, isAdmin, deleteLead);

export default router;
