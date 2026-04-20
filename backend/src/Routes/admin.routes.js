import express from "express";
import { auth, isAdmin } from "../Middlewares/auth.middleware.js";
import {
  sendOtpForAdminLogin,
  verifyAdminOtp,
  changeUserRoleToAdmin,
  getDashboardOverview,
  getRevenueAnalytics,
  getTopCategories,
  getRecentOrders,
  getAllLeadsAdmin,
  getLeadByIdAdmin,
} from "../Controllers/Admin/admin.controller.js";

const router = express.Router();

/**
 * 🔐 ADMIN AUTH
 */
router.post("/send-otp", sendOtpForAdminLogin);
router.post("/verify-otp", verifyAdminOtp);

/**
 * 👨‍💼 ADMIN MANAGEMENT
 */
router.post("/make-admin", auth, isAdmin, changeUserRoleToAdmin);

/**
 * 📊 DASHBOARD ANALYTICS (ALL PROTECTED)
 */
router.get("/dashboard/overview", auth, isAdmin, getDashboardOverview);
router.get("/dashboard/revenue", auth, isAdmin, getRevenueAnalytics);
router.get("/dashboard/top-categories", auth, isAdmin, getTopCategories);
router.get("/dashboard/recent-orders", auth, isAdmin, getRecentOrders);


/**
 * 📊 leads details (for admin)
 */
router.get("/dashboard/get-all-leads", auth, isAdmin, getAllLeadsAdmin);
router.get("/dashboard/get-leads/:id", auth, isAdmin, getLeadByIdAdmin);

export default router;
