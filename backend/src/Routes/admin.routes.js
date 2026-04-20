import express from "express";
import { auth, isAdmin } from "../Middlewares/auth.middleware.js";
import {
  sendOtpForAdminLogin,
  verifyAdminOtp,
  changeUserRoleToAdmin,
} from "../Controllers/Admin/admin.controller.js";

const router = express.Router();

router.post("/send-otp", sendOtpForAdminLogin);
router.post("/verify-otp", verifyAdminOtp);

router.post("/make-admin", auth, isAdmin, changeUserRoleToAdmin);

export default router;
