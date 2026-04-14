import { ENV } from "../Config/env.config.js";
import mongoose from "mongoose";
import { User } from "../Models/user.model.js";
import { hashPassword } from "../Utils/hash.js";

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.DATABASE_URL);
    console.log("✅ MongoDB Connected");

    const adminEmail = process.env.ADMIN_EMAIL;

    if (!adminEmail || !process.env.ADMIN_PASSWORD) {
      throw new Error("ADMIN_EMAIL and ADMIN_PASSWORD are required in .env");
    }

    const existingAdmin = await User.findOne({ email: adminEmail });

    if (existingAdmin) {
      console.log("⚠️ Admin already exists");
      process.exit();
    }

    const hashedPassword = await hashPassword(process.env.ADMIN_PASSWORD);

    const firstname = process.env.ADMIN_FIRSTNAME || "Super";
    const lastname = process.env.ADMIN_LASTNAME || "Admin";

    const initials =
      `${firstname.charAt(0)}${lastname.charAt(0)}`.toUpperCase();

    const admin = await User.create({
      firstname,
      lastname,
      email: adminEmail,
      password: hashedPassword,
      role: "ADMIN",
      provider: "LOCAL",
      profilePic: `https://api.dicebear.com/5.x/initials/svg?seed=${initials}`,
      phoneNumber: process.env.ADMIN_PHONE || "",
      address: null, 
    });

    console.log("🚀 Admin created successfully");
    console.log({
      email: admin.email,
      password: process.env.ADMIN_PASSWORD,
    });

    process.exit();
  } catch (error) {
    console.error("❌ Error seeding admin:", error);
    process.exit(1);
  }
};


seedAdmin();
