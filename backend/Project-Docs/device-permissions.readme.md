0# Mobile location and files

All endpoints below require the existing user authentication token.

`PUT /api/v1/auth/mobile/permissions` accepts JSON such as:

```json
{"location":"granted","files":"limited","latitude":18.5204,"longitude":73.8567}
```

Permission states are `granted`, `denied`, `not_requested`; files also supports `limited`. These report device permission state, not OS authorization. Coordinates require explicit `location: "granted"` in the same request. Refresh coordinates when the user chooses to use their current location. Denying or resetting location clears saved coordinates. Read saved state through `GET /api/v1/auth/profile`.

`GET /api/v1/leads/get-all-leads?nearby=true&radiusKm=25` filters leads within the saved location's radius (default 25 km, maximum 200 km), retaining existing pagination, sorting and category filters. This requires granted location consent and saved coordinates. Existing city/state filtering remains available without location permission. Leads without coordinates cannot match nearby searches. Admin create/update lead requests accept optional `latitude` and `longitude` together. Spreadsheet imports currently do not populate coordinates; add them using the update endpoint. Exact lead coordinates are hidden from public listing and unpurchased details.

`PUT /api/v1/auth/profile-picture` accepts multipart form data with a single `profilePic` JPEG, PNG or WebP, maximum 2 MB. It updates only the picture. Existing mobile profile completion also supports picture uploads.

`GET /api/v1/leads/download/:orderId` already returns an Excel attachment for the authenticated owner's paid leads, subject to the existing download rules. Content-Disposition is exposed to browser clients so they can read the filename.

The mobile client must implement native permission requests and send the resulting state. Use a system photo/file picker for pictures and the platform save/share flow for Excel files; do not treat the backend's files state as authorization to access phone storage. Handle refusal and allow users to continue with city/state selection. No mobile permission dialogs or native integration are added by these backend changes.
