# Backend notifications

Base URL: `/api/v1/notifications` (API_VERSION may override v1). All endpoints require the existing bearer token or session cookie.

| Method | Path | Body / query |
| --- | --- | --- |
| GET | `/` | Optional `before` ObjectId cursor, `limit` 1–100, `unread=true` |
| GET | `/unread-count` | Returns `data.count` |
| PATCH | `/:id/read` | Marks only the authenticated user's notification read |
| PATCH | `/read-all` | Marks the user's unread notifications read |
| GET | `/preferences` | Returns `newLeads`, `announcements`, `push` |
| PATCH | `/preferences` | Boolean fields, e.g. `{"newLeads":true,"push":true}` |
| POST | `/devices` | `{"token":"<FCM token>","platform":"android","permission":"granted"}`; platform can also be ios/web |
| DELETE | `/devices` | `{"token":"<FCM token>"}`; call before logout and when permission is revoked |
| POST | `/admin/send` | Admin only: `{"userIds":["<user ObjectId>"],"title":"Update","message":"Details","clientId":"unique-send-id"}`; max 100 recipients per call |
| POST | `/:id/received` | Owner only: `{"channel":"mobile"}` or `{"channel":"web"}`; confirms the client received this inbox item |
| GET | `/admin/summary` | Admin only: totals and counts by type; optional `userId`, `type`, `read=true/false`, `from`, `to` |
| GET | `/admin/notifications` | Admin only: all recipient inbox records; same filters plus `before` and `limit` 1–100 |
| GET | `/admin/notifications/:id` | Admin only: recipient, receipts, preferences and device metadata; excludes tokens and authentication fields |
| GET | `/admin/recipients` | Admin only: eligible users for the send form; optional literal name/email/user-ID search `q` (max 100 characters) and `before` cursor; 30 users per page |

List responses include `data` and `nextCursor`. Types identify the destination screen; `targetId` identifies the lead, order, top-up, or support message. Fetch destination data through its existing authorized API. Notification text excludes purchased contact details and support message contents.

New leads: unblocked USER accounts whose profile city/state (case insensitive, literal match) and selected category match the lead. The lead must be active, unexpired, and have fewer than two buyers. A missing profile match receives no alert. Membership is not required for discovery alerts. `newLeads=false` suppresses future lead inbox items.

Confirmed lead payments, wallet top-ups, and wallet membership activation create inbox items in the same MongoDB transaction as the business operation. Refund processing creates an item only after the gateway confirms the refund. Admin support replies create an item for the conversation owner. Announcements go to the explicit eligible user IDs and respect `announcements=false`.

Unique `(user,eventKey)` indexes deduplicate business events and retries. Reuse an announcement clientId only to retry the same send; use a new clientId for a new announcement. Preferences do not delete history. Read status is shared across clients.

Before serving traffic, run `node scripts/init-notifications.js` to initialize notification indexes without sending notifications. Schedule `node scripts/reconcile-notifications.js` periodically to repair interrupted lead fanout. It scans all currently active leads in batches, including existing leads, and safely skips previously delivered user/event pairs. Large recipient fanouts run sequentially; move them to a dedicated worker as traffic grows. Do not run reconciliation if you do not want existing active leads to generate inbox alerts.

This first phase delivers persisted inbox notifications. Device registration records permission reported by the client; it cannot grant or independently verify OS/browser permission. Push defaults to false. Device registration alone does not enable push preference. Firebase transport, push retry jobs, and frontend permission prompts are not implemented yet; no phone/browser alerts are sent by this phase. The inbox works without push permission. Tokens must be unlinked by the client before logout; automatic logout cleanup is not yet integrated.

Financial operations now require the notification collection to be writable to commit. A failed notification write rolls back the business transaction and is retried using the existing transaction behavior. Lead fanout failure is logged without undoing lead creation and can be repaired by reconciliation. Support send retries with the same clientId repair a failed notification write.

## Admin monitoring and client receipts

Admin summary includes `saved`, `read`, `unread`, `received`, `awaitingClient`, `mobileReceived`, `webReceived`, all seven notification types (including zero counts), and explicit push configuration status. Dates use ISO timestamps, e.g. `from=2026-10-12T00:00:00.000Z`. Filters apply to notification creation time. Use `userId` to check one user's counts and history. The same admin authorization, including production MFA, protects every monitoring endpoint.

`SAVED` means the notification exists in MongoDB for its recipient. `AWAITING_CLIENT` means no client has acknowledged receipt; it does not mean delivery failed. `RECEIVED` means the authenticated owner has reported receiving it through mobile and/or web. `readAt` separately records the owner's mark-as-read action. Push status remains `NOT_CONFIGURED`; no saved or acknowledged record is presented as a delivered push alert.

When the frontend is built, it must call `POST /:id/received` after receiving each notification from the inbox API, specifying its channel. A receipt is idempotent per notification/channel and preserves the first server receipt timestamp. One notification received by both mobile and web counts once in `received`, once in `mobileReceived` and once in `webReceived`. Clients cannot acknowledge another user's notification. Receipts are authenticated client reports, not independent proof of OS delivery or human viewing. Acknowledging receipt does not mark it read.

Admin diagnostics show persisted inbox records and receipts, not every attempted or suppressed event. Opted-out, blocked and unmatched recipients have no inbox record. Failed generation is still handled through business transaction retries or lead reconciliation, not a separate failure dashboard. No frontend or Firebase transport is included in this phase. Re-run the additive index initialization script before deploying these monitoring changes; it now includes receipt indexes.
