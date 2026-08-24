import express from "express";
import passport from "../Config/passport.js";
import { auth } from "../Middlewares/auth.middleware.js";
import {
  googleCallback,
  registerUser,
  loginUser,
  forgetPassword,
  resetPassword,
  addAddress,
  logOutUser,
  getUserProfile,
  updateUserProfile,
  verifyOtp,
  requestMobileOtp,
  requestSessionMobileOtp,
  verifyMobileOtp,
  verifySessionMobileOtp,
  completeMobileProfile,
  createMobileRegistrationOrder,
  verifyMobileRegistrationPayment,
} from "../Controllers/auth.controller.js";

const router = express.Router();

router.get(
  "/google",
  passport.authenticate("google", {
    scope: ["profile", "email"],
    session: false,
  }),
);

router.get(
  "/google/callback",
  (req, res, next) => {
    passport.authenticate("google", (err, user) => {
      if (err) {
        return res.status(500).json({
          success: false,
          code: "OAUTH_ERROR",
          message: "Google authentication failed. Please try again.",
          error: err.message,
        });
      }

      if (!user) {
        return res.status(400).json({
          success: false,
          code: "OAUTH_USER_NOT_FOUND",
          message: "Unable to retrieve user information from Google.",
        });
      }

      req.user = user;
      next();
    })(req, res, next);
  },
  googleCallback,
);

router.post("/register", registerUser);
router.post("/login", loginUser);
router.get("/profile", auth, getUserProfile);
router.get("/logout", auth, logOutUser);
router.put("/update-profile", auth, updateUserProfile);

router.post("/add-address", auth, addAddress);

router.post("/forgot-password", forgetPassword);
router.post("/verify-otp", verifyOtp);
router.post("/reset-password", resetPassword);
router.post("/mobile/request-otp", requestMobileOtp);
router.post("/mobile/verify-otp", verifyMobileOtp);
router.post("/mobile/request-otp-session", auth, requestSessionMobileOtp);
router.post("/mobile/verify-otp-session", auth, verifySessionMobileOtp);
router.post("/mobile/complete-profile", auth, completeMobileProfile);
router.put("/mobile/complete-profile", auth, completeMobileProfile);
router.post("/mobile/create-registration-order", auth, createMobileRegistrationOrder);
router.post("/mobile/verify-registration-payment", auth, verifyMobileRegistrationPayment);

export default router;
