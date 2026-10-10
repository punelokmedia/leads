> Historical verification snapshot. The six backend failures have since been fixed; see [current six-fix results](six-security-fixes.md). Other findings are not automatically resolved.

# Security verification summary - NOT READY for a complete security sign-off

Date: 2026-10-10. Scope: local source, installed dependencies, loopback HTTP, disposable MongoDB 7.0.24 replica sets, synthetic users and mocked Razorpay. No production database queries/writes, real payments, deployment or application fixes were performed. This is a targeted local verification, not a certification or exhaustive penetration test.

Backend result: 99 tests, 93 pass, 6 fail. Failing security expectations remain enabled to make the findings reproducible. Evidence: [complete backend output](evidence/backend-tests.txt).

| Test | Method | Expected | Actual | Status | Severity | Recommended fix | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Backend tests | npm test | All functional and security assertions pass | 93/99 pass; 6 security assertions fail; exit 1 | FAIL | High/medium/low as detailed below | Fix demonstrated findings, retain failing tests, then rerun | [backend output](evidence/backend-tests.txt) |
| Backend build | npm run build | Syntax/build check succeeds | Exit 0; 58 JS source files checked | PASS | None | None | [build](evidence/backend-build.txt) |
| Backend lint | Inspect package scripts | Available lint check executed | No backend lint script | NOT TESTED | Low tooling gap | Define lint workflow if required | ../package.json |
| User web build/test/lint | npm run build:user; npm test -w user-web; npm run lint:user | Type checks/build/lint succeed | All exit 0; test script is tsc + ESLint, not a browser/unit test suite | PASS | Runtime coverage gap remains | Add staged browser security tests | [build](evidence/user-web-build.txt); [test](evidence/user-web-test.txt); [lint](evidence/user-web-lint.txt) |
| Admin web build/lint | npm run build:admin; npm run lint:admin | Type checks/build/lint succeed | Both exit 0 | PASS | None for those checks | None | [build](evidence/admin-web-build.txt); [lint](evidence/admin-web-lint.txt) |
| Admin web runtime tests | Inspect package scripts | Configured runtime tests run | No admin web test script | NOT TESTED | Medium coverage gap | Add browser/admin authorization regression coverage | ../../frontend/apps/admin-web/package.json |
| Flutter tests | Installed Flutter tool snapshot test --no-pub --suppress-analytics; SDK lock access needed for local tool | All existing widget/store tests pass | 17 pass, 2 fail; missing expected High Quality Leads and Leads Sell text; exit 1 | FAIL | Low/medium regression issue; not itself a proven exploit | Review changed UI against test expectations without deleting features | [Flutter output](evidence/mobile-tests.txt) |
| Flutter analysis | Dart analyze lib test with workspace telemetry directory | No warnings/errors | 43 issues: 14 warnings and 29 info; exit 2 | FAIL | Low/medium code-quality/dependency hygiene | Resolve analysis findings, including OTP print logging and referenced dependency declarations | [analysis](evidence/mobile-analyze.txt) |
| Release/staging penetration tests | No production endpoints or real customer accounts attacked | Isolated staging browser/device/gateway/infra checks | Not exercised | NOT TESTED | High assurance gap | Run remaining staging checks after local fixes | ../Project-Docs/wallet-security-operations.md |

## Final scorecard

| Security area | Status | Evidence |
| --- | --- | --- |
| Dependency vulnerabilities | FAIL overall; backend PASS | Backend 0; frontend 12 package entries (9 high), production frontend 2 inherited high entries |
| Wallet balance security | PASS locally | VER-01/08/11/19; replay/refund/membership tests; ledger reconciliation |
| Razorpay verification | PASS mocked; live NOT TESTED | VER-06/07; exact amounts/currency/owner/signatures and 20 duplicates |
| Referral fraud protection | PASS tested rules | VER-09: 20 retries, one reward; cap/self/qualification/ownership tests |
| Authentication | FAIL | Concurrent OTP reuse; logged-out JWT usable; Google bearer token in URL |
| Express API security | FAIL | Guards/proxy/CORS pass; unsupported Content-Type returns 500 |
| MongoDB security | FAIL; Atlas NOT TESTED | Financial transactions/indexes pass; phone identity index fails creation |
| Excel upload security | PASS tested cases; import duplicate policy NOT TESTED | EXCEL-01/02/03; invalid category/phone and formula/macro/archive cases |
| Admin access control | FAIL overall; route authorization PASS | Role/MFA guards pass; successful role promotion produces no audit event |
| Web and mobile security | FAIL; release behavior NOT TESTED | Token URL/localStorage; OTP logging; mobile HTTPS not enforced; frontend audit findings |
| Concurrency protection | FAIL overall; wallet/payment/referral PASS | 20-request financial stress tests and retry pass; concurrent OTP issues two sessions |

