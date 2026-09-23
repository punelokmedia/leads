import jwt from "jsonwebtoken";
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
const MOBILE_OTP_TTL_MS = 30 * 60 * 1000;
const MOBILE_OTP_RESEND_COOLDOWN_MS = 30 * 1000;
const REGISTRATION_FEE_AMOUNT_INR = 499;
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
    const { email, password } = req.body;

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

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
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

    const token = jwt.sign(
      {
        id: user._id,
        email: user.email,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: "7d" },
    );

    const redirectUrl = new URL("/", frontendBaseUrl);
    redirectUrl.searchParams.set("gauth", "1");
    redirectUrl.searchParams.set("token", token);
    redirectUrl.searchParams.set(
      "user",
      JSON.stringify({
        _id: user._id,
        firstname: user.firstname,
        lastname: user.lastname,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        profilePic: user.profilePic,
        city: user.city || "",
        businessName: user.businessName || "",
        workType: user.workType || "",
        registrationFeePaid: Boolean(user.registrationFeePaid),
      }),
    );

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

    const otp = Math.floor(1000 + Math.random() * 9000).toString();

    console.log("forgetPassword : ", {
      email: email,
      otp: otp,
    });

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
    const { email, newPassword, confirmPassword } = req.body;

    if (!email || !newPassword || !confirmPassword) {
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

    const user = await User.findById(userId).select("-password").lean();

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
    const { firstname, lastname, phoneNumber } = req.body;

    if (!firstname && !lastname && !phoneNumber) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "At least one field is required to update",
      });
    }

    if (phoneNumber && !/^[6-9]\d{9}$/.test(phoneNumber)) {
      return res.status(400).json({
        success: false,
        code: "INVALID_PHONE",
        message: "Please enter a valid 10-digit Indian phone number",
      });
    }

    const updateData = {};

    if (firstname) updateData.firstname = firstname.trim();
    if (lastname) updateData.lastname = lastname.trim();
    if (phoneNumber) updateData.phoneNumber = phoneNumber;

    const user = await User.findByIdAndUpdate(
      userId,
      { $set: updateData },
      { new: true, runValidators: true },
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

    return res.status(500).json({
      success: false,
      code: "UPDATE_FAILED",
      message: "Failed to update profile",
    });
  }
};

const requestMobileOtp = async (req, res) => {
  try {
    const normalizedPhone = normalizeIndianPhone(req.body?.phoneNumber);

    if (!normalizedPhone) {
      return res.status(400).json({
        success: false,
        code: "INVALID_PHONE",
        message: "Please enter a valid 10-digit Indian phone number.",
      });
    }

    const now = Date.now();

    let user = await User.findOne({ phoneNumber: normalizedPhone });
    let otpToUse = Math.floor(100000 + Math.random() * 900000).toString();
    let otpExpireDate = new Date(now + MOBILE_OTP_TTL_MS);

    if (!user) {
      user = await User.create({
        firstname: "New",
        lastname: "User",
        email: buildMobilePlaceholderEmail(normalizedPhone),
        phoneNumber: normalizedPhone,
        password: null,
        providers: ["LOCAL"],
        loginOtp: otpToUse,
        loginOtpExpire: otpExpireDate,
      });
    } else {
      const hasActiveOtp =
        user.loginOtp &&
        user.loginOtpExpire &&
        new Date(user.loginOtpExpire).getTime() > now;
      const lastOtpCreatedRecently =
        hasActiveOtp &&
        new Date(user.loginOtpExpire).getTime() - now >
          MOBILE_OTP_TTL_MS - MOBILE_OTP_RESEND_COOLDOWN_MS;

      if (hasActiveOtp && lastOtpCreatedRecently) {
        otpToUse = user.loginOtp;
        otpExpireDate = new Date(user.loginOtpExpire);
      } else {
        user.loginOtp = otpToUse;
        user.loginOtpExpire = otpExpireDate;
        await user.save();
      }
    }

    return res.status(200).json({
      success: true,
      code: "OTP_SENT",
      message: "OTP sent successfully.",
      data: {
        phoneNumber: normalizedPhone,
        expiresInSeconds: Math.max(
          1,
          Math.floor((new Date(otpExpireDate).getTime() - now) / 1000),
        ),
        ...(process.env.NODE_ENV !== "production" ? { otp: otpToUse } : {}),
      },
    });
  } catch (error) {
    console.error("Request Mobile OTP Error:", error);
    return res.status(500).json({
      success: false,
      code: "OTP_SEND_FAILED",
      message: "Unable to send OTP at the moment.",
    });
  }
};

const requestSessionMobileOtp = async (req, res) => {
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

    const now = Date.now();
    let otpToUse = Math.floor(100000 + Math.random() * 900000).toString();
    let otpExpireDate = new Date(now + MOBILE_OTP_TTL_MS);

    const hasActiveOtp =
      user.loginOtp &&
      user.loginOtpExpire &&
      new Date(user.loginOtpExpire).getTime() > now &&
      user.pendingPhoneNumber === normalizedPhone;
    const lastOtpCreatedRecently =
      hasActiveOtp &&
      new Date(user.loginOtpExpire).getTime() - now >
        MOBILE_OTP_TTL_MS - MOBILE_OTP_RESEND_COOLDOWN_MS;

    if (hasActiveOtp && lastOtpCreatedRecently) {
      otpToUse = user.loginOtp;
      otpExpireDate = new Date(user.loginOtpExpire);
    } else {
      user.loginOtp = otpToUse;
      user.loginOtpExpire = otpExpireDate;
      user.pendingPhoneNumber = normalizedPhone;
      await user.save();
    }

    return res.status(200).json({
      success: true,
      code: "OTP_SENT",
      message: "OTP sent successfully.",
      data: {
        phoneNumber: normalizedPhone,
        expiresInSeconds: Math.max(
          1,
          Math.floor((new Date(otpExpireDate).getTime() - now) / 1000),
        ),
        ...(process.env.NODE_ENV !== "production" ? { otp: otpToUse } : {}),
      },
    });
  } catch (error) {
    console.error("Request Session Mobile OTP Error:", error);
    return res.status(500).json({
      success: false,
      code: "OTP_SEND_FAILED",
      message: "Unable to send OTP at the moment.",
    });
  }
};

