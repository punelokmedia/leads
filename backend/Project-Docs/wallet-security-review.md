# Wallet security review

Reviewed 10 October 2026 against the supplied checklist. Scope: current working-tree backend, React web wallet/auth integration, Flutter wallet integration, and focused tests. This is a code review, not a penetration test or verification of deployed infrastructure. No production payment or balance was changed.

## Priority findings

1. **High: refunds and disputes after a top-up are not reconciled against the wallet.** `creditCapturedTopup` rejects already-refunded payments at credit time, but the webhook handles only `payment.captured`. A later refund or chargeback can leave previously credited money spendable. Define reversal, account restriction, insufficient-balance, and fraud-review rules; implement idempotent compensating ledger entries rather than editing existing transactions.
2. **High: no application rate limiting or OTP attempt limit found.** Wallet top-up requests can create database records and gateway orders repeatedly. The admin login uses an emailed four-digit OTP without evidence of an independent second factor. Add shared limits for OTP issuance/verification and wallet mutations, and enforce strong MFA for privileged accounts. An upstream limiter may exist but was not verified.
3. **High: ledger records are ordinary mutable MongoDB documents.** Unique keys prevent duplicate inserts; they do not prevent administrators or production code from updating/deleting records. No independent protected audit trail or ledger-to-balance reconciliation was found. Restrict ledger update/delete permissions, monitor balance/ledger differences, and export audit events to separately controlled storage. Application hooks alone cannot protect against database administrators.
4. **High: referral farming remains possible across multiple accounts.** Self-referral and duplicate qualification are prevented, and the ₹100 lifetime cap is enforced transactionally. There is no observed device/payment-identity abuse detection, minimum eligible paid-spend threshold, or refund/fraud reversal policy. A successful low-price purchase can trigger a ₹50 reward, including a purchase funded by referral credits. Decide eligibility rules before introducing controls that change the business policy.
5. **Medium: operation idempotency is incomplete.** Captured top-up settlement and membership activation are idempotent. Lead access cannot be purchased twice, but retries do not accept a stable client operation key to return the original completed purchase. Top-up creation retries can create multiple gateway orders. Add request keys scoped to user and operation, preserving the validated amount/selection associated with each key.
6. **Medium: monetary consistency needs stronger boundaries.** Wallet entries and top-ups validate integer paise, but wallet user fields are generic numbers and lead/order prices remain rupee floating-point values converted with rounding. Add integer/range validation to balance writes and define a consistent integer-paise pricing policy. Verify actual unique indexes before accepting payments; schema declarations do not prove deployed indexes exist.
7. **Medium: web bearer tokens are stored in localStorage.** This exposes authenticated wallet access if the frontend suffers script injection. Review XSS controls and consider HttpOnly-cookie sessions with appropriate CSRF protection. CORS alone does not protect against injected same-origin code.

## Checklist status

| Control | Status | Evidence or remaining work |
| --- | --- | --- |
| Server-authoritative balances | Implemented in reviewed wallet API | Only verified top-ups and qualified referrals credit balances; no balance-setting route found. |
| Atomic debit/credit and lead access | Implemented, infrastructure dependent | MongoDB snapshot/majority transactions; conditional sufficient-balance debit; purchase access commits with debit. Requires a replica set. |
| Immutable/tamper-evident ledger | Partial | Unique transaction keys and history exist; no tamper evidence or protected independent storage. |
| Razorpay verification and idempotency | Partial | Timing-safe HMAC checks, authoritative gateway fetch, ownership/capture/currency/amount checks; request creation and post-credit reversals need work. |
| MFA and least-privilege access | Unverified / partial | App roles exist. Admin email OTP is not evidence of MFA. Atlas, hosting, repository and Razorpay account permissions were not inspected. |
| Dual approval for manual adjustments | Not implemented | No manual wallet adjustment endpoint found; production DB/deployment privileges can bypass application controls. |
| Independent protected audit logs | Not found | Ledger and routine console logs are not an independent audit system. |
| Encrypted backups/tested recovery | Unverified | Requires Atlas/backup configuration and restore evidence. |
| API authorization and rate-limit tests | Partial | Wallet ownership and signature tests pass; rate limits and their tests are missing. |
| Referral abuse and concurrency tests | Partial | Rollback, duplicate qualification and cap tested; multi-account abuse and reversals not covered. |
| Secret scanning/dependency security checks | Unverified / not found in CI | No tracked GitHub workflow found. Reviewed web/mobile environment files had no nonempty secret/password/private/database keys; this does not scan Git history or deployed APKs. |
| Independent production audit | Not performed | Arrange deployment/configuration review and penetration testing before claiming production readiness. |

## Validation

22 focused backend tests passed for wallet, referrals, checkout concurrency, and lead-access authorization. These cover captured-payment validation, wrong ownership, invalid signatures, duplicate credits, insufficient funds, membership retries, transaction rollback, referral caps, two-buyer inventory limits, repeat-purchase blocking, history privacy and pagination.

Missing test coverage includes post-credit refunds/disputes, signed wallet webhook replay end-to-end, two concurrent wallet purchases of different leads exhausting the same balance, simultaneous rewards competing at a referrer's lifetime cap, rate limits, and reconciliation after lost gateway-order creation responses.

The current product exposes purchase credits and no bank withdrawal endpoint was found. Withdrawal functionality would require a separately reviewed design. No claims about regulatory classification are made here.

## Recommended sequence

1. Define top-up/referral reversal policy and enforce it transactionally; add the corresponding failure and concurrency tests.
2. Add shared rate limits, privileged MFA, request idempotency and bounded monetary validation.
3. Verify production database roles, unique indexes, TLS, secret management, test/live environment isolation, deployment reviews, and MFA across all external accounts.
4. Add independent audit/reconciliation alerts and document a tested backup restore process.
5. Complete independent production security testing. Passing the current tests does not establish bank-grade security or protection against unrestricted production administrators.
