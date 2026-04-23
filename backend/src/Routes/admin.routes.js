import express from "express";
import { auth, isAdmin } from "../Middlewares/auth.middleware.js";
import {
  sendOtpForAdminLogin,
  verifyAdminOtp,
  changeUserRoleToAdmin,
  removeAdminRole,
  updateUserBlockStatus,
  deleteUserByAdmin,
  getAllUsersAdmin,
  getAllAdmins,
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
router.post("/remove-admin", auth, isAdmin, removeAdminRole);
router.post("/users/block", auth, isAdmin, updateUserBlockStatus);
router.post("/users/delete", auth, isAdmin, deleteUserByAdmin);
router.get("/users", auth, isAdmin, getAllUsersAdmin);
router.get("/admins", auth, isAdmin, getAllAdmins);

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
