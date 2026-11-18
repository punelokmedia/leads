import { OAuthHandoff } from '../Models/oauth-handoff.model.js';
import { MEMBERSHIP_PRICE_INR } from '../Config/membership.js';
import jwt from "jsonwebtoken";
import mongoose from "mongoose";
import {
  PHONE_OTP_PURPOSE,
  PHONE_OTP_TTL_MS,
  PHONE_OTP_RESEND_COOLDOWN_MS,
  SmsProviderError,
  phoneOtpProvider,
  startTwilioVerification,
  checkTwilioVerification,
  createLocalCode,
  hashLocalCode,
} from "../Services/sms-verification.js";
import crypto from "crypto";
import { User } from "../Models/user.model.js";
import { hashPassword, comparePassword } from "../Utils/hash.js";
import { razorpay } from "../Config/razorpay.config.js";
import {
  forgetPasswordEmail,
  sendWelcomeEmail,
} from "../Utils/email.resend.utils.js";

const normalizeIndianPhone = (phoneNumber = "") => {
  const digits = String(phoneNumber).replace(/\D/g, "");

  if (digits.length === 10) return digits;
  if (digits.length === 12 && digits.startsWith("91")) return digits.slice(2);
  return null;
};

const buildMobilePlaceholderEmail = (phoneNumber) =>
  `${phoneNumber}.${Date.now()}@mobile.nextleads.local`;
const REGISTRATION_FEE_AMOUNT_INR = MEMBERSHIP_PRICE_INR;
const RAZORPAY_PUBLIC_KEY =
  process.env.RAZORPAY_KEY_ID || process.env.RAZORPAY_KEY || "";
const RAZORPAY_SECRET_KEY =
  process.env.RAZORPAY_KEY_SECRET || process.env.RAZORPAY_SECRET || "";

const registerUser = async (req, res) => {
  try {
    const { firstname, lastname, email, password, phoneNumber } = req.body;

    if (!firstname || !lastname || !email || !phoneNumber || !password) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message:
          "Firstname, lastname, email, phoneNumber and password are required.",
      });
    }

    let user = await User.findOne({ email });

    if (user) {
      if (!user.providers) user.providers = [];

      if (!user.password) {
        user.password = await hashPassword(password);

        if (!user.providers.includes("LOCAL")) {
          user.providers.push("LOCAL");
        }

        await user.save();

        await sendWelcomeEmail(
          user.email,
          `${user.firstname} ${user.lastname}`,
        ).catch((err) =>
          console.error("❌ Welcome Email Failed:", err.message),
        );

        return res.status(200).json({
          success: true,
          code: "ACCOUNT_LINKED",
          message:
            "Your account was created using Google. Password added successfully.",
        });
      }

      return res.status(409).json({
        success: false,
        code: "USER_ALREADY_EXISTS",
        message: "Account already exists. Please login.",
      });
    }

    const hashed = await hashPassword(password);

    user = await User.create({
      firstname,
      lastname,
      email,
      password: hashed,
      phoneNumber,
      providers: ["LOCAL"],
      profilePic: `https://api.dicebear.com/5.x/initials/svg?seed=${firstname}%20${lastname}`,
    });

    await sendWelcomeEmail(
      user.email,
      `${user.firstname} ${user.lastname}`,
    ).catch((err) => console.error("❌ Welcome Email Failed:", err.message));

    user.password = undefined;

    return res.status(201).json({
      success: true,
      code: "REGISTER_SUCCESS",
      message: "Account created successfully.",
      data: user,
    });
  } catch (err) {
    console.error("Register Error:", err);

    return res.status(500).json({
      success: false,
      code: "REGISTER_FAILED",
      message: "Something went wrong while creating your account.",
    });
  }
};

