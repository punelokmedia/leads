# User Google sign-in

Web uses GET `/api/v1/auth/google` and the browser callback. Flutter Android
uses native Google sign-in and POSTs `{ "idToken": "..." }` to the same path.
The POST verifies Google's signature, expiry, issuer and the web client audience
with `google-auth-library`, then returns `{ success, token, user }`.

## Backend and user web

Set these in the backend environment (examples for local development):

```dotenv
USER_GOOGLE_CLIENT_ID=<Web application OAuth client ID>
MOBILE_USER_GOOGLE_CLIENT_ID=<Web application OAuth client ID used by native mobile>
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
MOBILE_USER_GOOGLE_CLIENT_ID=<same Web application client ID as backend MOBILE_USER_GOOGLE_CLIENT_ID>
```

The API origin is configured in `lib/core/network/api_config.dart`, with production
default `https://leads-qa6h.vercel.app/`. Override it at build/run time with
`--dart-define=BASE_URL=https://your-public-api.example/`; `.env.local` BASE_URL
is not read by the current app. Use a public production domain. A Vercel protected
preview deployment returns HTTP 401 before the backend runs, even with valid
Google credentials. Recreating OAuth clients cannot fix deployment protection.

Never put the OAuth client secret in the Flutter app. The mobile serverClientId must
be a Web application OAuth client ID, even when it is dedicated to mobile login.
The backend token endpoint accepts both USER_GOOGLE_CLIENT_ID and
MOBILE_USER_GOOGLE_CLIENT_ID as audiences. Browser OAuth continues to use
USER_GOOGLE_CLIENT_ID and its matching secret. Set both IDs in Vercel's production
environment and redeploy after changing them; rebuild mobile after changing its environment.

In the same Google Cloud project, register an **Android** OAuth client with:

- Package: `com.leadssell.user_app`
- SHA-1: the fingerprint of the certificate used to sign the installed APK.

Obtain signing fingerprints from `android/gradlew.bat signingReport` in the
Flutter project. Register the debug certificate for debug APKs and the actual
release/Play signing certificate for distributed APKs. Direct release APK builds
now use the existing debug signing key registered as Android client 1. Bundle
tasks retain the upload keystore from `android/key.properties` for Play upload.
Native iOS requires a separate iOS OAuth client and
its reversed-client-ID URL scheme; that account-specific setup is not included.

Rebuild Flutter after updating its environment file.

### Release failure investigation (2026-10-16)

The previous directly built release APK used the upload key (`4F:E0:...`),
which did not match either Android OAuth registration supplied by the user.
Direct APK signing now selects the existing local debug keystore:

- Package: `com.leadssell.user_app`
- Direct APK signing SHA-1: `C0:B3:4C:94:20:2B:95:E9:7E:39:9B:02:A3:62:92:7A:0A:6C:FA:31`
- Google deployment certificate SHA-1: `8C:81:75:00:98:18:33:52:C9:AD:B5:DB:8D:D1:36:00:86:65:69:E0`

Use `flutter build apk --release` for direct installation and
`flutter build appbundle --release` for Play upload. Keep the existing local
`%USERPROFILE%/.android/debug.keystore` stable: another machine's automatically
generated debug key has a different fingerprint and needs its own registration.
Debug keys are for local testing; production distribution should use Play signing
or a secured dedicated release key registered with Google OAuth. An APK signed
with the old upload key cannot be updated in place by the local-key APK; Android
requires uninstalling that old APK first, which removes its local application data.

Compare these exact values with the Android OAuth client in the same Google Cloud
project as the configured mobile Web client. This local check does not establish
what is registered in Google Cloud. Play-distributed builds may use a different
Play App Signing certificate; check the certificate of the installed distribution.

The screenshot's `Google account sign-in failed (sign_in_failed)` is emitted
before token exchange with the backend. It cannot be fixed by changing backend
timeouts. The plugin groups several native failures under this same code. The
app now preserves Google's numeric status in its error message, including when
R8 renames the native exception class. Capture that numeric status or connected
device logs before diagnosing a specific provider failure. Do not recreate OAuth
clients or signing keys as a troubleshooting step.

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
