import jwt from "jsonwebtoken";
import { User } from "../Models/user.model.js";
import { hashPassword, comparePassword } from "../Utils/hash.js";
import { forgetPasswordEmail } from "../Utils/email.resend.utils.js";

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

        return res.status(200).json({
          success: true,
          code: "ACCOUNT_LINKED",
          message:
            "Your account was created using Google. A password has been added successfully. You can now login using email and password.",
        });
      }

      return res.status(409).json({
        success: false,
        code: "USER_ALREADY_EXISTS",
        message:
          "An account with this email already exists. Please login instead.",
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

    return res.status(201).json({
      success: true,
      code: "REGISTER_SUCCESS",
      message: "Account created successfully.",
      data: {
        id: user._id,
        email: user.email,
      },
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

const googleCallback = async (req, res) => {
  try {
    const user = req.user;

    if (!user) {
      return res.status(400).json({
        success: false,
        code: "GOOGLE_AUTH_FAILED",
        message: "Google authentication failed. Please try again.",
      });
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

    user.password = undefined;

    return res.status(200).json({
      success: true,
      code: "GOOGLE_LOGIN_SUCCESS",
      message: "Logged in successfully using Google.",
      token,
      data: user,
    });
  } catch (error) {
    console.error("Google Callback Error:", error);

    return res.status(500).json({
      success: false,
      code: "TOKEN_GENERATION_FAILED",
      message: "Unable to generate authentication token.",
    });
  }
};

const changePassword = async (req, res) => {
  try {
    const userId = req.user.id;

    const { oldPassword, newPassword, confirmPassword } = req.body;

    if (!oldPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "New password and confirm password do not match",
      });
    }

    const user = await User.findById(userId);

    if (!user || user.provider !== "LOCAL") {
      return res.status(400).json({
        success: false,
        message: "Invalid user or not a local account",
      });
    }

    const isMatch = await comparePassword(oldPassword, user.password);

    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: "Old password is incorrect",
      });
    }

    const hashed = await hashPassword(newPassword);

    user.password = hashed;
    await user.save();

    return res.status(200).json({
      success: true,
      message: "Password changed successfully",
    });
  } catch (error) {
    console.error("Change Password Error:", error);
    return res.status(500).json({
      success: false,
      message: "Error while changing password",
    });
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

    // 🔒 Don't reveal user existence
    if (!user) {
      return res.status(200).json({
        success: true,
        message: "If account exists, OTP sent",
      });
    }

    // 🔢 Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    const expiry = new Date(Date.now() + 10 * 60 * 1000);

    user.resetOtp = otp;
    user.resetOtpExpire = expiry;

    await user.save();

    await forgetPasswordEmail(user.email, user.name, otp);

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

    if (!user || user.resetOtp !== otp || user.resetOtpExpire < new Date()) {
      return res.status(400).json({
        success: false,
        message: "Invalid or expired OTP",
      });
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
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Error resetting password",
    });
  }
};

export {
  registerUser,
  changePassword,
  forgetPassword,
  resetPassword,
  loginUser,
  googleCallback,
};
