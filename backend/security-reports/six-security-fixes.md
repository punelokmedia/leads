# Six security fixes — verified locally, 2026-10-10

All 99 original backend tests pass. Six additional regressions bring the suite to **105 passed, 0 failed**. No existing assertions were weakened or removed. No production database, customer wallet, real payment or deployment was accessed or modified.

| Original failure | Fix | Verification |
| --- | --- | --- |
| VER-13 | Phone uniqueness uses supported `$type: 'string', $gt: ''` partial filter. New empty/whitespace values normalize to absent. Read-only readiness inspection detects duplicate trimmed phone values and reports empty legacy fields without printing phone numbers. | Index creation passes; duplicate real phones fail; multiple absent phones allowed; synthetic duplicate preflight detects duplicates and prevents unique-index creation. |
| VER-14 | User sessionVersion increments on successful logout; every JWT issuer includes its current value and auth checks it against the database. Old JWTs without that claim remain compatible at version zero until revoked. | Old token returns 401 after logout; fresh password login issues version 1 and successfully authenticates. |
| VER-15 | Public login consumes a valid, unexpired OTP in a single conditional findOneAndUpdate before signing a session. Authenticated phone verification also updates the phone and consumes its OTP atomically. | Original concurrent verification passes; both routes permit exactly one successful verification. |
| VER-17 | Google redirect contains no bearer token or serialized user. A random one-minute code in the URL fragment exchanges for a session only with the matching browser verifier. Only hashed codes are persisted; exchange consumes atomically and checks expiry, account status and sessionVersion. All three web login entry points and callback handling updated. Native mobile Google ID-token POST remains supported. | Successful handoff, incorrect verifier, concurrent replay and expiry tested; token and user absent from redirect query. |
| VER-18 | Login validates Content-Type, object body and string credentials before accessing fields. | text/plain returns 415; malformed field types/arrays return 400; valid password login passes. |
| VER-20 | Existing-user promotion and email-based new-admin creation write an audit record in the same Mongo transaction as the role change. Audit includes actor, target, previous role, new role, timestamp and action. | Original successful-promotion check passes; audit details checked; simulated audit failure leaves target a USER. |

## Actual commands and results

| Command | Result | Evidence |
| --- | --- | --- |
| node --test test/security-verification.test.js | Exit 0: 26 passed, 0 failed | [Focused output](evidence/six-fixes-focused.txt) |
| npm test | Exit 0: 105 passed, 0 failed | [Full output](evidence/six-fixes-full.txt) |
| npm run build (backend) | Exit 0: 61 JavaScript source files checked | [Build](evidence/six-fixes-backend-build.txt) |
| npm audit (backend) | Exit 0: zero known findings | [Audit](evidence/six-fixes-audit.txt) |
| npm audit --omit=dev (backend) | Exit 0: zero known findings | [Production audit](evidence/six-fixes-production-audit.txt) |
| npm run build:user / build:admin | Both exit 0 | [User](evidence/six-fixes-web-build.txt), [admin](evidence/six-fixes-admin-build.txt) |
| npm run lint:user / lint:admin | Both exit 0, no warnings/errors | [User](evidence/six-fixes-web-lint.txt), [admin](evidence/six-fixes-admin-lint.txt) |

No backend lint script exists. Flutter source was unchanged in this fix; the preceding Flutter test/analysis failures were not addressed or claimed resolved.

## Files changed for this fix

- Backend models: [User](../src/Models/user.model.js), [new OAuth handoff](../src/Models/oauth-handoff.model.js).
- Backend authorization/controllers: [auth middleware](../src/Middlewares/auth.middleware.js), [auth controller](../src/Controllers/auth.controller.js), [native Google login](../src/Controllers/google-auth.controller.js), [new code exchange](../src/Controllers/oauth-handoff.controller.js), [admin controller](../src/Controllers/Admin/admin.controller.js), [auth routes](../src/Routes/auth.routes.js).
- Index readiness: [read-only service](../src/Services/user-index-readiness.js), [local check script](../scripts/check-user-phone-index.js).
- Web handoff: [helper](../../frontend/apps/user-web/src/features/auth/googleHandoff.ts), [header/callback](../../frontend/apps/user-web/src/components/layout/PublicHeader.tsx), [mobile auth page](../../frontend/apps/user-web/src/features/auth/pages/MobileAuthPage.tsx), [mobile auth drawer](../../frontend/apps/user-web/src/features/auth/pages/MobileAuthDrawerPage.tsx).
- Admin web: [logout now calls backend revocation](../../frontend/apps/admin-web/src/features/auth/context/AdminAuthContext.tsx).
- Tests: [security verification](../test/security-verification.test.js), six appended regressions. Original 99 cases retained.
- Reports: this report, saved command evidence, and historical-summary pointer.

## Rollout requirements and remaining limitations

Logout revokes **all current sessions for that account**, including other devices. Web/mobile user clients already call backend logout and clear local state; admin web now also requests backend logout. If a device is offline, local logout can clear its token but cannot contact the server to revoke it until connectivity is available.

Deploy the backend and updated user web together when explicitly authorized: the old web Google redirect format is replaced. Google callbacks must echo the initiation state; the handoff collection needs its unique/TTL indexes. Exchange explicitly checks expiration, independent of TTL cleanup. Browser cryptography requires a secure context (HTTPS or localhost). Live provider redirect and installed-device behavior require a staging smoke test; this run used synthetic callbacks and no Google/Razorpay network calls.

Before production index rollout, an administrator must inspect existing phone duplicates, whitespace/empty values and actual index definitions. Tests inspected only disposable local data. The readiness helper is read-only and outputs counts; the executable deliberately requires an explicit local URI rather than loading DATABASE_URL. Existing duplicates are never automatically merged/deleted, and no index is automatically dropped or synced. If a differently defined phoneNumber_1 index exists, its replacement requires a reviewed migration. Correcting the source definition does not establish the production index state.

SessionVersion defaults to zero for legacy users. Existing signed tokens continue working until logout increments that account's version. Previously exposed bearer tokens are not globally invalidated by deployment alone; reviewed session invalidation may be required. Never rotate live secrets or alter real accounts automatically as part of these tests.

Remaining findings from the earlier comprehensive report are outside these six fixes: frontend dependency advisories, browser localStorage token risk, mobile sensitive logging/HTTPS configuration, two Flutter UI failures and analyzer issues, broader privileged-action audit coverage, and unverified production permissions/MFA/backups/secret management/audit export. Zero backend audit findings and passing tests do not guarantee protection against every attack.
