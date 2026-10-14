# Live categories and support

The catalog contains the 17 category names used in the mobile preview. Run
`npm run seed:categories` to preview missing entries and
`npm run seed:categories -- --apply` to insert them into DATABASE_URL.
Existing categories are preserved; demo leads, payments and users are never imported.

The live mobile app reads `/api/v1/categories/get-all-categories`. Categories
without leads remain visible; actual lead records determine prices and budgets.

Authenticated support endpoints:

- GET /api/v1/support/messages — latest 100 messages belonging to the signed-in user.
  Supply `before=<message ID>` to load earlier messages.
- POST /api/v1/support/messages — `{text, clientId}`. Text is limited to 2000
  characters. Reuse clientId when retrying an uncertain send.
- GET /api/v1/support/admin/threads?page=1 — admin-only inbox, 50 conversations per page.
- GET /api/v1/support/admin/messages/:userId — admin-only conversation history.
- POST /api/v1/support/admin/messages/:userId — admin-only reply with `{text, clientId}`.

Messages are saved in MongoDB. Ownership comes from the authenticated identity,
never a user ID provided by the mobile client. The compound unique index prevents
duplicate messages from concurrent retries. Admin web has a Support Inbox page.
Mobile chat polls every 15 seconds while open and also has a refresh button.
Users may submit requests around the clock; human response times depend on staffing.
No simulated replies are sent in live mode.

## Customer and representative messaging

Support conversations are available in the Android app and the admin Support
inbox. The user website has no chat UI. Representatives currently sign in with
an ADMIN account; a separate restricted SUPPORT role is not implemented.

Message responses include authorName and readAt. Admin threads include
customerName and unreadCount. The admin inbox refreshes every 10 seconds while
visible; open conversations refresh every 15 seconds. Mobile chat pauses its
polling while the app is backgrounded and refreshes on resume. Admin and mobile
can load older conversation history. Messages persist between visits.

POST /api/v1/support/read and POST /api/v1/support/admin/read/:userId accept
`{through: messageId}` to mark incoming messages up to that loaded message as
read. The marker must belong to that conversation; newer messages are not
marked. Customers cannot access another customer's conversation or admin APIs.
Unread legacy messages initially count as unread. No index migration is needed
for the optional readAt field.

Replies use existing deduplicated SUPPORT_REPLY notification records. Native
push delivery and a mobile notification inbox integration remain separate work.
This is one conversation per customer; ticket numbering, assignment, attachments,
and resolved/closed statuses are not part of this messaging change.

Deploy backend and admin web, then rebuild the mobile release. The new support
routes must be running before real chat can be used. Tests use an isolated local
MongoDB process: `node --test test/support.test.js`.
