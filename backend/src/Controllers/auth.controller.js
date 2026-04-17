import jwt from "jsonwebtoken";
import { User } from "../Models/user.model.js";
import { hashPassword, comparePassword } from "../Utils/hash.js";
import {
  forgetPasswordEmail,
  sendWelcomeEmail,
} from "../Utils/email.resend.utils.js";

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

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (!user.password) {
      return res.status(400).json({
        success: false,
        message: "This account uses Google login. Password change not allowed.",
      });
    }

    const isMatch = await comparePassword(oldPassword, user.password);

    console.log(oldPassword, user.password);

    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: "Old password is incorrect",
      });
    }

    const isSame = await comparePassword(newPassword, user.password);

    if (isSame) {
      return res.status(400).json({
        success: false,
        message: "New password cannot be same as old password",
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

export {
  registerUser,
  changePassword,
  forgetPassword,
  verifyOtp,
  resetPassword,
  loginUser,
  googleCallback,
  addAddress,
  logOutUser,
  getUserProfile,
  updateUserProfile,
};
