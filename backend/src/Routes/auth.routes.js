import express from "express";
import passport from "../Config/passport.js";
import { addAddress } from "../Controllers/user.controller.js";
import { auth } from "../Middlewares/auth.middleware.js";
import {
  googleCallback,
  registerUser,
  loginUser,
  changePassword,
  forgetPassword,
  resetPassword,
} from "../Controllers/auth.controller.js";

const router = express.Router();

router.get("/google",
  passport.authenticate("google", {
    scope: ["profile", "email"],
    session: false,
  }),
);

router.get( "/google/callback",
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
router.post("/change-password", auth, changePassword);
router.post("/add-address", auth, addAddress);

router.post("/forgot-password", forgetPassword);
router.post("/reset-password", resetPassword);

export default router;