const loginUser = async (req, res) => {
  try {
    if (req.is && !req.is('application/json') && !req.is('application/x-www-form-urlencoded')) return res.status(415).json({ success: false, message: 'Unsupported Content-Type.' });
    if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body)) return res.status(400).json({ success: false, message: 'Invalid login body.' });
    const { email, password } = req.body;
    if (typeof email !== 'string' || typeof password !== 'string') return res.status(400).json({ success: false, message: 'Email and password must be strings.' });

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "Email and password are required.",
      });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "No account found with this email.",
      });
    }

    if (!user.password) {
      return res.status(400).json({
        success: false,
        code: "USE_GOOGLE_LOGIN",
        message:
          "This account is registered with Google. Please login using Google.",
      });
    }

    if (user.isBlocked) {
      return res.status(403).json({
        success: false,
        code: "ACCOUNT_BLOCKED",
        message: "Your account has been blocked. Please contact support.",
      });
    }

    const isMatch = await comparePassword(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        code: "INVALID_PASSWORD",
        message: "Incorrect password. Please try again.",
      });
    }

    user.password = undefined;

    const token = jwt.sign({ id: user._id, sv: user.sessionVersion ?? 0 }, process.env.JWT_SECRET, {
      expiresIn: req.header?.("X-Web-Session") === "1" ? "5d" : "7d",
    });

    return res.status(200).json({
      success: true,
      code: "LOGIN_SUCCESS",
      message: "Login successful.",
      token,
      data: user,
    });
  } catch (error) {
    console.error("Login Error:", error);

    return res.status(500).json({
      success: false,
      code: "LOGIN_FAILED",
      message: "Something went wrong during login.",
    });
  }
};

const logOutUser = async (req, res) => {
  try {
    await User.updateOne({ _id: req.user.id }, { $inc: { sessionVersion: 1 } });
    res.set?.("Cache-Control", "no-store");
    return res.status(200).json({
      success: true,
      code: "LOGOUT_SUCCESS",
      message: "Logged out successfully",
    });
  } catch (error) {
    console.error("Logout Error:", error);

    return res.status(500).json({
      success: false,
      code: "LOGOUT_FAILED",
      message: "Something went wrong during logout",
    });
  }
};

const googleCallback = async (req, res) => {
  try {
    const user = req.user;
    const frontendBaseUrl = process.env.FRONTEND_URL || "http://localhost:5174";

    if (!user) {
      const redirectUrl = new URL("/", frontendBaseUrl);
      redirectUrl.searchParams.set("gauth", "1");
      redirectUrl.searchParams.set(
        "error",
        "Google authentication failed. Please try again.",
      );
      return res.redirect(302, redirectUrl.toString());
    }

    if (user.isBlocked) {
      const redirectUrl = new URL("/", frontendBaseUrl);
      redirectUrl.searchParams.set("gauth", "1");
      redirectUrl.searchParams.set(
        "error",
        "Your account has been blocked. Please contact support.",
      );
      return res.redirect(302, redirectUrl.toString());
    }

    const challenge = req.query?.state;
    if (typeof challenge !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(challenge)) throw new Error('Invalid OAuth state');
    const code = crypto.randomBytes(32).toString('hex');
    await OAuthHandoff.create({ codeHash: crypto.createHash('sha256').update(code).digest('hex'), challenge, user: user._id, sessionVersion: user.sessionVersion ?? 0, expiresAt: new Date(Date.now() + 60000) });
    const redirectUrl = new URL('/', frontendBaseUrl);
    redirectUrl.searchParams.set('gauth', '1');
    redirectUrl.hash = 'oauth_code=' + code;
    return res.redirect(302, redirectUrl.toString());
  } catch (error) {
    console.error("Google Callback Error:", error);

    const redirectUrl = new URL("/", process.env.FRONTEND_URL || "http://localhost:5174");
    redirectUrl.searchParams.set("gauth", "1");
    redirectUrl.searchParams.set("error", "Unable to complete Google login.");
    return res.redirect(302, redirectUrl.toString());
  }
};

const forgetPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(200).json({
        success: true,
        message: "If account exists, OTP sent",
      });
    }

    const otp = crypto.randomInt(1000, 10000).toString();

    const expiry = new Date(Date.now() + 10 * 60 * 1000);

    user.resetOtp = otp;
    user.resetOtpExpire = expiry;

    await user.save();

    try {
      await forgetPasswordEmail(
        user.email,
        `${user.firstname} ${user.lastname}`,
        otp,
      );
    } catch (e) {
      console.error("Email failed but OTP saved:", e.message);
    }

    return res.status(200).json({
      success: true,
      message: "OTP sent successfully",
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Error sending OTP",
    });
  }
};

const verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: "Email and OTP are required",
      });
    }

    const user = await User.findOne({ email });

    if (!user || user.resetOtp !== otp || user.resetOtpExpire < new Date()) {
      return res.status(400).json({
        success: false,
        message: "Invalid or expired OTP",
      });
    }

    return res.status(200).json({
      success: true,
      message: "OTP verified successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error verifying OTP",
    });
  }
};

const resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword, confirmPassword } = req.body;

    if (!email || !otp || !newPassword || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "Passwords do not match",
      });
    }

    const user = await User.findOne({ email });

    if (!user || !user.resetOtp || user.resetOtp !== String(otp) || !user.resetOtpExpire || user.resetOtpExpire <= new Date()) {
      return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
    }

    const hashed = await hashPassword(newPassword);

    user.password = hashed;
    user.resetOtp = null;
    user.resetOtpExpire = null;

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Password reset successful",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error resetting password",
    });
  }
};

const addAddress = async (req, res) => {
  try {
    const userId = req.user.id;

    const { label, street, landmark, city, state, country, zipcode } = req.body;

    if (!street || !city || !state || !zipcode) {
      return res.status(400).json({
        success: false,
        message: "street, city, state and zipcode are required",
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const newAddress = {
      label,
      street,
      landmark,
      city,
      state,
      country,
      zipcode,
    };

    user.address = newAddress;

    await user.save();

    return res.status(200).json({
      success: true,
      message: user.address
        ? "Address updated successfully"
        : "Address added successfully",
      data: user.address,
    });
  } catch (error) {
    console.error("Add Address Error:", error);

    return res.status(500).json({
      success: false,
      message: "Error saving address",
    });
  }
};

const getUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await User.findById(userId).select("-password -resetOtp -resetOtpExpire -loginOtp -loginOtpExpire -pendingPhoneNumber -phoneVerification -sessionVersion -registrationPayment.razorpaySignature").lean();

    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found",
      });
    }

    return res.status(200).json({
      success: true,
      code: "PROFILE_FETCHED",
      message: "User profile fetched successfully",
      data: {
        ...user,
        isProfileComplete: !!(user.firstname && user.email && user.phoneNumber),
      },
    });
  } catch (error) {
    console.error("Get Profile Error:", error);

    return res.status(500).json({
      success: false,
      code: "PROFILE_FETCH_FAILED",
      message: "Failed to fetch user profile",
    });
  }
};

const updateUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const fields = ["firstname", "lastname", "phoneNumber", "email", "businessName", "workType", "city", "state",
      "businessType", "gstNumber", "businessAddress", "serviceArea", "yearsInBusiness", "website"];
    const supplied = fields.filter((field) => Object.hasOwn(req.body, field));
    const hasCategories = Object.hasOwn(req.body, "categories");
    const hasRadius = Object.hasOwn(req.body, "serviceRadiusKm");
    const hasAreas = Object.hasOwn(req.body, "additionalAreas");
    if ((!supplied.length && !hasCategories && !hasRadius && !hasAreas) || supplied.some((field) => typeof req.body[field] !== "string")) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "Provide at least one valid profile field",
      });
    }

    const { phoneNumber, email } = req.body;
    if (phoneNumber !== undefined && !/^[6-9]\d{9}$/.test(phoneNumber.trim())) {
      return res.status(400).json({
        success: false,
        code: "INVALID_PHONE",
        message: "Please enter a valid 10-digit Indian phone number",
      });
    }

    const updateData = {};
    if (hasRadius) {
      if (![10, 25, 50].includes(req.body.serviceRadiusKm)) {
        return res.status(400).json({ success: false, message: "Select a valid service radius" });
      }
      updateData.serviceRadiusKm = req.body.serviceRadiusKm;
    }
    if (hasAreas) {
      if (!Array.isArray(req.body.additionalAreas) || req.body.additionalAreas.length > 50 ||
          req.body.additionalAreas.some((area) => typeof area !== 'string' || !area.trim() || area.trim().length > 100)) {
        return res.status(400).json({ success: false, message: "Provide valid additional areas" });
      }
      updateData.additionalAreas = [...new Set(req.body.additionalAreas.map((area) => area.trim()))];
    }
    if (hasCategories) {
      if (!Array.isArray(req.body.categories) || req.body.categories.length > 100 ||
          req.body.categories.some((id) => typeof id !== 'string' || !/^[a-f0-9]{24}$/i.test(id))) {
        return res.status(400).json({ success: false, message: "Please select valid categories" });
      }
      updateData.categories = [...new Set(req.body.categories.map((id) => id.toLowerCase()))];
    }
    for (const field of supplied) updateData[field] = req.body[field].trim();
    if (updateData.gstNumber) {
      updateData.gstNumber = updateData.gstNumber.toUpperCase();
      if (!/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/.test(updateData.gstNumber)) {
        return res.status(400).json({ success: false, message: "Please enter a valid GSTIN" });
      }
    }
    if (updateData.website) {
      let website;
      try { website = new URL(updateData.website); } catch { /* validated below */ }
      if (!website || !["http:", "https:"].includes(website.protocol) || !website.hostname.includes(".")) {
        return res.status(400).json({ success: false, message: "Please enter a valid http or https website address" });
      }
    }
    if (email !== undefined) {
      updateData.email = email.trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(updateData.email)) {
        return res.status(400).json({ success: false, message: "Please enter a valid email address" });
      }
    }
    if (["firstname", "lastname"].some((field) => supplied.includes(field) && !updateData[field])) {
      return res.status(400).json({ success: false, message: "First and last name are required" });
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { $set: updateData },
      { returnDocument: "after", runValidators: true },
    ).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found",
      });
    }

    return res.status(200).json({
      success: true,
      code: "PROFILE_UPDATED",
      message: "Profile updated successfully",
      data: user,
    });
  } catch (error) {
    console.error("Update Profile Error:", error);
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: "Email is already in use" });
    }
    return res.status(500).json({
      success: false,
      code: "UPDATE_FAILED",
      message: "Failed to update profile",
    });
  }
};

const smsUnavailable = (res, message) =>
  res.status(503).json({ success: false, code: "SMS_NOT_CONFIGURED", message });

const invalidOtp = (res) =>
  res.status(400).json({ success: false, code: "INVALID_OTP", message: "Invalid or expired OTP." });

const sendOtpFailure = (res, error, label) => {
  if (error instanceof SmsProviderError) {
    if (error.status === 429) {
      return res.status(429).json({ success: false, code: "OTP_RATE_LIMITED", message: "Too many OTP requests for this number. Please try again later." });
    }
    return res.status(502).json({ success: false, code: "OTP_SEND_FAILED", message: "Unable to send OTP at the moment." });
  }
  console.error(`${label}:`, error);
  return res.status(500).json({ success: false, code: "OTP_SEND_FAILED", message: "Unable to send OTP at the moment." });
};

const verifyOtpFailure = (res, error, label) => {
  if (!(error instanceof SmsProviderError)) console.error(`${label}:`, error);
  return res.status(error instanceof SmsProviderError ? 502 : 500).json({ success: false, code: "OTP_VERIFY_FAILED", message: "Unable to verify OTP right now." });
};

const isBindingFor = (binding, { purpose, phoneNumber, userId }, now = Date.now()) =>
  !!binding &&
  binding.purpose === purpose &&
  binding.phoneNumber === phoneNumber &&
  String(binding.userId) === String(userId) &&
  new Date(binding.expiresAt).getTime() > now;

// A Twilio code sent moments ago is still pending; don't pay for (or rate-limit on) a duplicate send.
const canReuseBinding = (binding, target, now = Date.now()) =>
  isBindingFor(binding, target, now) &&
  binding.provider === "twilio" &&
  phoneOtpProvider(target.purpose) === "twilio" &&
  now - new Date(binding.sentAt).getTime() < PHONE_OTP_RESEND_COOLDOWN_MS;

// Sends the code (Twilio) or creates it (dev-only local provider). Resolves only after the provider accepts.
const issuePhoneOtp = async (target) => {
  const sentAt = new Date();
  const binding = { ...target, sentAt, expiresAt: new Date(sentAt.getTime() + PHONE_OTP_TTL_MS) };
  if (phoneOtpProvider(target.purpose) === "twilio") {
    const { verificationSid } = await startTwilioVerification(target);
    return { binding: { ...binding, provider: "twilio", verificationSid } };
  }
  const devCode = createLocalCode();
  return { binding: { ...binding, provider: "local", codeHash: hashLocalCode(devCode, target) }, devCode };
};

