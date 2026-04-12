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

router.get(
  "/google",
  passport.authenticate("google", {
    scope: ["profile", "email"],
    session: false,
  }),
);

router.get(
  "/google/callback",
  passport.authenticate("google", {
    session: false,
    failureRedirect: "/login",
  }),
  googleCallback,
);

router.post("/register", registerUser);
router.post("/login", loginUser);
router.post("/change-password", auth, changePassword);
router.post("/add-address", auth, addAddress);

router.post("/forgot-password", forgetPassword);
router.post("/reset-password", resetPassword);

export default router;
