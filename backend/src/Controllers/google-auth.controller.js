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
    const audiences = [...new Set([
      process.env.USER_GOOGLE_CLIENT_ID,
      process.env.MOBILE_USER_GOOGLE_CLIENT_ID,
    ].map((value) => value?.trim()).filter(Boolean))];
    if (!audiences.length || !process.env.JWT_SECRET) {
      console.error('Google token login configuration missing', { hasUserAudience: audiences.length > 0, hasJwtSecret: Boolean(process.env.JWT_SECRET) });
      return res.status(503).json({ success: false, code: "GOOGLE_LOGIN_NOT_CONFIGURED", message: "Google login is not configured." });
    }
    let payload;
    try {
      const ticket = await verify({ idToken, audience: audiences });
      payload = ticket.getPayload();
      if (!payload?.sub || !payload.email || payload.email_verified !== true) throw new Error("Invalid identity");
    } catch (error) {
      // Do not log the ID token, payload, email, or provider error message:
      // provider errors may embed token contents. Classify known failure types.
      const reason = /audience|recipient/i.test(error.message || '') ? 'AUDIENCE_MISMATCH'
        : /expired|too late/i.test(error.message || '') ? 'TOKEN_EXPIRED'
        : 'TOKEN_REJECTED';
      console.warn('Google token verification failed', { reason });
      return res.status(401).json({ success: false, code: "GOOGLE_TOKEN_REJECTED", message: "Google login expired or is invalid. Please sign in again." });
    }
    try {
      const user = await resolveUser(payload);
      if (user.isBlocked) return res.status(403).json({ success: false, message: "Your account has been blocked." });
      const token = jwt.sign({ id: user._id, sv: user.sessionVersion ?? 0, email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: req.header?.("X-Web-Session") === "1" ? "5d" : "7d" });
      return res.json({ success: true, token, user: publicGoogleUser(user) });
    } catch (error) {
      console.error('Google account login failed', { name: error.name, code: error.code, status: error.status });
      return res.status(error.status || 500).json({ success: false, message: error.status ? error.message : "Unable to complete Google login." });
    }
  };
}

export const googleTokenLogin = createGoogleTokenLogin();
