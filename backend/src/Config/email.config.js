import nodemailer from "nodemailer";
import { ENV } from "./env.config.js";

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false,
  auth: {
    user: ENV.EMAIL_USER,
    pass: ENV.EMAIL_PASSWORD,
  },
});

const adminTransporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false,
  auth: {
    user: ENV.ADMIN_SMTP_USER,
    pass: ENV.ADMIN_SMTP_PASSWORD,
  },
});

export { transporter, adminTransporter };
