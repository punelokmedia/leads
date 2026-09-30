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

Deploy backend and admin web, then rebuild the mobile release. The new support
routes must be running before real chat can be used. Tests use an isolated local
MongoDB process: `node --test test/support.test.js`.
