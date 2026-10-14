# App support tickets

## Automated guidance and human handoff

New tickets start with a persisted message labeled Automated support assistant.
Customers choose an issue and select Get help for fixed troubleshooting guidance.
POST /tickets/:ticketId/automation accepts {choice: issueCode} or {choice: HUMAN}.
The human option records humanRequestedAt and inserts one retry-safe confirmation
that the ticket is in the human support queue. It does not promise availability
or automatically assign a representative. Admin ticket cards identify these
requests. The first representative reply records humanReplyAt, which the app
shows as a human response. Guidance buttons disappear after handoff/reply.
Automated messages have sender=automated and cannot be impersonated through
customer message submission. Automation cannot change balances, confirm payments,
approve refunds or mark tickets completed. Repeated selections do not duplicate
the same automated reply. Completed tickets reject new automation selections.
Existing tickets start automation when a customer selects a guidance option.

The Android support section provides Create ticket and My tickets. Customers
choose PAYMENT, WALLET, LEAD_QUALITY, DOWNLOAD, MEMBERSHIP, REFERRAL, ACCOUNT or
OTHER and provide a description. The server generates a unique NL- ticket ID,
stores the ticket in MongoDB and starts it as PENDING.

Statuses are PENDING (Pending), ACTION_TAKEN (Action taken), and COMPLETED
(Completed). Only admins can change them. Each change records its actor and
timestamp. Updates require expectedStatus and reject stale updates with 409.
Admins may also reopen tickets by selecting Pending. Customers see status in
their ticket list and conversation. Each ticket has a separate message history.
Existing unticketed conversations remain available in the admin legacy inbox.
The customer website has no ticket/chat UI.

Customer endpoints under /api/v1/support:

- GET /tickets?page=1&status=PENDING (status optional, 30 per page)
- POST /tickets: {issue, description, clientId}
- GET /tickets/:ticketId
- GET or POST /tickets/:ticketId/messages (existing message format)
- POST /tickets/:ticketId/read: {through: messageId}

The :ticketId route parameter is the document _id returned by the API; ticketId
in the body is the human-readable NL- display identifier. Customers can access
only their own tickets. Create retries with the same clientId return the same
ticket; using it for different content returns 409.

Admin equivalents use /admin/tickets and require ADMIN authentication (and
production MFA). POST /admin/tickets/:ticketId/status accepts
{status, expectedStatus}. The admin Support page lists all tickets with a status
filter, pagination, descriptions, conversations, replies and status history.

Before rollout, run `node scripts/init-support.js` against the intended database
to create additive ticket uniqueness and query indexes. This script does not
delete existing indexes or messages. Deploy backend and admin, then rebuild
Android. No production database or deployment was performed in this change.

Verification: `node --test test/support.test.js`, backend build, admin build/lint,
and Dart analysis of the changed mobile screens. These checks do not replace an
on-device smoke test: create a ticket, reply as admin, change to Action taken and
Completed, refresh in the app, and verify another customer cannot view it.