## Prioritized remaining work (no application fixes made in this pass)

1. **High: Google redirect leaks bearer JWT through URL.** VER-17 reproduces token query parameter. Replace with one-time code or secure cookie. URL capture can preserve reusable credentials; no external leak was attempted.
2. **High: phone identity index cannot be created.** VER-13 reproduces MongoDB CannotCreateIndex on unsupported partial-filter operator. Correct supported index predicate and inspect duplicates safely; production index state remains unknown. Do not use destructive sync/reset.
3. **High registry findings: frontend dependencies.** Full frontend audit: 12 affected package entries (9 high, 2 moderate, 1 low); production: react-router/react-router-dom inherited entries. Review applicability and update parents; avoid claiming the SSR/RSC findings are automatically exploitable in this browser-only SPA.
4. **Medium: OTP consumption is not atomic.** VER-15 schedules two concurrent reads of one valid OTP; both verification calls issue sessions. Use atomic conditional consume. Sequential OTP reuse protection passes but does not prevent this race.
5. **Medium: logout does not revoke issued JWT.** VER-14 logout succeeds, same token still reads wallet. Implement session revocation/refresh-token lifecycle or token version with short access-token lifetime.
6. **Medium: admin changes lack attributable audit.** VER-20 promotion succeeds with no persisted SecurityAudit event. Include verified actor, target, action, timestamp and before/after; independent export.
7. **Medium client risks:** localStorage bearer tokens accessible to injected scripts; unconditional mobile OTP/phone prints; mobile HTTPS not enforced and inspected local URL is HTTP. No browser XSS or device network attack was attempted. Remove sensitive prints and enforce HTTPS in release configuration.
8. **Low: unsupported login Content-Type yields 500.** VER-18 demonstrates text/plain request causing generic server failure/internal exception. Validate Content-Type/body before the controller.
9. **Regression/coverage:** fix two Flutter UI expectations and 43 analyzer issues; define duplicate Excel import business rule; add web runtime security tests.
10. **Production NOT TESTED:** Atlas roles/indexes/network/TLS; backup restore; hosting/GitHub/Razorpay MFA/permissions; deployment protection; ledger key and independent audit export; webhook secret; scheduled reconciliation. Local .env is missing security-operation keys; production configuration was not accessed.

## Reproduce safely

From backend: npm audit --json; npm audit; npm audit --omit=dev; npm ls --all; npm test; npm run build; node scripts/security-static-verification.js; node scripts/generate-security-reports.js. npm test intentionally exits 1 while the six security failures are present. Test suites create their own loopback Mongo replica sets; do not run wallet-security-check.js with a production DATABASE_URL as part of this verification.

From frontend: npm run build:user; npm test -w user-web; npm run lint:user; npm run build:admin; npm run lint:admin; npm audit --json; npm audit --omit=dev --json. Flutter: flutter test --no-pub --suppress-analytics and dart analyze lib test using the installed SDK. No pub install or dependency fix was performed in this verification.

Evidence is stored beside these six reports, with UTF-8 normalized command output and a SHA-256 manifest. Added verification code: test/security-verification.test.js, test/security-excel-verification.test.js, scripts/security-static-verification.js, scripts/generate-security-reports.js; expanded existing Excel test. No production application logic was changed.

## Scope limits

This run did not test network DDoS, WAF, real API gateway routing, OAuth provider/SMS delivery, production browser/device sessions, production database indexes/permissions, Git history for secrets, or live Razorpay callback/refund delivery. Referral device farming and human fraud investigation were not simulated. Stored audit entries and ORM immutability are verified locally; resistance to a privileged raw database writer depends on external roles/secrets/audit sink. Do not interpret the passing wallet tests or zero backend advisory count as proof that all attacks fail.

## Detailed reports

- [Dependency audit and all 22 historical entries](dependency-audit.md)
- [Wallet, referral and concurrency tests](wallet-security-test.md)
- [Payment verification](payment-security-test.md)
- [API, authentication and clients](api-security-test.md)
- [Database, Excel and administrative access](database-security-test.md)
