Loading browser checks
======================

Build the user app and run its Vite preview on `http://localhost:3000`.
Keep the backend running on the API URL configured in the frontend environment.

Start headless Chrome with remote debugging port `9223` and a **dedicated temporary profile**.
The checks clear local storage and close preview tabs in that profile; do not use your everyday browser profile.

From the repository root, run:

```
node frontend/apps/user-web/test/loading-browser.mjs desktop fast
node frontend/apps/user-web/test/loading-browser.mjs mobile 4g
node frontend/apps/user-web/test/loading-browser.mjs tablet fast
node frontend/apps/user-web/test/loading-browser.mjs mobile slow
node frontend/apps/user-web/test/home-reveal-browser.mjs
```

Devices: `desktop` (1440px), `tablet` (820px), `mobile` (390px).
Networks: `fast`, `4g` (150ms latency, 500 KB/s), `slow` (400ms latency, 100 KB/s).
Override `LOADING_TEST_URL` or `CHROME_DEBUG_URL` if needed.

The checks use Chrome DevTools Protocol without additional dependencies. They delay application and route bundles, verify the pre-JavaScript shell, image decoding, responsive sizing, layout shift, preserved navigation, reduced motion, image failures, API failure/retry, independent referral history, wallet loading, route bundle failures, and application entry failure recovery. Screenshots are written to `.tmp/loading-checks`.

Public category requests use the running backend. Signed-in API tests use intercepted fixture responses and a dummy token; they do not create users, change database records, or make purchases.

`home-reveal-browser.mjs` defaults to the development server on port 5174 and does not need the backend. It holds the hero request to check that the page skeleton stays visible, then verifies the homepage reveals without an image cover. It also checks the original-image fallback and retry after both image sources fail. Use `LOADING_TEST_URL` to run this check against the production preview.
