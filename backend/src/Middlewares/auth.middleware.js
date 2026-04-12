import jwt from "jsonwebtoken";

const auth = async (req, res, next) => {
  try {
    const token =
      req.header("Authorization")?.replace("Bearer ", "") ||
      req.body?.token ||
      req.header("token") ||
      req.cookies?.token;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Token is missing. Please login.",
      });
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      req.user = {
        id: decoded.id || decoded.user,
        email: decoded.email,
        role: decoded.role,
      };

      next();
    } catch (error) {
      console.error("Token verification failed:", error);
      return res.status(401).json({
        success: false,
        message: "Invalid or expired token. Please login again.",
      });
    }
  } catch (error) {
    console.error("Error while authenticate user middleware:", error);
    return res.status(500).json({
      success: false,
      message: `Error while authenticate user middleware: ${error.message}`,
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
