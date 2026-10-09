# Production review

The user and admin frontend production builds pass. Local configuration uses the
production backend `https://leads-qa6h.vercel.app`, user frontend
`https://www.trynextlead.com`, and admin frontend
`https://leads-1-gwhj.onrender.com`.

Fixed missing lead reservation schema fields and enforced the two-buyer limit.
Password reset now requires the correct, unexpired OTP in the final request;
the user frontend sends it. Password reset OTPs are no longer logged.
Admin login now rejects missing OTPs and missing expiry dates. User JSON and
profile responses exclude passwords, OTPs and payment signatures.

Before accepting production users:

- Configure the backend environment variables in hosting. Local `.env` files
  are ignored by Git and pushing code does not upload these settings.
- Set `NODE_ENV=production`, the MongoDB connection string, JWT secret,
  Razorpay credentials, Resend credentials and verified sender, Google user
  credentials and callback URL, and both frontend origins. See `backend/VERCEL.md`.
- In each frontend hosting project, set
  `VITE_API_BASE_URL=https://leads-qa6h.vercel.app` and rebuild.
- Register `https://leads-qa6h.vercel.app/api/v1/auth/google/callback` with the
  corresponding Google OAuth client. The active strategy uses `USER_GOOGLE_*`;
  changing `ADMIN_GOOGLE_CALLBACK_URL` does not create an admin Google login.
- Configure Razorpay's `payment.captured` webhook at
  `https://leads-qa6h.vercel.app/api/v1/payments/razorpay-webhook` and set the
  matching `RAZORPAY_WEBHOOK_SECRET`, which is absent from the local `.env`.
- Provide a separate persistent worker or scheduled job for payment maintenance
  on Vercel. The interval is deliberately disabled there; reconciliation and
  refund retries otherwise do not run automatically.
- Verify database connectivity, sender domain verification and email delivery,
  Google login, membership checkout, lead purchase, and refund behavior against
  the deployed application. These external services were not verified locally.
- Add durable request and OTP attempt limits before exposing authentication to
  unrestricted public traffic. No such limits were found in the reviewed routes.
- Implement SMS delivery before enabling phone registration and phone verification.
  These routes previously generated codes without sending them. Production now
  returns `503 SMS_NOT_CONFIGURED`; Twilio environment variables alone do not
  implement delivery. Google onboarding that requires phone verification is
  affected too.

Validation rerun on October 3, 2026: all 50 backend tests pass, both web
production builds pass, and both web lint commands pass. The admin Fast Refresh
export error was fixed by moving the toast context and hook into `useToast.ts`.
The user frontend still has five hook dependency warnings, and its production
build reports a JavaScript bundle size warning.
Read-only requests to the deployed URLs failed with connection errors from this
execution environment. No conclusion about deployed availability can be drawn
from those failures; live service verification remains outstanding.

This review covered backend and web frontend configuration, authentication,
checkout, existing backend tests, builds and lint. It is not a full security
audit or mobile release review.
