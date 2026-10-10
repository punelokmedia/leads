Wallet amounts are stored in integer paise. Only a captured INR Razorpay payment matching a persisted top-up order, or a newly qualified referral, can credit a wallet. No API accepts a replacement balance or arbitrary credit.

Referral policy: ₹50 to the referrer after the referred user's first successful lead purchase; ₹100 lifetime credit maximum per referrer, even after spending rewards. Existing qualified referrals are not credited retroactively.

Authenticated USER endpoints under `/api/v1/wallet`:

- GET `/`: balance, lifetime referral credit and the latest 50 ledger entries.
- GET `/history?cursor=<nextCursor>`: older private ledger entries, 50 per page. The wallet screen shows transaction type, date, and signed amount below the balance, with a button to load older transactions.
- POST `/topup`: `{ "amountPaise": 50000 }`, between ₹1 and ₹10,000. Returns the Razorpay public key, order ID and amount in paise.
- POST `/verify`: Razorpay order ID, payment ID and signature. Fetches the payment from Razorpay; checks ownership, capture, amount and currency before crediting once.
- POST `/membership`: charges the server's ₹1 lifetime membership price once.
- POST `/purchase`: `{ "leadIds": [...] }`. Uses current server lead prices and inventory reservations; wallet debit, ledger, paid order, contact access and referral qualification commit in one MongoDB transaction.

The mobile cart and membership screens use the wallet. Existing direct Razorpay endpoints remain for compatibility with other clients and outstanding orders.

The user web app has a `/wallet` page linked from the header, with authenticated balance, Razorpay top-ups, referral-credit totals, and paginated wallet history. Web lead checkout and lifetime membership activation now debit the wallet; Razorpay checkout opens only for wallet top-ups in the current web UI.

Deployment requires MongoDB transactions (replica set/Atlas) and the unique indexes on WalletEntry.key and WalletTopup.gatewayOrderId/paymentId. Verify indexes before accepting payments if automatic index creation is disabled. Keep Razorpay private keys and the webhook secret exclusively on the backend; never bundle them in mobile assets.

Configure a Razorpay `payment.captured` webhook at `/api/v1/payments/razorpay-webhook` with `RAZORPAY_WEBHOOK_SECRET`. The webhook fetches authoritative payment data and uses the same credit transaction as app verification. Persistent Node deployments also reconcile pending top-ups every 30 seconds. Serverless deployments need the webhook or an external reconciliation job; interval maintenance does not run on Vercel.

Validate live top-up, interrupted app callback, repeated webhook delivery, membership and lead purchases in Razorpay test mode before production rollout. This change does not deploy backend changes or configure the gateway.

Security hardening and deployment requirements: see wallet-security-operations.md. Referral eligibility now requires a first paid purchase and net verified top-ups of at least INR 50.
