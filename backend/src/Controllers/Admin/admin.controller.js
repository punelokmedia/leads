import jwt from "jsonwebtoken";
import { User } from "../../Models/user.model.js";
import { sendAdminOtpEmail } from "../../Utils/email.resend.utils.js";

const sendOtpForAdminLogin = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const admin = await User.findOne({ email, role: "ADMIN" });

    if (!admin) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Not an admin.",
      });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpire = new Date(Date.now() + 10 * 60 * 1000);

    try {
      const emailResponse = await sendAdminOtpEmail(email, otp);

      admin.resetOtp = otp;
      admin.resetOtpExpire = otpExpire;
      await admin.save();

      return res.status(200).json({
        success: true,
        message: "OTP sent to admin email",
      });
    } catch (mailError) {
      console.error("❌ Email failed:", mailError.message);

      return res.status(500).json({
        success: false,
        message: mailError.message,
      });
    }
  } catch (error) {
    console.error("❌ Server error:", error);

    return res.status(500).json({
      success: false,
      message: "Something went wrong",
    });
  }
};

const verifyAdminOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const admin = await User.findOne({ email, role: "ADMIN" });

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    if (admin.resetOtp !== otp) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP",
      });
    }

    if (admin.resetOtpExpire < new Date()) {
      return res.status(400).json({
        success: false,
        message: "OTP expired",
      });
    }

    admin.resetOtp = null;
    admin.resetOtpExpire = null;
    await admin.save();

    const token = jwt.sign(
      { id: admin._id, role: admin.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" },
    );

    return res.status(200).json({
      success: true,
      message: "Admin login successful",
      token,
      data: {
        id: admin._id,
        fullname: admin.firstname + " " + admin.lastname,
        email: admin.email,
        role: admin.role,
      },
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: "OTP verification failed",
    });
  }
};

const changeUserRoleToAdmin = async (req, res) => {
  try {
    const { userId } = req.body;

  console.log("req.user.role ",req.user.role );
  
    if (req.user.role !== "ADMIN") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Only admin can change roles.",
      });
    }

    // 🔍 2. Validate input
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User ID is required",
      });
    }

    // 🔎 3. Find user
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // ⚠️ 4. Prevent changing already ADMIN
    if (user.role === "ADMIN") {
      return res.status(400).json({
        success: false,
        message: "User is already an admin",
      });
    }

    // 🔄 5. Update role
    user.role = "ADMIN";
    await user.save();

    return res.status(200).json({
      success: true,
      message: "User promoted to admin successfully",
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Change Role Error:", error);
    return res.status(500).json({
      success: false,
      message: "Something went wrong",
    });
  }
};

export { sendOtpForAdminLogin, verifyAdminOtp, changeUserRoleToAdmin };