const isApprovedCode = async (binding, otp) => {
  if (binding.provider === "twilio") {
    return checkTwilioVerification({ purpose: binding.purpose, phoneNumber: binding.phoneNumber, code: otp, verificationSid: binding.verificationSid });
  }
  if (process.env.NODE_ENV === "production" || !binding.codeHash) return false;
  const expected = Buffer.from(binding.codeHash, "hex");
  const actual = Buffer.from(hashLocalCode(otp, binding), "hex");
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
};

// Matches exactly the binding that was checked, so a concurrent or newer request cannot be consumed twice.
const bindingFilter = (binding) => ({
  "phoneVerification.purpose": binding.purpose,
  "phoneVerification.phoneNumber": binding.phoneNumber,
  "phoneVerification.userId": binding.userId,
  "phoneVerification.sentAt": binding.sentAt,
  "phoneVerification.expiresAt": { $gt: new Date() },
  ...(binding.provider === "twilio"
    ? { "phoneVerification.verificationSid": binding.verificationSid }
    : { "phoneVerification.codeHash": binding.codeHash }),
});

const LEGACY_OTP_FIELDS = { loginOtp: 1, loginOtpExpire: 1, pendingPhoneNumber: 1 };

const otpSentResponse = (res, binding, devCode) =>
  res.status(200).json({
    success: true,
    code: "OTP_SENT",
    message: "OTP sent successfully.",
    data: {
      phoneNumber: binding.phoneNumber,
      expiresInSeconds: Math.max(1, Math.floor((new Date(binding.expiresAt).getTime() - Date.now()) / 1000)),
      ...(devCode && process.env.NODE_ENV !== "production" ? { otp: devCode } : {}),
    },
  });

const normalizeOtpInput = (value) => {
  const otp = String(value ?? "").trim();
  return /^\d{4,10}$/.test(otp) ? otp : null;
};

const requestMobileOtp = async (req, res) => {
  if (!phoneOtpProvider(PHONE_OTP_PURPOSE.LOGIN)) {
    return smsUnavailable(res, "Phone verification is unavailable. Please use email or Google login.");
  }
  try {
    const normalizedPhone = normalizeIndianPhone(req.body?.phoneNumber);

    if (!normalizedPhone) {
      return res.status(400).json({
        success: false,
        code: "INVALID_PHONE",
        message: "Please enter a valid 10-digit Indian phone number.",
      });
    }

    let user = await User.findOne({ phoneNumber: normalizedPhone });
    const userId = user?._id ?? new mongoose.Types.ObjectId();
    const target = { purpose: PHONE_OTP_PURPOSE.LOGIN, phoneNumber: normalizedPhone, userId };

    if (user && canReuseBinding(user.phoneVerification, target)) {
      return otpSentResponse(res, user.phoneVerification);
    }

    const { binding, devCode } = await issuePhoneOtp(target);

    if (user) {
      await User.updateOne({ _id: user._id }, { $set: { phoneVerification: binding }, $unset: LEGACY_OTP_FIELDS });
    } else {
      try {
        await User.create({
          _id: userId,
          firstname: "New",
          lastname: "User",
          email: buildMobilePlaceholderEmail(normalizedPhone),
          phoneNumber: normalizedPhone,
          password: null,
          providers: ["LOCAL"],
          phoneVerification: binding,
        });
      } catch (error) {
        if (error?.code !== 11000) throw error;
        // Another request created this phone's account first; bind the code to that account instead.
        user = await User.findOne({ phoneNumber: normalizedPhone });
        if (!user) throw error;
        binding.userId = user._id;
        await User.updateOne({ _id: user._id }, { $set: { phoneVerification: binding } });
      }
    }

    return otpSentResponse(res, binding, devCode);
  } catch (error) {
    return sendOtpFailure(res, error, "Request Mobile OTP Error");
  }
};

