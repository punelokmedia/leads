import { User } from "../Models/user.model.js";

export async function resolveGoogleUser(profile) {
  if (!profile.sub || !profile.email || profile.email_verified !== true) {
    throw Object.assign(new Error("A verified Google email is required."), { status: 401 });
  }
  const email = profile.email.trim().toLowerCase();
  const allowedEmails = (process.env.USER_GOOGLE_ALLOWED_EMAILS || "")
    .split(",").map((value) => value.trim().toLowerCase()).filter(Boolean);
  if (allowedEmails.length && !allowedEmails.includes(email)) {
    throw Object.assign(new Error("This account does not have access to the testing app."), { status: 403 });
  }
  let user = await User.findOne({ googleId: profile.sub });
  if (!user) user = await User.findOne({ email });
  if (user?.isBlocked) {
    throw Object.assign(new Error("Your account has been blocked."), { status: 403 });
  }
  if (user?.googleId && user.googleId !== profile.sub) {
    throw Object.assign(new Error("This email is linked to another Google account."), { status: 401 });
  }
  if (user) {
    user.googleId = profile.sub;
    user.providers = [...new Set([...(user.providers || []), "GOOGLE"])];
    await user.save();
    return user;
  }
  return User.create({
    firstname: profile.given_name || profile.name || "Google",
    lastname: profile.family_name || "User",
    email,
    googleId: profile.sub,
    providers: ["GOOGLE"],
    role: "USER",
    profilePic: profile.picture || "",
  });
}

export function publicGoogleUser(user) {
  const fields = ["_id", "firstname", "lastname", "email", "phoneNumber", "role", "profilePic", "city", "businessName", "workType", "registrationFeePaid"];
  return Object.fromEntries(fields.map((key) => [key, user[key]]));
}
