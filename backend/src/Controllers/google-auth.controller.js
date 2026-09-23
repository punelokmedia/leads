import { OAuth2Client } from "google-auth-library";
import jwt from "jsonwebtoken";
import { resolveGoogleUser, publicGoogleUser } from "../Utils/google-user.js";

const client = new OAuth2Client();

export function createGoogleTokenLogin({ verify = (options) => client.verifyIdToken(options), resolveUser = resolveGoogleUser } = {}) {
  return async (req, res) => {
    const idToken = req.body?.idToken;
    if (typeof idToken !== "string" || !idToken.trim()) {
      return res.status(400).json({ success: false, message: "Google ID token is required." });
    }
    if (!process.env.USER_GOOGLE_CLIENT_ID || !process.env.JWT_SECRET) {
      return res.status(503).json({ success: false, message: "Google login is not configured." });
    }
    let payload;
    try {
      const ticket = await verify({ idToken, audience: process.env.USER_GOOGLE_CLIENT_ID });
      payload = ticket.getPayload();
      if (!payload?.sub || !payload.email || payload.email_verified !== true) throw new Error("Invalid identity");
    } catch {
      return res.status(401).json({ success: false, message: "Google login expired or is invalid. Please sign in again." });
    }
    try {
      const user = await resolveUser(payload);
      if (user.isBlocked) return res.status(403).json({ success: false, message: "Your account has been blocked." });
      const token = jwt.sign({ id: user._id, email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: "7d" });
      return res.json({ success: true, token, user: publicGoogleUser(user) });
    } catch (error) {
      return res.status(error.status || 500).json({ success: false, message: error.status ? error.message : "Unable to complete Google login." });
    }
  };
}

export const googleTokenLogin = createGoogleTokenLogin();