const requestSessionMobileOtp = async (req, res) => {
  if (!phoneOtpProvider(PHONE_OTP_PURPOSE.PHONE_CHANGE)) {
    return smsUnavailable(res, "Phone verification is unavailable. Please contact support.");
  }
  try {
    const userId = req.user.id;
    const normalizedPhone = normalizeIndianPhone(req.body?.phoneNumber);

    if (!normalizedPhone) {
      return res.status(400).json({
        success: false,
        code: "INVALID_PHONE",
        message: "Please enter a valid 10-digit Indian phone number.",
      });
    }

    const existingPhoneUser = await User.findOne({
      phoneNumber: normalizedPhone,
      _id: { $ne: userId },
    }).select("_id");
    if (existingPhoneUser) {
      return res.status(409).json({
        success: false,
        code: "PHONE_ALREADY_IN_USE",
        message: "This phone number is already associated with another account.",
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found.",
      });
    }

    const target = { purpose: PHONE_OTP_PURPOSE.PHONE_CHANGE, phoneNumber: normalizedPhone, userId: user._id };
    if (canReuseBinding(user.phoneVerification, target)) {
      return otpSentResponse(res, user.phoneVerification);
    }

    const { binding, devCode } = await issuePhoneOtp(target);
    await User.updateOne({ _id: user._id }, { $set: { phoneVerification: binding }, $unset: LEGACY_OTP_FIELDS });

    return otpSentResponse(res, binding, devCode);
  } catch (error) {
    return sendOtpFailure(res, error, "Request Session Mobile OTP Error");
  }
};

const verifyMobileOtp = async (req, res) => {
  try {
    const normalizedPhone = normalizeIndianPhone(req.body?.phoneNumber);
    const rawOtp = String(req.body?.otp ?? "").trim();

    if (!normalizedPhone || !rawOtp) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "Phone number and OTP are required.",
      });
    }
    const otp = normalizeOtpInput(rawOtp);
    if (!otp) return invalidOtp(res);

    const candidate = await User.findOne({ phoneNumber: normalizedPhone, isBlocked: { $ne: true } });
    const binding = candidate?.phoneVerification;
    if (!candidate || !isBindingFor(binding, { purpose: PHONE_OTP_PURPOSE.LOGIN, phoneNumber: normalizedPhone, userId: candidate._id })) {
      return invalidOtp(res);
    }
    if (!(await isApprovedCode(binding, otp))) return invalidOtp(res);

    const user = await User.findOneAndUpdate(
      { _id: candidate._id, phoneNumber: normalizedPhone, isBlocked: { $ne: true }, ...bindingFilter(binding) },
      { $unset: { phoneVerification: 1, ...LEGACY_OTP_FIELDS } },
      { returnDocument: "after" },
    );
    if (!user) return invalidOtp(res);

    const isNewUser = user.firstname === "New" && user.lastname === "User";
    const needsProfile =
      !user.businessName ||
      !user.workType ||
      !user.city ||
      isNewUser;

    const token = jwt.sign({ id: user._id, sv: user.sessionVersion ?? 0 }, process.env.JWT_SECRET, {
      expiresIn: req.header?.("X-Web-Session") === "1" ? "5d" : "7d",
    });

    return res.status(200).json({
      success: true,
      code: "LOGIN_SUCCESS",
      message: "Mobile login successful.",
      token,
      data: {
        _id: user._id,
        firstname: user.firstname,
        lastname: user.lastname,
        phoneNumber: user.phoneNumber,
        businessName: user.businessName || "",
        workType: user.workType || "",
        email: user.email,
      },
      meta: {
        isNewUser,
        needsProfile,
      },
    });
  } catch (error) {
    return verifyOtpFailure(res, error, "Verify Mobile OTP Error");
  }
};

