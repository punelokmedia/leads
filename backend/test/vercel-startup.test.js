import test from "node:test";
import assert from "node:assert/strict";
import mongoose from "mongoose";

process.env.VERCEL = "1";
process.env.RAZORPAY_KEY_ID = "rzp_test_only";
process.env.RAZORPAY_KEY_SECRET = "test_only";
process.env.RESEND_API_KEY = "re_test_only";

test("Vercel entry exports an app without opening a listener or database connection", async (t) => {
  t.mock.method(mongoose, "connect", () => assert.fail("must not connect on import"));
  const { default: app } = await import("../index.js");
  assert.equal(typeof app, "function");
  const server = app.listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));
  try {
    const response = await fetch(`http://127.0.0.1:${server.address().port}/`);
    assert.equal(response.status, 200);
    assert.equal((await response.json()).success, true);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("database failures reject without exiting and a later attempt can retry", async (t) => {
  process.env.DATABASE_URL = "mongodb://example.invalid/test";
  const { connectDB } = await import("../src/Config/db.connection.config.js");
  let calls = 0;
  t.mock.method(process, "exit", () => assert.fail("must not exit the function"));
  t.mock.method(mongoose, "connect", async () => {
    calls++;
    if (calls === 1) throw new Error("test database failure");
    return mongoose;
  });
  await assert.rejects(connectDB(), /test database failure/);
  await Promise.all([connectDB(), connectDB()]);
  assert.equal(calls, 2);
});
