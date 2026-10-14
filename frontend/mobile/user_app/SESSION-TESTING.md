# Testing saved-session recovery

Run from the repository root in PowerShell:

```powershell
Set-Location frontend/mobile/user_app
flutter.bat pub get
flutter.bat test --no-pub test/auth_interceptor_test.dart test/session_recovery_test.dart test/live_store_test.dart test/widget_test.dart
```

Or run `scripts/test-session-recovery.ps1` from the mobile app directory if PowerShell script execution is enabled. This suite uses mocked storage and responses. It does not contact the production API, send OTPs, change accounts, or require waiting seven days.

## What the tests verify

| Situation | Expected behavior | Test file |
| --- | --- | --- |
| Saved token rejected with HTTP 401 | Remove rejected token; notify app | `test/auth_interceptor_test.dart` |
| Session rejection notification | Signed-in state becomes false; router opens `/login` | `test/session_recovery_test.dart` |
| Sign in after a rejected saved token | Next request uses fresh token and succeeds without reinstalling | `test/auth_interceptor_test.dart` |
| No internet, connect timeout, receive timeout | Preserve login; retry succeeds when the connection returns | `test/auth_interceptor_test.dart` |
| HTTP 403, 429, 500, 503 | Preserve login; do not mistake these errors for token expiry | `test/auth_interceptor_test.dart` |
| Request uses an older or explicit token | Preserve explicit header; rejection cannot clear a different saved token | `test/auth_interceptor_test.dart` |
| Anonymous request receives HTTP 401 | No session-expiry event | `test/auth_interceptor_test.dart` |
| Home load fails and retries | No sample data fallback; retry can load real response data | `test/live_store_test.dart` |
| App startup | Root app builds with the same ProviderScope used by main | `test/widget_test.dart` |

## Where to inspect a new failure

1. `lib/core/network/auth_interceptor.dart`: outgoing Authorization header and incoming status. Never log the token itself.
2. `lib/core/network/dio_provider.dart`: actual API base URL and session-expiry event wiring.
3. `lib/app/user_app.dart`: clears authentication/profile state and routes to login.
4. `lib/features/auth/shared/auth_providers.dart`: saved-token login state.
5. `lib/features/preview/live_store.dart`: home requests, including profile and history; one failed request can fail the home refresh.
6. `lib/features/profile/infra/profile_repository.dart`: profile response/error handling.
7. `backend/src/Middlewares/auth.middleware.js`: `SESSION_EXPIRED`, `SESSION_REVOKED`, `SESSION_INVALID`, or `AUTH_UNAVAILABLE` response code.

Record the failing endpoint, HTTP status, response code, Dio error type, app version, and time. Wi-Fi being on does not prove an API request succeeded. A 401 points to credentials; a 503 or timeout requires a different investigation.

## Phone checks before release

Use a staging backend and test account for intentional session expiry/revocation.

1. Install the updated app over the previous app without uninstalling. Open Home and My Profile with an existing valid login. Both should load.
2. Revoke the test account's session in staging (increment that user's `sessionVersion`, preserving its other data). With the app still holding the old token, refresh Home or My Profile. It must open Sign in, and signing in again must restore both screens without reinstalling. Reset any staging changes after the check.
3. Sign in, enable airplane mode, and refresh Home/Profile. An error should appear and the saved login should remain. Turn airplane mode off and press Retry; data should load.
4. Force-stop and reopen with a valid saved login. Verify Home and Profile still load. Repeat the staging revocation check with the app force-stopped before reopening.
5. Repeat on all four affected devices, using both Wi-Fi and mobile data. Save the app version and results for each device.

For a real expired-token check, use a staging-only backend build with a short mobile token lifetime in the signing paths in `backend/src/Controllers/auth.controller.js` and `google-auth.controller.js`. Sign in, wait for expiry, then refresh and sign in again. Do not change production JWT secrets or the phone clock to simulate expiry; restore normal staging token lifetime afterwards.

## Release checks

Run the focused suite above on every session change. Also run `flutter.bat analyze` and `flutter.bat test` before release. A focused pass does not establish that the entire app passes: the previous broader run found support and preview test failures, and analyzer warnings still need review.

These checks verify the recovery mechanism. They do not establish the original cause on the four devices without their request errors, or guarantee that every future connectivity failure is prevented.
