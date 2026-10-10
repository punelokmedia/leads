# Backend security remediation - 2026-10-10

Local changes only. No deployment, production database operation, credential change, or real payment was performed.

## Audit evidence

Original saved production report had 22 affected packages. Fresh full baseline: {"info":0,"low":0,"moderate":10,"high":12,"critical":2,"total":24}. Final full audit: {"info":0,"low":0,"moderate":0,"high":0,"critical":0,"total":0}. Final production audit: {"info":0,"low":0,"moderate":0,"high":0,"critical":0,"total":0}. No reported advisory remains in the installed backend tree. This is an npm registry advisory result, not proof that the application cannot be attacked. Original advisory inventory in wallet-dependency-audit.md is historical; current raw evidence is ../wallet-dependency-audit.json and ../wallet-dependency-audit-production.json.

## Changes

- package.json and package-lock.json: compatible dependency refresh; reviewed Nodemailer major upgrade retaining createTransport/sendMail usage; added Helmet and explicit JSZip dependency; removed obsolete npm crypto and vulnerable xlsx. Removed nodemon dependency and preserved local restart through node --watch. ExcelJS remains 4.4.0. Its CommonJS uuid v4 consumer uses a scoped uuid ^11.1.1 override; v11 supports CommonJS. Conditional-format XLSX roundtrip verifies this path. No force audit fix, deprecated ExcelJS downgrade, or global incompatible override used.
- src/app.js: Helmet headers, explicit disabled proxy trust, removal of wildcard extension CORS access, JSON 256 KiB and URL-encoded 32 KiB/100 parameters, request guards and generic final errors. Existing CORS allowlist and raw Razorpay webhook buffer preserved.
- src/Middlewares/request-security.js: reject nested Mongo operators, dotted/prototype keys, excessive object depth; hide parser/upload/unhandled errors.
- src/Middlewares/security-limits.js, src/Routes/payment.routes.js, src/Routes/referral.routes.js: shared database-backed authenticated payment 20/minute and referral 10/minute limits alongside existing wallet/auth/OTP limits. Signed gateway webhook excluded from account limiter so legitimate retries can reconcile.
- src/Config/email.config.js: SMTP STARTTLS required, certificate validation, disable file and URL content access. No credentials changed.
- src/Services/excel-import.js, src/Controllers/Admin/leads.controller.js, src/Middlewares/fileupload.middleware.js: ExcelJS replaces SheetJS parser, matching existing column/category mapping. Uploaded XLSX capped at 5 MiB, 200 archive files, 10 MiB per decompressed file, 20 MiB combined, 5,000 data rows, 100 columns, 10,000 characters per cell. Reject formula cells, macro/external-link parts, XML entities, duplicate/prototype headers and malformed ZIP content. In-memory parser/export, no temporary file creation. ExcelJS string values remain strings in export, never converted to formula objects.
- src/Routes/auth.routes.js: remove internal OAuth exception from response.
- test/bulk-lead-upload.test.js and test/request-security.test.js: import mapping and rejection regressions, HTTP operator/prototype/parser/body/header checks, compatible UUID/export regression.
- .gitignore: exclude local npm cache.

## Exact locked version changes

Compared with repository HEAD lockfile (which matches the original audited direct versions):