const verifySessionMobileOtp = async (req, res) => {
  try {
    const userId = req.user.id;
    const normalizedPhone = normalizeIndianPhone(req.body?.phoneNumber);
    const rawOtp = String(req.body?.otp ?? "").trim();

    if (!normalizedPhone || !rawOtp) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "Phone number and OTP are required.",
      });
    }
    const otp = normalizeOtpInput(rawOtp);
    if (!otp) return invalidOtp(res);

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found.",
      });
    }

    const binding = user.phoneVerification;
    if (user.isBlocked || !isBindingFor(binding, { purpose: PHONE_OTP_PURPOSE.PHONE_CHANGE, phoneNumber: normalizedPhone, userId })) {
      return invalidOtp(res);
    }
    if (!(await isApprovedCode(binding, otp))) return invalidOtp(res);

    const phoneInUse = () => res.status(409).json({
      success: false,
      code: "PHONE_ALREADY_IN_USE",
      message: "This phone number is already associated with another account.",
    });

    const existingPhoneUser = await User.findOne({
      phoneNumber: normalizedPhone,
      _id: { $ne: userId },
    }).select("_id");
    if (existingPhoneUser) return phoneInUse();

    let consumed;
    try {
      consumed = await User.findOneAndUpdate(
        { _id: userId, isBlocked: { $ne: true }, ...bindingFilter(binding) },
        { $set: { phoneNumber: normalizedPhone }, $unset: { phoneVerification: 1, ...LEGACY_OTP_FIELDS } },
        { returnDocument: "after", runValidators: true },
      );
    } catch (error) {
      if (error?.code === 11000) return phoneInUse();
      throw error;
    }
    if (!consumed) return invalidOtp(res);

    return res.status(200).json({
      success: true,
      code: "PHONE_VERIFIED",
      message: "Phone verified successfully.",
      data: {
        phoneNumber: consumed.phoneNumber,
      },
    });
  } catch (error) {
    return verifyOtpFailure(res, error, "Verify Session Mobile OTP Error");
  }
};


const completeMobileProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { fullName, email, city, businessName, workType, address } = req.body;
    const rawCategories = req.body.categories ?? req.body['categories[]'] ?? [];
    const categories = Array.isArray(rawCategories) ? rawCategories : [rawCategories];
    if (categories.some((id) => !/^[a-f0-9]{24}$/i.test(String(id)))) {
      return res.status(400).json({ success: false, message: "Please select valid categories." });
    }
    if (req.file && !["image/jpeg", "image/png", "image/webp"].includes(req.file.mimetype)) {
      return res.status(400).json({ success: false, message: "Please upload a JPEG, PNG or WebP picture." });
    }

    if (!fullName || !email || !businessName || !workType || !city) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "fullName, email, city, businessName and workType are required.",
      });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        code: "INVALID_EMAIL",
        message: "Please enter a valid email address.",
      });
    }

    const existingEmailUser = await User.findOne({
      email: normalizedEmail,
      _id: { $ne: userId },
    }).select("_id");
    if (existingEmailUser) {
      return res.status(409).json({
        success: false,
        code: "EMAIL_ALREADY_IN_USE",
        message: "This email is already associated with another account.",
      });
    }

    const nameParts = fullName
      .trim()
      .split(/\s+/)
      .filter(Boolean);
    const firstname = nameParts[0] || "User";
    const lastname = nameParts.slice(1).join(" ") || "User";

    const user = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          firstname,
          lastname,
          email: normalizedEmail,
          city: String(city).trim(),
          businessName: businessName.trim(),
          workType: workType.trim(),
          profileAddress: String(address || "").trim(),
          categories: [...new Set(categories)],
          ...(req.file ? { profilePic: 'data:' + req.file.mimetype + ';base64,' + req.file.buffer.toString('base64') } : {}),
          role: "USER",
        },
      },
      { returnDocument: "after", runValidators: true },
    ).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found.",
      });
    }

    return res.status(200).json({
      success: true,
      code: "PROFILE_COMPLETED",
      message: "Profile completed successfully.",
      data: user,
    });
  } catch (error) {
    console.error("Complete Mobile Profile Error:", error);
    return res.status(500).json({
      success: false,
      code: "PROFILE_COMPLETE_FAILED",
      message: "Unable to complete profile right now.",
    });
  }
};