const verifyMobileOtp = async (req, res) => {
  try {
    const normalizedPhone = normalizeIndianPhone(req.body?.phoneNumber);
    const otp = String(req.body?.otp ?? "").trim();

    if (!normalizedPhone || !otp) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "Phone number and OTP are required.",
      });
    }

    const user = await User.findOne({ phoneNumber: normalizedPhone });
    const isOtpValid =
      user &&
      user.loginOtp === otp &&
      user.loginOtpExpire &&
      user.loginOtpExpire > new Date();

    if (!isOtpValid) {
      return res.status(400).json({
        success: false,
        code: "INVALID_OTP",
        message: "Invalid or expired OTP.",
      });
    }

    if (user.isBlocked) {
      return res.status(403).json({
        success: false,
        code: "ACCOUNT_BLOCKED",
        message: "Your account has been blocked. Please contact support.",
      });
    }

    const isNewUser = user.firstname === "New" && user.lastname === "User";
    const needsProfile =
      !user.businessName ||
      !user.workType ||
      !user.city ||
      !user.registrationFeePaid ||
      isNewUser;

    user.loginOtp = null;
    user.loginOtpExpire = null;
    await user.save();

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: "7d",
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
    console.error("Verify Mobile OTP Error:", error);
    return res.status(500).json({
      success: false,
      code: "OTP_VERIFY_FAILED",
      message: "Unable to verify OTP right now.",
    });
  }
};

const verifySessionMobileOtp = async (req, res) => {
  try {
    const userId = req.user.id;
    const normalizedPhone = normalizeIndianPhone(req.body?.phoneNumber);
    const otp = String(req.body?.otp ?? "").trim();

    if (!normalizedPhone || !otp) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "Phone number and OTP are required.",
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

    const isOtpValid =
      user.loginOtp === otp &&
      user.loginOtpExpire &&
      user.loginOtpExpire > new Date() &&
      user.pendingPhoneNumber === normalizedPhone;

    if (!isOtpValid) {
      return res.status(400).json({
        success: false,
        code: "INVALID_OTP",
        message: "Invalid or expired OTP.",
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

    user.phoneNumber = normalizedPhone;
    user.loginOtp = null;
    user.loginOtpExpire = null;
    user.pendingPhoneNumber = "";
    await user.save();

    return res.status(200).json({
      success: true,
      code: "PHONE_VERIFIED",
      message: "Phone verified successfully.",
      data: {
        phoneNumber: user.phoneNumber,
      },
    });
  } catch (error) {
    console.error("Verify Session Mobile OTP Error:", error);
    return res.status(500).json({
      success: false,
      code: "OTP_VERIFY_FAILED",
      message: "Unable to verify OTP right now.",
    });
  }
};

const completeMobileProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { fullName, email, city, businessName, workType } = req.body;

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
          role: "USER",
        },
      },
      { new: true },
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

    const {
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
      fullName,
      email,
      city,
      businessName,
      workType,
    } = req.body;

    if (
      !razorpayOrderId ||
      !razorpayPaymentId ||
      !razorpaySignature ||
      !fullName ||
      !email ||
      !city ||
      !businessName ||
      !workType
    ) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message:
          "Payment details and profile fields are required.",
      });
    }

    const existingUser = await User.findById(req.user.id).select(
      "registrationFeePaid registrationPayment",
    );
    if (!existingUser) {
      return res.status(404).json({
        success: false,
        code: "USER_NOT_FOUND",
        message: "User not found.",
      });
    }

    if (existingUser.registrationFeePaid) {
      return res.status(409).json({
        success: false,
        code: "REGISTRATION_FEE_ALREADY_PAID",
        message: "Registration fee already paid for this account.",
      });
    }

    const generatedSignature = crypto
      .createHmac("sha256", RAZORPAY_SECRET_KEY)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (generatedSignature !== razorpaySignature) {
      return res.status(400).json({
        success: false,
        code: "INVALID_PAYMENT_SIGNATURE",
        message: "Payment verification failed.",
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
      _id: { $ne: req.user.id },
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
      req.user.id,
      {
        $set: {
          firstname,
          lastname,
          email: normalizedEmail,
          city: String(city).trim(),
          businessName: String(businessName).trim(),
          workType: String(workType).trim(),
          role: "USER",
          registrationFeePaid: true,
          registrationFeePaidAt: new Date(),
          registrationPayment: {
            razorpayOrderId,
            razorpayPaymentId,
            razorpaySignature,
            amount: REGISTRATION_FEE_AMOUNT_INR,
            currency: "INR",
          },
        },
      },
      { new: true },
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
      code: "REGISTRATION_PAYMENT_SUCCESS",
      message: "Payment successful. Registration completed.",
      data: user,
    });
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