| Package path | Before | After |
| --- | --- | --- |
| node_modules/@mongodb-js/saslprep | 1.5.4 | 1.6.0 |
| node_modules/axios | 1.15.0 | 1.20.0 |
| node_modules/balanced-match | 4.0.4 | 1.0.2 |
| node_modules/bare-fs | 4.8.2 | 4.8.4 |
| node_modules/body-parser | 2.2.2 | 2.3.0 |
| node_modules/brace-expansion | 5.0.5 | 1.1.21 |
| node_modules/bson | 7.2.0 | 7.3.3 |
| node_modules/content-disposition | 1.1.0 | 2.0.1 |
| node_modules/content-type | 1.0.5 | 2.1.0 |
| node_modules/cookie-signature | 1.2.2 | 1.0.6 |
| node_modules/dayjs | 1.11.20 | 1.11.23 |
| node_modules/dotenv | 17.4.1 | 17.4.2 |
| node_modules/es-object-atoms | 1.1.1 | 1.1.2 |
| node_modules/express | 5.2.1 | 5.3.0 |
| node_modules/follow-redirects | 1.15.11 | 1.16.1 |
| node_modules/form-data | 4.0.5 | 4.0.6 |
| node_modules/google-auth-library | 11.1.0 | 11.2.0 |
| node_modules/google-auth-library/node_modules/gcp-metadata | 9.0.4 | 9.1.0 |
| node_modules/hasown | 2.0.2 | 2.0.4 |
| node_modules/iconv-lite | 0.7.2 | 0.7.3 |
| node_modules/isarray | 1.0.0 | 2.0.5 |
| node_modules/kareem | 3.2.0 | 3.4.0 |
| node_modules/media-typer | 1.1.0 | 1.1.1 |
| node_modules/minimatch | 10.2.5 | 3.1.5 |
| node_modules/mongodb | 7.6.0 | 7.7.0 |
| node_modules/mongodb-connection-string-url | 7.0.1 | 7.0.2 |
| node_modules/mongodb-memory-server-core/node_modules/tar-stream | 3.2.1 | 3.2.2 |
| node_modules/mongoose | 9.4.1 | 9.11.1 |
| node_modules/multer | 2.1.1 | 2.4.0 |
| node_modules/negotiator | 1.0.0 | 1.1.0 |
| node_modules/node-addon-api | 8.7.0 | 8.9.2 |
| node_modules/nodemailer | 8.0.5 | 10.1.0 |
| node_modules/postal-mime | 2.7.4 | 2.7.6 |
| node_modules/proxy-addr | 2.0.7 | 2.0.8 |
| node_modules/qs | 6.15.1 | 6.16.0 |
| node_modules/range-parser | 1.2.1 | 1.3.0 |
| node_modules/razorpay | 2.9.6 | 2.9.8 |
| node_modules/readdir-glob/node_modules/brace-expansion | 2.1.0 | 2.1.7 |
| node_modules/resend | 6.10.0 | 6.32.1 |
| node_modules/semver | 7.7.4 | 7.8.5 |
| node_modules/side-channel | 1.1.0 | 1.1.1 |
| node_modules/standardwebhooks | 1.0.0 | 1.1.1 |
| node_modules/tmp | 0.2.5 | 0.2.7 |
| node_modules/traverse | 0.3.9 | 0.3.10 |
| node_modules/type-is | 2.0.1 | 2.1.0 |
| node_modules/uuid | 10.0.0 | 11.1.1 |

Added helmet 8.3.0; explicit jszip 3.10.1 (previously transitive). Removed xlsx 0.18.5, crypto 1.0.1, nodemon 3.1.14 and unused transitive dependency chains. Razorpay now resolves patched axios 1.20.0. Resend now uses its updated webhook dependency tree.

## Validation

- npm test: 76 passed, 0 failed. Real local replica-set transaction tests cover insufficient funds/rollback, concurrent membership/purchases/topups, exact server prices/payment amounts/currency/ownership, duplicate callbacks, refund/debt freeze and referral revocation/cap. No live payment is made.
- npm run build: syntax check passed. No lint script exists in this backend.
- npm audit and npm audit --omit=dev: zero findings.
- Existing Excel import customer phone normalization/category mapping passes. New tests reject formula/prototype/macro/oversized archive uploads and exercise conditional-format export.

## Production requirements and limits

Deploy only after staging smoke tests for login/email, add money, wallet history, membership/lead purchase, XLSX import/download and signed Razorpay test-mode callbacks. Dependencies and lockfile must be deployed together via npm ci. This local result does not validate gateway delivery, production database settings, hosting TLS or secrets.

Follow wallet-security-operations.md: configure strong external ledger HMAC key and independent HTTPS audit sink/token; configure gateway refund/dispute webhook and scheduled maintenance/export; provision required unique/TTL indexes; verify Atlas least-privilege roles/network allowlist, database/hosting TLS, backups and successful restore, secret manager rotation, provider MFA and production admin password plus OTP. Existing unsigned ledger rows need supervised reconciliation before rollout; do not rewrite financial history automatically.

Proxy trust intentionally remains false; hosting must supply verified proxy addresses before enabling forwarded-IP trust. Account-based limits work independently, but shared proxy IPs can make auth IP limits restrictive. Default localhost origins are limited to development; production uses only explicitly configured origins. Review that configured allowlist before deployment. Rate limits mitigate abusive requests but do not replace infrastructure DDoS protection. Negative financial balances/debt, wallet freeze, ledger tamper evidence and server-side pricing/ownership protections remain in place. Request guards do not replace controller allowlists or per-resource authorization.
