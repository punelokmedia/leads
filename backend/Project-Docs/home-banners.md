# Server-controlled home banners

The app fetches `GET /api/v1/banners/home`. Images are served by the backend, never included in the Flutter asset bundle. The two supplied images are backend defaults in `public/home-banners/`.

Deploy the updated backend and release the updated app **once** to enable this feature. Subsequent image changes require **no app update** and, using the upload endpoint, **no backend redeployment**.

## Replace a banner

Use an existing administrator bearer token. The upload endpoint requires the same admin authentication and production MFA as other admin operations.

```powershell
# Set $bannerAdminToken to the existing administrator session token.
curl.exe --fail-with-body -X PUT "https://leads-qa6h.vercel.app/api/v1/banners/home/business" `
  -H "Authorization: Bearer $bannerAdminToken" `
  -F "image=@C:/Users/punel/Downloads/Grow Your Business with NextLead.png" `
  -F "title=Grow Your Business with NextLead" `
  -F "target=leads"

curl.exe --fail-with-body -X PUT "https://leads-qa6h.vercel.app/api/v1/banners/home/membership" `
  -H "Authorization: Bearer $bannerAdminToken" `
  -F "image=@C:/Users/punel/Downloads/NextLead Lifetime Membership at ₹499.webp" `
  -F "title=NextLead Lifetime Membership at ₹499" `
  -F "target=membership"
```

Use your deployment's backend URL if different. Supported formats: PNG, JPEG and WebP, up to 4 MB each. Keep approximately a 17:10 aspect ratio; the app contains the full image rather than cropping its text. These controls affect only the home hero, not category, project or other screen images.

Uploads persist in MongoDB, including on Vercel's read-only/ephemeral filesystem. The image's content hash changes its URL, bypassing old app image-cache entries. Metadata is not HTTP-cached. The app rechecks about once a minute while Home is active, on returning from the background after that interval, and on pull-to-refresh. Manual swipe and automatic rotation every four seconds are supported; automatic rotation pauses in the background and respects reduced-motion settings.

Verify a change by requesting `/api/v1/banners/home`: the changed banner receives a new `version` and `imageUrl`. The other banner remains unchanged. The banner API is read-only for guests; replacements require administrator authentication. Backend deployment must include `public/home-banners/` for the initial defaults.
