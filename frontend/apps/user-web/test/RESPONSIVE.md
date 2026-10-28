# Responsive browser checks

Build with `npm.cmd run build:user --prefix frontend`, then run the user-web
Vite preview on localhost:3000. Use a dedicated headless Chrome profile with
remote debugging on port 9223, as described in LOADING.md. These tests close
preview tabs and use dummy authentication; never use your everyday profile.

From the repository root:

```powershell
node frontend/apps/user-web/test/responsive-browser.mjs
```

The check visits 23 routes at 320, 360, 375, 390, 412, 430, 768, 1024, and
1440 pixels. API responses use intercepted fixtures, including populated carts,
lead history, wallet activity, and referral history. No backend records are
changed and no payments are submitted. This is layout and interaction coverage,
not an end-to-end authentication or payment test.

It checks visible content bounds (rather than relying on overflow hidden),
runtime errors, the narrow payment review, desktop navigation, and mobile drawer
focus containment, Escape, outside click, link selection, and scroll restoration.
Intentional carousel tracks and locally scrolling tables/tabs are excluded from
the page-bound check. Home screenshots include loaded lazy illustrations.
Results and screenshots are saved in `.tmp/responsive-checks`.

Run the separate loading checks in LOADING.md to exercise network throttling,
initial skeletons, route transitions, reduced motion, failed images, retries,
and failed API responses. `LOADING_TEST_URL` and `CHROME_DEBUG_URL` can override
the preview and debugging URLs in either suite.
