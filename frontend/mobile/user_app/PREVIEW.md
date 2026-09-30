# NextLeads mockup preview

Run from `frontend/mobile/user_app`:

```powershell
flutter run -t lib/main_preview.dart
```

For a browser preview:

```powershell
flutter run -d chrome -t lib/main_preview.dart
```

The normal entry point also supports `flutter run --dart-define=TEST_MODE=true`.
The dedicated preview entry point requires no backend, login, environment file or payment keys.
Every screen has a yellow TEST MODE banner. Data and edits are in memory only.
Normal app startup now uses this design with backend data after the existing splash/login flow.

## Backend-connected app

Run `flutter run` from this directory. The app reads `BASE_URL` from `.env.local`.
To select another backend without editing the environment file:

```powershell
flutter run --dart-define=BASE_URL=http://10.0.2.2:5000/
```

`10.0.2.2` reaches the host from an Android emulator. A physical phone needs the
host's LAN address. `--dart-define=ENV=dev` selects `.env.dev` instead.
For browser browsing, use an origin allowed by the backend, for example
`flutter run -d chrome --web-port=5173`; real checkout uses the existing native Razorpay flow.

Live mode loads categories, cities, all lead pages, account details and paid lead
receipts. Profile Save waits for the API response. Prices, purchase state and
vendor limits come from the server. Accept Lead opens the existing cart checkout;
contacts are available only after the backend confirms a paid order.

Checkout now allows two distinct buyers per lead, with one slot per buyer.
Slots are reserved for up to 10 minutes before payment opens. A third checkout
is blocked while both slots are held; after two purchases the lead is out of
stock. Late captured payments are queued for a refund and do not unlock contacts.
See `backend/Project-Docs/two-buyer-checkout.md` at the repository root for
deployment requirements and the pending concurrency-test validation.

Deploy the accompanying backend changes before relying on profile editing and
purchased contacts: public lead routes now support authenticated requests,
ownership is checked against paid orders, and profile updates accept the displayed
business/location fields. Existing vendor limits and prices are preserved.

Saved leads are session-only. Notifications have no backend feed. Both support
buttons open the authenticated database-backed support inbox; live mode never sends simulated replies.
API failures show Retry instead of sample data. More includes Refresh and account access.

Checks:

```powershell
flutter test test/preview_test.dart test/live_store_test.dart test/home_filters_test.dart
# From backend:
node --test test/lead-access.test.js
```

## Review checklist

- Home feature prompt: tap to open the featured lead details, swipe left/right or use the close button to dismiss. Home remains visible and interactive beneath it. Dismissal lasts for the preview session; Reset test data shows it again.

- Compact header: small logo on the left, profile shortcut and notification bell on the right.
- Profile: open the bottom Profile tab or top profile icon, then Edit personal details. Edit name, email, phone, business, service category, city and state. Save updates the sample profile; Cancel discards edits. Restart or Reset test data restores defaults.

- Home: premium leads button, city/category filters, category grid, budget cards, trust strip, notification bell, support bar and five navigation tabs.
- All Categories: switch between the pricing table and category list with available lead counts. Tap a category to filter leads.
- Leads: search, city/category filters, saved-only filter, and All/New/Joined/Closed tabs. Combine filters to check the empty state.
- Details: project budget and access fee are separate; inspect project type, client type, property type, area, timeline and preferred starting date.
- Save a lead using the heart. Open Profile → Saved leads to find it.
- Share opens a sample summary with Copy summary. It does not send anything externally.
- Accept Lead & View Contact: try Cancel, Simulate failure, and Simulate success. Only success changes the vendor count, unlocks sample contact, adds a receipt and notification. A joined or full lead cannot be bought again.
- Painting starts closed at 2/2; Plumbing starts joined; Interior Design starts at 1/2. Other categories include empty slots.
- Payments: tap a receipt to inspect it. All payments are simulated.
- Support: choose a topic or send text to receive an explicitly simulated response.
- More → Reset test data restores the initial fixtures, favourites, messages, receipts and filters.

The first 12 category ranges follow the mocks; additional categories use sample ranges.
Coverage and verification text is design copy, not verification of business claims.
In TEST_MODE, contact details are placeholders and changes stay in memory.
Run without TEST_MODE to use the backend integration described above.

Validation: `flutter test test/preview_test.dart`

## System theme and Android test display

The live app and preview follow the phone's light/dark setting automatically.
Check switching while the app is open with
`flutter test test/system_theme_test.dart`.

Android debug builds use a TextureView to avoid the blank SurfaceView observed
on the development emulator. Release builds retain Flutter's SurfaceView.
After native Android changes, stop and rebuild instead of hot reload:

```powershell
flutter run -d emulator-5554 -t lib/main_preview.dart
```

This entry point uses sample data. Use `flutter run` for the backend-connected app.

## Live category catalog and support

All 17 preview categories are imported into the configured database and verified
through https://leads-e5jv.onrender.com (20 categories including existing entries).
Sample leads and payment records remain in demo mode. Categories with no active
leads still appear in the category list.

Both 24/7 Support and Chat with Support use the live support inbox. Sign in to
send messages. Admins reply from Support Inbox in admin web. Deploy the backend
support routes and admin web before using live chat. Requests can be submitted
24/7; the app does not claim immediate human responses.

Build the live APK:

```powershell
flutter build apk --release --build-number=2 --dart-define=BASE_URL=https://leads-e5jv.onrender.com/
```