const createMobileRegistrationOrder = async (req, res) => {
  try {
    if (!RAZORPAY_PUBLIC_KEY || !RAZORPAY_SECRET_KEY) {
      return res.status(500).json({
        success: false,
        code: "RAZORPAY_NOT_CONFIGURED",
        message: "Razorpay is not configured on server.",
      });
    }

    const user = await User.findById(req.user.id).select(
      "registrationFeePaid registrationPayment role",
    );
    if (!user) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found.",
      });
    }

    if (user.registrationFeePaid) {
      return res.status(409).json({
        success: false,
        code: "REGISTRATION_FEE_ALREADY_PAID",
        message: "Registration fee already paid for this account.",
      });
    }

    const amountInPaise = REGISTRATION_FEE_AMOUNT_INR * 100;
    const shortReceipt = `su_${String(req.user.id).slice(-8)}_${Date.now()
      .toString()
      .slice(-10)}`;
    const order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: "INR",
      receipt: shortReceipt,
      notes: {
        purpose: "signup_registration_fee",
        userId: String(req.user.id),
      },
    });

    return res.status(200).json({
      success: true,
      code: "ORDER_CREATED",
      message: "Registration order created successfully.",
      data: {
        orderId: order.id,
        razorpayOrderId: order.id,
        amount: order.amount,
        currency: order.currency,
        keyId: RAZORPAY_PUBLIC_KEY,
      },
    });
  } catch (error) {
    console.error("Create Registration Order Error:", error);
    return res.status(500).json({
      success: false,
      code: "ORDER_CREATE_FAILED",
      message:
        error?.error?.description ||
        error?.message ||
        "Failed to create registration order.",
    });
  }
};

const verifyMobileRegistrationPayment = async (req, res) => {
  try {
    if (!RAZORPAY_SECRET_KEY) {
      return res.status(500).json({
        success: false,
        code: "RAZORPAY_NOT_CONFIGURED",
        message: "Razorpay is not configured on server.",
      });
    }

    // Membership is independent of profile setup and can only be activated by a captured payment.
    {
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;
      if (typeof razorpayOrderId !== 'string' || typeof razorpayPaymentId !== 'string' || typeof razorpaySignature !== 'string') {
        return res.status(400).json({ success: false, message: 'Payment details are required.' });
      }
      const expected = crypto.createHmac('sha256', RAZORPAY_SECRET_KEY).update(razorpayOrderId + '|' + razorpayPaymentId).digest('hex');
      if (expected !== razorpaySignature) return res.status(400).json({ success: false, message: 'Invalid payment signature.' });
      const order = await razorpay.orders.fetch(razorpayOrderId);
      const payment = await razorpay.payments.fetch(razorpayPaymentId);
      if (String(order.notes?.userId) !== String(req.user.id) || order.notes?.purpose !== 'signup_registration_fee' ||
          order.amount !== REGISTRATION_FEE_AMOUNT_INR * 100 || order.currency !== 'INR' ||
          payment.order_id !== razorpayOrderId || payment.status !== 'captured' ||
          payment.amount !== REGISTRATION_FEE_AMOUNT_INR * 100 || payment.currency !== 'INR' ||
          (payment.amount_refunded || 0) > 0) {
        return res.status(400).json({ success: false, message: 'Membership payment is not captured or does not match this account.' });
      }
      const user = await User.findOneAndUpdate({ _id: req.user.id, registrationFeePaid: { $ne: true } }, {
        $set: { registrationFeePaid: true, registrationFeePaidAt: new Date(), registrationPayment: {
          razorpayOrderId, razorpayPaymentId, razorpaySignature, amount: REGISTRATION_FEE_AMOUNT_INR, currency: 'INR',
        } },
      }, { returnDocument: "after" }).select('-password');
      const member = user || await User.findById(req.user.id).select('-password');
      if (!member) return res.status(404).json({ success: false, message: 'User not found.' });
      return res.json({ success: true, message: 'Lifetime membership activated.', data: member });
    }
  } catch (error) {
    console.error("Verify Registration Payment Error:", error);
    return res.status(500).json({
      success: false,
      code: "PAYMENT_VERIFY_FAILED",
      message: "Unable to verify payment right now.",
    });
  }
};

export {
  registerUser,
  forgetPassword,
  verifyOtp,
  resetPassword,
  loginUser,
  googleCallback,
  addAddress,
  logOutUser,
  getUserProfile,
  updateUserProfile,
  requestMobileOtp,
  requestSessionMobileOtp,
  verifyMobileOtp,
  verifySessionMobileOtp,
  completeMobileProfile,
  createMobileRegistrationOrder,
  verifyMobileRegistrationPayment,
};
