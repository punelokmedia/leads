import jwt from "jsonwebtoken";
import { User } from "../Models/user.model.js";

const auth = async (req, res, next) => {
  try {
    const token =
      req.header("Authorization")?.replace("Bearer ", "") || req.cookies?.token;

    if (!token) {
      return res.status(401).json({
        success: false,
        code: "SESSION_REQUIRED",
        message: "Token is missing. Please login.",
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        code: "SESSION_INVALID",
        message: "User not found",
      });
    }
    if ((decoded.sv ?? 0) !== (user.sessionVersion ?? 0)) return res.status(401).json({ success: false, code: 'SESSION_REVOKED', message: 'Session revoked. Please login.' });
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
      mfa: decoded.mfa === true,
    };

    // Web clients opt in; mobile and admin token lifetimes stay compatible.
    // Renew at most once a minute to avoid request/render renewal loops.
    if (req.header('X-Web-Session') === '1' && user.role !== 'ADMIN' &&
        (decoded.exp - decoded.iat !== 5 * 86400 || Date.now() / 1000 - decoded.iat >= 60)) {
      res.set('X-Session-Token', jwt.sign({ id: user._id, sv: user.sessionVersion ?? 0 }, process.env.JWT_SECRET, { expiresIn: '5d' }));
      res.set('Cache-Control', 'no-store');
    }

    next();
  } catch (error) {
    const expectedTokenError = ['JsonWebTokenError', 'TokenExpiredError', 'NotBeforeError'].includes(error.name);
    if (!expectedTokenError) console.error('Authentication failed:', error.message);
    if (!expectedTokenError) return res.status(503).json({ success: false, code: 'AUTH_UNAVAILABLE', message: 'Unable to check your session. Please try again.' });
    return res.status(401).json({
      success: false,
      code: 'SESSION_EXPIRED',
      message: "Invalid or expired token",
    });
  }
};

const checkAccountType = (expectedRole) => (req, res, next) => {
  if (expectedRole === 'ADMIN' && process.env.NODE_ENV === 'production' && !req.user.mfa) {
    return res.status(403).json({ success: false, message: 'Admin password and OTP verification required.' });
  }
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
export { auth, isAdmin, optionalAuth, checkAccountType };
