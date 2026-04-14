import { resend } from "../Config/resend.config.js";

const sendWelcomeEmail = async (recipientEmail, username) => {
  try {
    await resend.emails.send({
      from: "onboarding@resend.dev", // or your verified domain
      to: recipientEmail,
      subject: "Welcome to Our Service!",
      html: `
        <h1>Welcome, ${username}!</h1>
        <p>Thank you for registering! We're excited to have you on board.</p>
        <p>Best Regards,<br/>Team</p>
      `,
    });
  } catch (error) {
    console.error("Error sending welcome email:", error);
    throw error;
  }
};

const forgetPasswordEmail = async (recipientEmail, username, otp) => {
  try {
    await resend.emails.send({
      from: "onboarding@resend.dev",
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

const sendAdminOtpEmail = async (recipientEmail, otp) => {
  const response = await resend.emails.send({
    from: "onboarding@resend.dev",
    to: recipientEmail,
    subject: "Admin Login OTP",
    html: `
      <h2>Admin Login Request</h2>
      <p>Your OTP for admin login is:</p>
      <h1 style="color: #4CAF50;">${otp}</h1>
      <p>This OTP is valid for 5-10 minutes.</p>
    `,
  });

  if (response.error) {
    throw new Error(response.error.message);
  }

  return response;
};

export { sendWelcomeEmail, forgetPasswordEmail, sendAdminOtpEmail };
