import jwt from "jsonwebtoken";
import { User } from "../Models/user.model.js";

const auth = async (req, res, next) => {
  try {
    const token =
      req.header("Authorization")?.replace("Bearer ", "") || req.cookies?.token;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Token is missing. Please login.",
      });
    }

    // ✅ Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 🔥 IMPORTANT: Fetch fresh user from DB
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User not found",
      });
    }

    // ✅ Always use latest role from DB
    req.user = {
      id: user._id,
      email: user.email,
      role: user.role,
    };

    next();
  } catch (error) {
    console.error("Auth Error:", error);
    return res.status(401).json({
      success: false,
      message: "Invalid or expired token",
    });
  }
};

const checkAccountType = (expectedRole) => (req, res, next) => {
  if (req.user.role !== expectedRole) {
    return res.status(403).json({
      success: false,
      message: `Access denied. Only ${expectedRole}s allowed.`,
    });
  }
  next();
};

const isAdmin = checkAccountType("ADMIN");

export { auth, isAdmin };
