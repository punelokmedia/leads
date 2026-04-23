import passport from "passport";
import { Strategy as GoogleStrategy } from "passport-google-oauth20";
import { User } from "../Models/user.model.js";

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL:
        process.env.NODE_ENV === "production"
          ? `${process.env.API_BASE_URL}/api/v1/auth/google/callback`
          : "http://localhost:5000/api/v1/auth/google/callback",
    },
    async (req, accessToken, refreshToken, profile, done) => {
      try {
        const email = profile.emails?.[0]?.value;

        let user = await User.findOne({ email });

        const first = profile.name?.givenName || "User";
        const last = profile.name?.familyName || "";

        const initials = `${first[0]}${last[0] || ""}`.toUpperCase();

        if (user) {
          if (!user.providers) user.providers = [];

          if (!user.googleId) {
            user.googleId = profile.id;
          }

          if (!user.providers.includes("GOOGLE")) {
            user.providers.push("GOOGLE");
          }

          await user.save();
        } else {
          user = await User.create({
            firstname: first,
            lastname: last,
            email,
            googleId: profile.id,
            providers: ["GOOGLE"],
            profilePic: `https://api.dicebear.com/5.x/initials/svg?seed=${initials}`,
          });
        }

        return done(null, user);
      } catch (err) {
        return done(err, null);
      }
    },
  ),
);

export default passport;
