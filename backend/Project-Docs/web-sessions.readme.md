# Persistent website sessions

Website login issues a five-day JWT when the request includes `X-Web-Session: 1`.
Authenticated website requests renew it for another five days in the
`X-Session-Token` response header. Renewal is limited to once per minute, so
the inactivity boundary has up to one minute of granularity. The backend exposes
this header through CORS; the user website saves it silently and uses the latest
token for subsequent requests. Existing valid seven-day web tokens migrate on
their next authenticated request. Already expired tokens require a fresh login.

The website checks the profile on opening and when returning to the tab. There
is no periodic keepalive: leaving a tab idle does not continually extend login.
Daily authenticated use keeps wallet, referral, profile and order access active.
Mobile requests without the web header and admin sessions retain their existing
lifetimes. Session-version revocation and blocked-account checks still apply.

This implementation uses rolling bearer tokens, rather than a separate refresh
cookie. Tokens remain in the existing localStorage location. A renewed token
does not invalidate older tokens before their expiry; logout revokes them through
the existing sessionVersion check. All devices currently share that logout
revocation behavior. There is no separate maximum session lifetime.

Confirmed session errors carry SESSION_REQUIRED, SESSION_INVALID,
SESSION_REVOKED or SESSION_EXPIRED and return 401. The frontend clears its token
and saved profile, updates logged-in controls, and displays a site-wide sign-in
notice. Login password errors do not clear another valid session. Unexpected
authentication/database failures return 503 AUTH_UNAVAILABLE and preserve login.
Delayed responses cannot clear a newer login or restore a logged-out session.

Deploy the backend and user website together to enable renewal and error codes.
No database migration or additional environment variable is required.

Validation:

```text
cd backend
node --test test/web-session.test.js test/admin-setup.test.js test/vercel-startup.test.js test/google-auth.test.js test/production-auth.test.js
npm run build
cd ../frontend
npm run build:user
npm run lint:user
node --test apps/user-web/test/session.test.mjs
```
