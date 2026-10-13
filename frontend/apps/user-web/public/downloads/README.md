# Android download

Place the approved Android APK here as `nextleads.apk` to enable the `/download` page's buttons. No backend endpoint is required for a static APK.

Alternatively set `VITE_ANDROID_APK_URL` at build time to the hosted APK URL. External hosts must allow HEAD requests with CORS and return an APK or binary Content-Type. For cross-origin downloads, serve Content-Disposition: attachment; filename="nextleads.apk".

Until an APK is supplied, the page displays an unavailable message and does not download the SPA fallback HTML. This directory intentionally contains no placeholder APK.
