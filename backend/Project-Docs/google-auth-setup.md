# User Google sign-in

Web uses GET `/api/v1/auth/google` and the browser callback. Flutter Android
uses native Google sign-in and POSTs `{ "idToken": "..." }` to the same path.
The POST verifies Google's signature, expiry, issuer and the web client audience
with `google-auth-library`, then returns `{ success, token, user }`.

## Backend and user web

Set these in the backend environment (examples for local development):

```dotenv
USER_GOOGLE_CLIENT_ID=<Web application OAuth client ID>
USER_GOOGLE_CLIENT_SECRET=<Web application OAuth client secret>
USER_GOOGLE_CALLBACK_URL=http://localhost:5000/api/v1/auth/google/callback
API_BASE_URL=http://localhost:5000
API_VERSION=v1
FRONTEND_URL=http://localhost:5174
```

Register the exact USER_GOOGLE_CALLBACK_URL under authorized redirect URIs on the
Google Cloud Web application client. FRONTEND_URL must point to **user-web**.
User-web uses fixed development port 5174 so it does not collide with admin-web.
If the OAuth app is in testing mode, add the accounts that will test it.

Set `VITE_API_BASE_URL` in user-web to the backend origin, without `/api/v1`.
Restart Vite after changing it. Deployments and phone-browser OAuth should use
an HTTPS backend and frontend reachable by the phone, with matching registered
redirect URIs. `localhost` on a phone refers to the phone itself.

## Flutter Android

In `frontend/mobile/user_app/.env.local`, set:

```dotenv
USER_GOOGLE_WEB_CLIENT_ID=<same Web application client ID as backend USER_GOOGLE_CLIENT_ID>
BASE_URL=<backend origin reachable from the phone>
```

Never put the OAuth client secret in the Flutter app. Set the mobile public client ID to the new user Web client ID. The new user
credential fields are intentionally blank until that client is created.

In the same Google Cloud project, register an **Android** OAuth client with:

- Package: `com.leadssell.user_app`
- SHA-1: the fingerprint of the certificate used to sign the installed APK.

Obtain signing fingerprints from `android/gradlew.bat signingReport` in the
Flutter project. Register the debug certificate for debug APKs and the actual
release/Play signing certificate for distributed APKs. The current release
build uses debug signing. Native iOS requires a separate iOS OAuth client and
its reversed-client-ID URL scheme; that account-specific setup is not included.

Rebuild Flutter after updating its environment file.

## Verification

### Private Google-login testing

Google's Testing audience is not an application authorization list: basic
openid/email/profile sign-in has an exception to the test-user restriction.
To restrict Google login in both web and mobile, set the backend environment:

```env
USER_GOOGLE_ALLOWED_EMAILS=first-tester@example.com,second-tester@example.com
```

Use the actual approved emails, then redeploy the backend. Addresses are matched
case-insensitively against Google's verified email before looking up or creating
a user. Unlisted accounts receive HTTP 403. An empty/unset value permits all
verified Google accounts, subject to the existing blocked-account check.
This setting controls new Google logins; it does not revoke existing sessions
or restrict the separate phone OTP flow. Remove it when opening Google login
to the public. Never put this authorization list in the mobile client.

The mobile Google token exchange allows 90 seconds for a slow backend response.
Render free services can take about a minute to wake up; this timeout does not
guarantee first-attempt success for network or provider failures. Cart-sync
failure no longer reports successful authentication as a failed login.

References: https://support.google.com/cloud/answer/15549945 and
https://render.com/docs/free#spinning-down-on-idle

Run `node --test test/google-auth.test.js` from backend and `npm run build` from
user-web. For a live check, sign in with a new Google account and confirm
onboarding, then a paid existing account and confirm it reaches home. Confirm a
blocked account cannot log in. Automated checks do not establish Google Cloud
registration or replace the interactive account-picker and consent test.

## Admin separation

The user routes use only USER_GOOGLE_* and the named google-user strategy.
They never fall back to ADMIN_GOOGLE_* or legacy GOOGLE_* credentials.
Existing legacy values are preserved for compatibility, and ADMIN_GOOGLE_*
values are copied from them in the local environment. No admin OAuth handler
exists in this workspace; configure those values in the service actually
handling the admin callback. Missing user credentials return HTTP 503 without
preventing the backend from starting. Restart backend and rebuild Flutter after
entering the new credentials.
