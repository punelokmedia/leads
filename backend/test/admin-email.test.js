import test from "node:test";
import assert from "node:assert/strict";

process.env.EMAIL_USER = "sender@example.com";
process.env.EMAIL_PASSWORD = "test-password";
process.env.RESEND_API_KEY = "re_test_only";
const { transporter } = await import("../src/Config/email.config.js");
const { resend } = await import("../src/Config/resend.config.js");
const { sendAdminOtpEmail } = await import("../src/Utils/email.resend.utils.js");

test("admin OTP uses Gmail without attempting Resend", async (t) => {
  t.mock.method(resend.emails, "send", () => assert.fail("Resend must not be called"));
  t.mock.method(transporter, "sendMail", async (mail) => {
    assert.equal(mail.from, "sender@example.com");
    assert.equal(mail.to, "admin@example.com");
    assert.match(mail.html, /123456/);
    return { messageId: "smtp-test" };
  });
  assert.deepEqual(await sendAdminOtpEmail("admin@example.com", "Admin", "123456"), { id: "smtp-test", provider: "smtp" });
});

test("SMTP failures are reported without switching to the unverified domain", async (t) => {
  t.mock.method(resend.emails, "send", () => assert.fail("Resend must not be called"));
  t.mock.method(transporter, "sendMail", async () => { throw new Error("SMTP authentication failed"); });
  await assert.rejects(sendAdminOtpEmail("admin@example.com", "Admin", "123456"), /SMTP authentication failed/);
});
