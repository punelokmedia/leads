import { resend } from "../Config/resend.config.js";
import { ENV } from "../Config/env.config.js";
import { transporter } from "../Config/email.config.js";

const RESEND_FROM_EMAIL = ENV.RESEND_FROM_EMAIL || "onboarding@resend.dev";
const SMTP_FROM_EMAIL = ENV.EMAIL_USER;

const sendWelcomeEmail = async (recipientEmail, name) => {
  try {
    await resend.emails.send({
      from: RESEND_FROM_EMAIL,
      to: recipientEmail,
      subject: "Welcome to Lead sells 🚀",
      html: `
      <div style="margin:0; padding:0; background:#f4f6f8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
        
        <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 15px;">
          <tr>
            <td align="center">

              <!-- Card -->
              <table width="520" style="background:#ffffff; border-radius:16px; overflow:hidden; box-shadow:0 10px 30px rgba(0,0,0,0.06);">
                
                <!-- Top Bar -->
                <tr>
                  <td style="height:5px; background:linear-gradient(90deg,#ffcc00,#ff9900);"></td>
                </tr>

                <tr>
                  <td style="padding:40px 35px; text-align:center;">

                    <!-- Logo -->
                    <div style="margin-bottom:20px;">
                      <div style="font-size:24px; font-weight:700; letter-spacing:1px; color:#111;">
                        LEADS
                      </div>
                      <div style="font-size:13px; color:#999; margin-top:2px;">
                        on demand
                      </div>
                    </div>

                    <!-- Title -->
                    <h1 style="margin:0 0 15px; font-size:26px; font-weight:700; color:#111; line-height:1.3;">
                      Welcome, ${name} 👋
                    </h1>

                    <!-- Description -->
                    <p style="margin:0 auto; max-width:420px; color:#555; font-size:15px; line-height:1.7;">
                      You're now part of a smarter way to grow your business.  
                      Discover high-quality leads, connect faster, and close more deals 🚀
                    </p>

                    <!-- Button -->
                    <a href="#" style="
                      display:inline-block;
                      margin-top:28px;
                      padding:14px 32px;
                      background:linear-gradient(90deg,#ffcc00,#ff9900);
                      color:#ffffff;
                      text-decoration:none;
                      border-radius:10px;
                      font-weight:600;
                      font-size:14px;
                      letter-spacing:0.3px;
                      box-shadow:0 6px 18px rgba(255,153,0,0.25);
                    ">
                      Explore Leads
                    </a>

                    <!-- Divider -->
                    <div style="margin:35px 0 25px; border-top:1px solid #eee;"></div>

                    <!-- Footer -->
                    <p style="font-size:12.5px; color:#888; line-height:1.6;">
                      Need help? Contact our support anytime.<br/><br/>
                      If you didn’t create this account, you can safely ignore this email.
                    </p>

                  </td>
                </tr>
              </table>

            </td>
          </tr>
        </table>
      </div>
      `,
    });
  } catch (error) {
    console.error(error);
    throw error;
  }
};

const forgetPasswordEmail = async (recipientEmail, username, otp) => {
  try {
    await resend.emails.send({
      from: RESEND_FROM_EMAIL,
      to: recipientEmail,
      subject: "Reset Your Password 🔐",
      html: `
      <div style="background:#f6f6f6; padding:50px; font-family:Arial;">
        
        <div style="max-width:520px; margin:auto; background:#fff; border-radius:18px; box-shadow:0 12px 40px rgba(0,0,0,0.08); overflow:hidden;">
          
          <!-- Top Gradient -->
          <div style="height:6px; background:linear-gradient(90deg,#ffcc00,#ff9900);"></div>

          <div style="padding:35px; text-align:center;">

            <h2 style="margin:0; color:#111;">Reset Password</h2>

            <p style="color:#666; font-size:14px; margin-top:10px;">
              Hello <b>${username}</b>, use the OTP below to reset your password.
            </p>

            <!-- OTP BOX -->
            <div style="
              margin:30px 0;
              padding:18px;
              font-size:36px;
              font-weight:bold;
              letter-spacing:10px;
              background:linear-gradient(135deg,#fff7cc,#ffe680);
              border-radius:14px;
              color:#ff9900;
              box-shadow: inset 0 2px 8px rgba(0,0,0,0.05);
            ">
              ${otp}
            </div>

            <p style="color:#777; font-size:13px;">
              This OTP expires in <b>10 minutes</b>.
            </p>

            <p style="font-size:11px; color:#aaa; margin-top:20px;">
              For security reasons, do not share this code with anyone.
            </p>

          </div>
        </div>
      </div>
      `,
    });
  } catch (error) {
    console.error(error);
    throw error;
  }
};

const sendAdminOtpEmail = async (recipientEmail, name, otp) => {
  const subject = "Admin Login Verification 🔐";
  const html = `
    <div style="background:#f6f6f6; padding:50px; font-family:Arial;">
        
      <div style="max-width:520px; margin:auto; background:#fff; border-radius:18px; box-shadow:0 12px 40px rgba(0,0,0,0.08); overflow:hidden;">
        
        <!-- Top Gradient -->
        <div style="height:6px; background:linear-gradient(90deg,#ffcc00,#ff6600);"></div>

        <div style="padding:35px; text-align:center;">

          <!-- Title -->
          <h2 style="margin:0; color:#111;">Admin Login Verification</h2>

          <!-- Greeting -->
          <p style="color:#666; font-size:14px; margin-top:10px;">
            Hello <b>${name || "Admin"}</b>, use the OTP below to securely login to your admin panel.
          </p>

          <!-- OTP BOX (same style but slightly stronger) -->
          <div style="
            margin:30px 0;
            padding:18px;
            font-size:36px;
            font-weight:bold;
            letter-spacing:10px;
            background:linear-gradient(135deg,#fff7cc,#ffe680);
            border-radius:14px;
            color:#ff6600;
            box-shadow: inset 0 2px 8px rgba(0,0,0,0.05);
          ">
            ${otp}
          </div>

          <!-- Info -->
          <p style="color:#777; font-size:13px;">
            This OTP is valid for <b>5–10 minutes</b>.
          </p>

          <!-- Security Warning -->
          <p style="font-size:11px; color:#aaa; margin-top:20px;">
            If you did not request this login, please secure your account immediately.
          </p>

        </div>
      </div>
    </div>
    `;

  // Use the configured Gmail sender directly; Resend is only for SMTP-free setups.
  if (SMTP_FROM_EMAIL && ENV.EMAIL_PASSWORD) {
    const info = await transporter.sendMail({
      from: SMTP_FROM_EMAIL,
      to: recipientEmail,
      subject,
      html,
    });
    return { id: info.messageId, provider: "smtp" };
  }

  const response = await resend.emails.send({
    from: RESEND_FROM_EMAIL,
    to: recipientEmail,
    subject,
    html,
  });
  if (response.error) throw new Error(response.error.message);
  return response;

};

export { sendWelcomeEmail, forgetPasswordEmail, sendAdminOtpEmail };