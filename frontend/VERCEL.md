# Deploying the frontends

Create separate Vercel projects for the user website and admin website:

| Setting | User website | Admin website |
| --- | --- | --- |
| Root Directory | `frontend/apps/user-web` | `frontend/apps/admin-web` |
| Framework | Vite | Vite |
| Build Command | `npm run build` | `npm run build` |
| Output Directory | `dist` | `dist` |

In **each frontend project's** Environment Variables, set:

```env
VITE_API_BASE_URL=https://leads-qa6h.vercel.app
```

Use the backend origin only, without `/api/v1`. Select the environments you
deploy to. Vite embeds this setting during the build, so redeploy both frontends
after changing it. Setting the variable only in the backend project has no effect
on either frontend.

Production defaults to this backend when the variable is absent. Local development
defaults to `http://localhost:5000`. An explicit environment value overrides the
default, so remove any production value pointing to localhost.

The per-app `vercel.json` files serve the SPA for browser routes such as `/login`.
Keep the Root Directory settings above so Vercel reads the appropriate file.

In the **backend project's** Environment Variables, set `FRONTEND_URL` to the
deployed user origin and `ADMIN_FRONTEND_URL` to the deployed admin origin. Use
origins without paths. Redeploy the backend after changing these CORS settings.

Verify in the browser Network tab that login requests go to
`https://leads-qa6h.vercel.app/api/v1/admin/send-otp`, rather than localhost.
The backend welcome JSON confirms the app loads; it does not verify MongoDB or
the email credentials needed to send OTPs.
