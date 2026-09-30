# Two-buyer checkout

Each lead can be allocated to at most two buyers. Each account can buy it once.
The limit is enforced in the backend, including for old documents whose stored
`maxBuyers` is 3. Existing sales are retained; historical overselling cannot be
undone. Leads with two or more recorded sales are closed to further checkout.

## What happens when three buyers tap Pay

1. Checkout reserves a slot in a MongoDB transaction before creating a Razorpay
   order. Adding to cart alone does not reserve anything.
2. The first two successful database reservations can open payment. The third
   request receives HTTP 409 and no payment order. Device timestamps do not
   decide priority.
3. A reservation lasts 10 minutes. Expired reservations no longer consume stock.
   Explicit cancellation releases it earlier. An offline client does not need to
   run a cleanup request for expiry to take effect.
4. A captured payment converts its valid reservation into one purchase. The
   buyer count, purchase entitlement and paid order commit together. Multi-lead
   orders are all-or-nothing. Duplicate callback/webhook requests do not allocate
   more slots. The payment owner, gateway order, amount, currency and capture
   status are checked server-side.
5. Once both purchases complete, browsing returns `SOLD_OUT`. While both slots
   are reserved, it returns `RESERVED` instead. No client receives reservation
   user IDs or internal order IDs through public lead endpoints.

An already-open Razorpay payment window can complete after its reservation was
cancelled or expired. This cannot be prevented solely by hiding the Buy button.
Such a capture grants **no contact access** and creates a durable full-refund job.
The app displays the backend's refund-pending message and receipt status.

## Deployment requirements

- Use MongoDB Atlas or another replica set with transactions. Standalone MongoDB
  cannot run this checkout. There is no nontransactional fallback.
- Deploy the backend and clients together, and stop old server instances first:
  an old instance could still use the former payment-verification implementation.
- Configure `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, and
  `RAZORPAY_WEBHOOK_SECRET`. Register `/api/v1/payments/razorpay-webhook` for
  `payment.captured`; the JSON parser preserves the exact signed bytes.
- Keep the backend process running. Its 30-second maintenance loop reconciles
  recent checkout payments and retries durable refund jobs. Signed webhooks
  handle late captures, including beyond the seven-day reconciliation window.
- Monitor `paymentrefunds` for repeated `lastError` / `attempts`. Refund processing
  depends on gateway availability and balance. An external partial refund needs
  reconciliation; the worker deliberately does not submit another partial refund.
- The new purchase uniqueness index applies only to version-2 purchases so old
  duplicate records do not prevent startup. Audit historical paid orders with
  missing purchase records: contact access now requires an actual purchase
  entitlement, not merely a `PAID` label from the old partial-success flow.

Refund retries first fetch gateway state and use the full captured amount, never
a newly calculated partial amount. The gateway's maximum-refundable-amount check
also prevents a duplicate request from refunding more than the captured amount.
Refund jobs survive process restarts; a refund is not marked complete just because
it was submitted.

## Verification

```powershell
cd backend
node --test test/lead-inventory.test.js test/lead-access.test.js
node --test test/checkout-concurrency.test.js
```

The concurrency suite uses a fresh temporary MongoDB replica set and a fake
gateway, never the configured production database. It covers three simultaneous
buyers, duplicate verification, repeat purchases, cancelled/expired reservations,
late payments, ownership, payment amounts, rollback, and refund retries.

**Current validation:** the real-database concurrency suite has been written but
its execution was blocked by automatic approval review hitting the account usage
limit. Complete that suite and a Razorpay test-mode checkout before deployment.
No production purchases, refunds, database migration or deployment were performed.

Implementation references:
- [MongoDB transactions and automatic transaction retries](https://www.mongodb.com/docs/drivers/node/current/crud/transactions/)
- [Razorpay refund API](https://d6xcmfyh68wv8.cloudfront.net/docs/api/refunds/)
