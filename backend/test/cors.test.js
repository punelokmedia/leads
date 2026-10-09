import test from "node:test";
import assert from "node:assert/strict";
import mongoose from "mongoose";

process.env.VERCEL = "1";
process.env.ADMIN_FRONTEND_URL = "https://leads-a2hi.vercel.app/";
process.env.CORS_ALLOWED_ORIGINS = " https://trusted.example/ , ";
process.env.RAZORPAY_KEY_ID = "rzp_test_only";
process.env.RAZORPAY_KEY_SECRET = "test_only";
process.env.RESEND_API_KEY = "re_test_only";

test("trusted admin preflight succeeds without database access", async (t) => {
  t.mock.method(mongoose, "connect", () => assert.fail("preflight must not connect"));
  const { app } = await import("../src/app.js");
  const server = app.listen(0, "127.0.0.1");
  await new Promise(resolve => server.once("listening", resolve));
  try {
    for (const origin of ["https://leads-a2hi.vercel.app", "https://trusted.example"]) {
      const response = await fetch(`http://127.0.0.1:${server.address().port}/api/v1/admin/send-otp`, {
        method: "OPTIONS",
        headers: {
          Origin: origin,
          "Access-Control-Request-Method": "POST",
          "Access-Control-Request-Headers": "content-type,authorization",
        },
      });
      assert.equal(response.status, 204);
      assert.equal(response.headers.get("access-control-allow-origin"), origin);
      assert.equal(response.headers.get("access-control-allow-credentials"), "true");
      assert.match(response.headers.get("access-control-allow-methods"), /POST/);
      assert.equal(response.headers.get("access-control-allow-headers"), "content-type,authorization");
    }
    const blocked = await fetch(`http://127.0.0.1:${server.address().port}/api/v1/admin/send-otp`, {
      method: "OPTIONS",
      headers: { Origin: "https://untrusted.example", "Access-Control-Request-Method": "POST" },
    });
    assert.equal(blocked.headers.get("access-control-allow-origin"), null);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
});
