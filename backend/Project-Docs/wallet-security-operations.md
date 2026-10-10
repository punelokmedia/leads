# Wallet security rollout and operations

## Implemented in source

- MongoDB-backed wallet mutation limits: 20 requests per account per minute. Auth limits: 60 POSTs per IP per 15 minutes, five verification/login attempts per account per 15 minutes, three OTP issues per account per 15 minutes. These are fixed windows and can permit boundary bursts. Unavailable limit storage fails closed. TTL cleanup does not reset a live bucket.
- Production admin login requires the persisted admin password plus email OTP. Protected admin routes require the corresponding signed token claim. Existing admin sessions need to log in again. This does not configure phishing-resistant MFA for Atlas, hosting, GitHub or Razorpay.
- New ledger records are HMAC signed, include a transactionally persisted audit outbox record, and reject normal model updates/deletes/bulk writes. Raw collection/database administrator access can bypass model hooks. The protected signing key and independent sink must be controlled separately from developers.
- Top-up refund totals are reconciled cumulatively from fetched Razorpay payments. Signed dispute events conservatively reverse the full top-up. Duplicate/out-of-order events cannot deduct twice. Any amount already spent becomes wallet debt; wallets freeze for review. Associated rewarded referrals are reversed once and moved to REVIEW. Lifetime referral cap is not replenished.
- Frozen wallets cannot initiate top-ups, membership or wallet lead purchases. Payments on previously issued top-up orders still settle, but do not unfreeze or automatically repay tracked debt.
- Referral qualification now requires both a first paid lead purchase of at least ₹50 and at least ₹50 in net verified top-ups. Same-phone and reciprocal referrals, frozen accounts and insufficient eligibility go to REVIEW without credit. `WALLET_REFERRAL_MIN_PURCHASE_PAISE` sets the threshold, default 5000. The zero threshold in legacy baseline tests is an explicit test override. These checks reduce abuse; they do not establish real-world identity or detect every multi-account scheme.

## Required configuration before deployment

1. Set `WALLET_LEDGER_HMAC_KEY` to a cryptographically random secret of at least 32 bytes in the hosting secret store. Never bundle it in web/mobile. Production ledger writes fail without it. Keep it stable; key rotation needs a versioned verification/migration plan.
2. Set `SECURITY_AUDIT_URL` to an independently controlled HTTPS ingestion endpoint and `SECURITY_AUDIT_TOKEN` to its restricted write token. It receives `{ events: [...] }`; deduplicate by eventKey. Restrict deletion/retention changes on the sink separately from application deployment permissions. Do not send these records to a user-controlled URL.
3. Subscribe the signed Razorpay webhook to `payment.captured`, `refund.created`, `refund.processed`, and available `payment.dispute.*` events. Configure `RAZORPAY_WEBHOOK_SECRET` separately for each environment. A won/closed dispute does not automatically restore credits: it remains frozen for reviewed resolution.
4. Create/verify wallet, audit and limiter indexes before rollout. Use Atlas/replica-set transactions. Audit outbox failures roll back financial transactions. Do not enable automatic index deletion in production.
5. Persistent Node maintenance exports audit events every 30 seconds. On Vercel or other serverless hosting, schedule `node scripts/wallet-security-check.js --export` from a restricted runner. The script exports pending audits, verifies signatures, and checks `ledger total = wallet balance - wallet debt`. Nonzero unsigned/tampered/mismatch counts exit unsuccessfully. Alert on failure and export backlog.
6. Existing unsigned ledger records are reported as unsigned; do not silently sign them as proof of authenticity. Establish a reviewed historical baseline against gateway receipts and independent records before migration.
7. Ensure production admin accounts have persisted bcrypt password hashes and explicit ADMIN roles provisioned through the reviewed seeder, then deploy the updated admin web client and backend together. Login cannot auto-create/promote an admin based on ADMIN_EMAIL in production. Password plus email OTP is required; rotate/revoke existing tokens as part of rollout.

## Production controls requiring external verification

These cannot be verified or enabled solely by editing this repository:

- Require individual accounts and MFA on Atlas, deployment hosting, GitHub and Razorpay. Prefer security keys/passkeys. Remove shared/root credentials from developers.
- Use a custom least-privilege Atlas application role: insert/find ledger entries, no update/remove on the ledger; required scoped privileges for balances, top-ups, orders, audits and limiter records. Test transactions with the proposed role in staging before rollout. Separate audit-sink ownership and database administration.
- Restrict production deployment and secret access; enforce reviewed protected branches and separation of test/live keys and databases.
- Enable encrypted backups/PITR with retention according to business requirements. Perform and record a restore into an isolated database, verify financial reconciliation, and measure recovery time/data-loss window. Never test a restore over production.
- Use TLS for database/HTTPS connections, restricted Atlas network access, and provider secret stores. A local .env file is not evidence of secure production secret management.
- Resolve frozen/debt accounts and exceptional adjustments through two-person approval with independent evidence. No unfreeze/manual adjustment endpoint was added; direct ad hoc database changes must not become the operational workflow. A reviewed adjustment system remains a separate implementation requirement.
- Add security scanning to CI, review dependency audit results, and arrange independent penetration testing. Current test coverage does not prove infrastructure controls or bank-grade security.

## Verification boundary

Code-level tests cover reversals/debt/freeze, duplicate events, signature tampering, append-only model guards, audit records, shared attempt limits and referral eligibility holds. The external audit destination, production account MFA, Atlas permissions and backups have not been configured or verified in this session.

Razorpay event references: https://razorpay.com/docs/webhooks/payloads/refunds/ and https://razorpay.com/docs/webhooks/payloads/disputes/.
