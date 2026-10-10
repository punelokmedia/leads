import express from "express";
import { exchangeGoogleCode } from '../Controllers/oauth-handoff.controller.js';
import multer from "multer";
import passport from "../Config/passport.js";
import { auth } from "../Middlewares/auth.middleware.js";
import { googleTokenLogin } from "../Controllers/google-auth.controller.js";
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
const profileUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 2 * 1024 * 1024, files: 1 } });
const parseProfile = (req, res, next) => {
  profileUpload.single("profilePic")(req, res, (error) => {
    if (error) return res.status(400).json({ success: false, message: "Profile picture must be smaller than 2 MB." });
    next();
  });
};
const requireUserGoogleConfig = (req, res, next) => {
  if (!process.env.USER_GOOGLE_CLIENT_ID || !process.env.USER_GOOGLE_CLIENT_SECRET) {
    return res.status(503).json({ success: false, message: "User Google login is not configured. Set USER_GOOGLE_CLIENT_ID and USER_GOOGLE_CLIENT_SECRET." });
  }
  next();
};
router.post("/google", googleTokenLogin);
router.post('/google/exchange', exchangeGoogleCode);

router.get(
  "/google",
  requireUserGoogleConfig,
  (req, res, next) => {
    if (typeof req.query.challenge !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(req.query.challenge)) return res.status(400).json({ success: false, message: 'Start Google login from the application.' });
    return passport.authenticate('google-user', { scope: ['profile', 'email'], session: false, state: req.query.challenge })(req, res, next);
  },
);

router.get(
  "/google/callback",
  requireUserGoogleConfig,
  (req, res, next) => {
    passport.authenticate("google-user", (err, user) => {
      if (err) {
        return res.status(500).json({
          success: false,
          code: "OAUTH_ERROR",
          message: "Google authentication failed. Please try again.",
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
router.post("/mobile/complete-profile", auth, parseProfile, completeMobileProfile);
router.put("/mobile/complete-profile", auth, parseProfile, completeMobileProfile);
router.post("/mobile/create-registration-order", auth, createMobileRegistrationOrder);
router.post("/mobile/verify-registration-payment", auth, verifyMobileRegistrationPayment);

export default router;
