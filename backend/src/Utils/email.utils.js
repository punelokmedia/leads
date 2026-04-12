import { transporter } from "../Config/email.config.js";

const sendWelcomeEmail = async (recipientEmail, username) => {
  try {
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: recipientEmail,
      subject: "Welcome to Our Service!",
      text: `Hello ${username},\n\nThank you for registering! We're excited to have you on board.\n\nBest Regards,\nTeam`,
      html: `<h1>Welcome, ${username}!</h1><p>Thank you for registering with us. We're excited to have you on board.</p><p>Best Regards,<br>Team</p>`,
    });
  } catch (error) {
    console.error("Error sending welcome email:", error);
    throw error;
  }
};

const forgetPasswordEmail = async (recipientEmail, username, otp) => {
  try {
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: recipientEmail,
      subject: "Password Reset OTP",
      html: `
        <h2>Hello ${username}</h2>
        <p>Your OTP for password reset is:</p>
        <h1>${otp}</h1>
        <p>This OTP will expire in 10 minutes.</p>
      `,
    });
  } catch (error) {
    console.error("Error sending OTP email:", error);
    throw error;
  }
};

export { sendWelcomeEmail, forgetPasswordEmail };
