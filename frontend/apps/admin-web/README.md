# Admin web

## Production admin login returning 401

Production requires a valid database-stored admin password as well as the email
OTP. Development permits OTP-only login. Setting ADMIN_PASSWORD in an env file
alone does not update an existing account password.

For an existing ADMIN account without a password, run `npm run seed:admin` from
the backend using the intended production DATABASE_URL, ADMIN_EMAIL and
ADMIN_PASSWORD in that command's environment. This initializes only a missing
password, clears old OTPs and revokes prior sessions. Existing passwords are
preserved. Request a new OTP afterward and enter the initialized password.
If the account already has a password, use that password or the existing reset
workflow. Local `.env` changes do not update Vercel environment variables; the
seed command must target the same database as the deployed backend. Redeploy
the admin frontend to receive the required production password field.

If the existing admin password must be replaced, explicitly run
`npm.cmd run seed:admin -- --reset-password` from the backend with the verified
production database and intended ADMIN_EMAIL / ADMIN_PASSWORD configured.
This replaces the existing ADMIN account password, revokes sessions and clears
old OTPs. Request a new OTP and enter ADMIN_PASSWORD afterward. The default
seed command never overwrites an existing password.

## Notification monitoring

Sign in as an admin and select **Notifications** in the sidebar or mobile navigation.
The page is available at `/notifications` and uses the authenticated backend APIs
under `/api/v1/notifications/admin`.

Summary counts and counts by type reflect the applied recipient ID, type, read
status and creation date filters. History is paginated with 30 records per page.
Select **Inspect** to view the recipient, event ID, mobile/web receipt timestamps,
read time, current preferences and registered device metadata. Use **Refresh**
to load the latest changes; this page does not refresh automatically.

Use **Send notification** to search users by name, email or user ID, select up
to 100 recipients and enter an announcement title and message. Selected users
remain selected across search pages. Successful sends refresh monitoring data.
Retries of the same failed send reuse the client ID to prevent duplicate inbox
items. Blocked accounts and users who disabled announcements are skipped.
Sending requires the existing ADMIN role (and MFA in production); no new env
variable or change to account permissions is required.

Saved inbox records and confirmed client receipts are shown separately. Until
the user app and portal call the receipt API, receipt status remains awaiting
confirmation. Firebase push delivery is not configured in this phase. Deploy
the matching backend routes and run `node scripts/init-notifications.js` from
the backend before deploying the admin changes. No sample data is shown on API
failure; the page displays an error and allows retrying.

## Render deployment

Set `VITE_API_BASE_URL` on the admin Render service to the backend HTTPS origin
(for example, `https://your-backend.onrender.com`, without `/api/v1`). Vite reads
this value at build time, so rebuild the admin after changing it.

On the backend Render service, set `ADMIN_FRONTEND_URL` to the admin HTTPS origin
and keep `FRONTEND_URL` pointing to the user website. Redeploy the backend after
changing these values. The admin uses email OTP at `/api/v1/admin/send-otp` and
`/api/v1/admin/verify-otp`; the backend must have `API_VERSION=v1`.

Use the shared frontend workspace lockfile:

- Root directory: `frontend`
- Build command: `npm ci --include=dev --include=optional && npm run build:admin`
- Publish directory: `apps/admin-web/dist`

After deploying a repaired lockfile, select **Manual Deploy → Clear build cache & deploy**.

The lockfile must include native optional dependencies for both local development
and Linux builds, including Rolldown, Tailwind Oxide, and Lightning CSS. A lockfile
containing only Windows binaries can build locally but fail on Render with
`Cannot find module '@rolldown/binding-linux-x64-gnu'`. Commit the shared
`frontend/package-lock.json` and use `npm ci` for deployment to keep it unchanged.

## Vite template notes

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend updating the configuration to enable type-aware lint rules:

```js
export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...

      // Remove tseslint.configs.recommended and replace with this
      tseslint.configs.recommendedTypeChecked,
      // Alternatively, use this for stricter rules
      tseslint.configs.strictTypeChecked,
      // Optionally, add this for stylistic rules
      tseslint.configs.stylisticTypeChecked,

      // Other configs...
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```

You can also install [eslint-plugin-react-x](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-x) and [eslint-plugin-react-dom](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-dom) for React-specific lint rules:

```js
// eslint.config.js
import reactX from 'eslint-plugin-react-x'
import reactDom from 'eslint-plugin-react-dom'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...
      // Enable lint rules for React
      reactX.configs['recommended-typescript'],
      // Enable lint rules for React DOM
      reactDom.configs.recommended,
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```
