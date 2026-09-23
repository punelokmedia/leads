import passport from "passport";
import { Strategy as GoogleStrategy } from "passport-google-oauth20";
import { resolveGoogleUser } from "../Utils/google-user.js";

const baseUrl = (process.env.API_BASE_URL || "http://localhost:" + (process.env.PORT || 5000)).replace(/\/$/, "");
if (process.env.USER_GOOGLE_CLIENT_ID && process.env.USER_GOOGLE_CLIENT_SECRET) {
passport.use("google-user", new GoogleStrategy({
  clientID: process.env.USER_GOOGLE_CLIENT_ID,
  clientSecret: process.env.USER_GOOGLE_CLIENT_SECRET,
  callbackURL: process.env.USER_GOOGLE_CALLBACK_URL || baseUrl + "/api/" + (process.env.API_VERSION || "v1") + "/auth/google/callback",
}, async (accessToken, refreshToken, profile, done) => {
  try {
    const user = await resolveGoogleUser({
      sub: profile.id,
      email: profile.emails?.[0]?.value,
      email_verified: profile._json?.email_verified === true,
      given_name: profile.name?.givenName,
      family_name: profile.name?.familyName,
      name: profile.displayName,
      picture: profile.photos?.[0]?.value,
    });
    done(null, user);
  } catch (error) { done(error, null); }
}));
}
export default passport;
