# Backend deployment on Vercel

Set the project's Root Directory to `backend` and select the Express framework
preset. No frontend build command or `dist` output directory is needed.

Add these variables under Vercel Project Settings > Environment Variables for
the environment being deployed. The frontend's local `.env` does not configure
the deployed backend.

- `DATABASE_URL`: a reachable MongoDB connection string, not localhost.
- `JWT_SECRET`: your private signing secret.
- `API_VERSION`: `v1`.
- `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET`: valid Razorpay credentials.
  The aliases `RAZORPAY_KEY` and `RAZORPAY_SECRET` are also supported.
- `RESEND_API_KEY`: your Resend key. Its client is created during app import.
- `NODE_ENV`: `production`.
- `API_BASE_URL`: `https://leads-qa6h.vercel.app` if this is the backend domain.
- `FRONTEND_URL` and `ADMIN_FRONTEND_URL`: the deployed frontend origins.

Google login also requires `USER_GOOGLE_CLIENT_ID`, `USER_GOOGLE_CLIENT_SECRET`,
and `USER_GOOGLE_CALLBACK_URL` on the backend. For this domain the callback is
`https://leads-qa6h.vercel.app/api/v1/auth/google/callback`. Register that redirect
URI in Google as well.

Ensure your MongoDB provider's network settings allow the deployment to connect.
Redeploy after changing environment variables or deploying the code changes.

Visit `/` to check for the welcome JSON. This confirms the app loads, not database
connectivity. Then check an API endpoint. Database failures now return 503 and
log their underlying error. For FUNCTION_INVOCATION_FAILED, inspect Vercel's
runtime Logs for the exception from the failed request. Never share secret values.

The local payment maintenance interval is not started on Vercel. Payment
reconciliation, reservation cleanup, and refund retries require a separate worker
or scheduled job; a function cannot rely on a persistent interval.
