# Play release 1.0.1+12

Build from this directory with `flutter build appbundle --release`.
Output: `build/app/outputs/bundle/release/app-release.aab`.

This release uses the public production API, preserves login during transient
network/server failures, routes rejected sessions to sign-in, and offers profile
retry. Profile providers now share one state, reload on login-state changes, and
ignore responses after disposal. The profile header respects dark mode and the
business-details row accommodates narrow layouts.

The build-7 screenshots only show a generic profile failure. They do not establish
whether its request timed out, its session expired, or its backend failed. This
release improves recovery; it cannot guarantee that networks and servers never
fail. Users must install the update to receive these client changes.

## Signing

- Direct APK: existing local debug key, `C0:B3:4C:94:20:2B:95:E9:7E:39:9B:02:A3:62:92:7A:0A:6C:FA:31`.
- Play bundle upload: configured upload keystore, `4F:E0:F8:B5:EC:A4:66:77:0E:4E:3C:61:39:A3:8B:42:88:FA:9A:ED`.
- Supplied Google deployment certificate: `8C:81:75:00:98:18:33:52:C9:AD:B5:DB:8D:D1:36:00:86:65:69:E0`.

The upload key does not need a Google OAuth registration when Google re-signs
the distributed APK. Play Console must accept that upload key. The distributed
APK's signing certificate must match an Android OAuth client in the same project
as the mobile Web client ID. A public DER certificate cannot sign local builds.

## Checks and rollout

- Full Flutter suite: 38 tests passed, including profile timeout/retry and expired-session recovery.
- Changed profile/test files: analyzer reports no issues.
- Whole-project analyzer still reports existing warnings and lint notices; it is not a clean analyzer pass.
- Google Cloud registrations are based on supplied screenshots; no direct console access was available.

Upload to internal testing first. On a device running Play-installed build 7,
update through Google Play without uninstalling. Confirm existing profile access,
Google sign-in, force-stop/reopen, and offline/retry recovery. An expired session
may require signing in again. A device running the directly installed debug-key
APK cannot update in place to a differently signed Play APK.

The AAB has not been uploaded or tested through Google Play by this agent. Confirm
version code 12 has not already been used in Play Console before submitting it.
