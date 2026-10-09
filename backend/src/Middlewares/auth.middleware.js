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

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User not found",
      });
    }
    if (user.isBlocked) {
      return res.status(403).json({
        success: false,
        message: "Your account has been blocked.",
      });
    }
    req.user = {
      id: user._id,
      email: user.email,
      role: user.role,
    };

    next();
  } catch (error) {
    const expectedTokenError = ['JsonWebTokenError', 'TokenExpiredError', 'NotBeforeError'].includes(error.name);
    if (!expectedTokenError) console.error('Authentication failed:', error.message);
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

// Public browsing is allowed; supplied credentials must still be valid.
const optionalAuth = (req, res, next) => {
  if (req.header("Authorization") || req.cookies?.token) return auth(req, res, next);
  return next();
};
export { auth, isAdmin, optionalAuth };
