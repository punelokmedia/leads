import test from "node:test";
import assert from "node:assert/strict";
import jwt from "jsonwebtoken";
import { createGoogleTokenLogin } from "../src/Controllers/google-auth.controller.js";
import { resolveGoogleUser } from "../src/Utils/google-user.js";
import { User } from "../src/Models/user.model.js";

process.env.USER_GOOGLE_CLIENT_ID = "test-client";
process.env.GOOGLE_CLIENT_ID = "legacy-admin-client-must-not-be-used";
process.env.ADMIN_GOOGLE_CLIENT_ID = "admin-client-must-not-be-used";
process.env.JWT_SECRET = "test-secret-only";
const identity = { sub: "google-id", email: "user@example.com", email_verified: true };
test("new Google users without a surname pass schema validation", async (t) => {
  t.mock.method(User, "findOne", async () => null);
  t.mock.method(User, "create", async (data) => {
    const user = new User(data);
    assert.equal(user.validateSync(), undefined);
    assert.equal(user.role, "USER");
    assert.equal(user.lastname, "User");
    return user;
  });
  await resolveGoogleUser({ ...identity, given_name: "Sam" });
});
test("existing Google identity cannot be replaced by a different subject", async (t) => {
  t.mock.method(User, "findOne", async (query) => query.googleId ? null : { googleId: "different-id" });
  await assert.rejects(resolveGoogleUser(identity), { status: 401 });
});
function response() {
  return { statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };
}
test("missing user credentials never fall back to admin credentials", async () => {
  const saved = process.env.USER_GOOGLE_CLIENT_ID;
  delete process.env.USER_GOOGLE_CLIENT_ID;
  try {
    const res = response();
    await createGoogleTokenLogin({ verify: () => assert.fail("must not verify using admin configuration") })({ body: { idToken: "token" } }, res);
    assert.equal(res.statusCode, 503);
  } finally {
    process.env.USER_GOOGLE_CLIENT_ID = saved;
  }
});
test("requires a token before verification", async () => {
  const res = response();
  await createGoogleTokenLogin({ verify: () => assert.fail("must not verify") })({ body: {} }, res);
  assert.equal(res.statusCode, 400);
});
test("rejects invalid signatures, expiry or audience before accessing users", async () => {
  const res = response();
  await createGoogleTokenLogin({ verify: async (options) => {
    assert.equal(options.audience, "test-client");
    throw new Error("invalid token");
  }, resolveUser: () => assert.fail("must not access database") })({ body: { idToken: "invalid" } }, res);
  assert.equal(res.statusCode, 401);
});
test("rejects unverified Google emails", async () => {
  const res = response();
  await createGoogleTokenLogin({ verify: async () => ({ getPayload: () => ({ ...identity, email_verified: false }) }), resolveUser: () => assert.fail("must not access database") })({ body: { idToken: "token" } }, res);
  assert.equal(res.statusCode, 401);
});
test("blocked users do not receive a session", async () => {
  const res = response();
  await createGoogleTokenLogin({ verify: async () => ({ getPayload: () => identity }), resolveUser: async () => ({ isBlocked: true }) })({ body: { idToken: "token" } }, res);
  assert.equal(res.statusCode, 403);
  assert.equal(res.body.token, undefined);
});
test("returns the mobile session contract without exposing private user fields", async () => {
  const res = response();
  await createGoogleTokenLogin({ verify: async () => ({ getPayload: () => identity }), resolveUser: async () => ({ _id: "user-id", email: identity.email, role: "USER", password: "private", resetOtp: "private" }) })({ body: { idToken: "token" } }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(jwt.verify(res.body.token, process.env.JWT_SECRET).id, "user-id");
  assert.equal(res.body.user.password, undefined);
  assert.equal(res.body.user.resetOtp, undefined);
});
