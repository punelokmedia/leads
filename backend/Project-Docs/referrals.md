# Shared referral code API

Every newly created User receives a permanent `referralCode`, including local,
Google and mobile OTP accounts. Codes consist of `NL` plus the complete uppercase
MongoDB account ID (26 characters total). They are public identifiers, not secrets
or authentication tokens. A unique partial index enforces uniqueness while
allowing legacy accounts without a code. The `/me` endpoint initializes legacy
accounts atomically; concurrent requests return the same persisted code.

Base path: `/api/v1/referrals` (version follows `API_VERSION`). Both routes accept
the existing Bearer token authentication for mobile and token cookie for web.

## Retrieve your code

`GET /api/v1/referrals/me`

```json
{"success":true,"data":{"referralCode":"NL0123456789ABCDEF01234567"}}
```

## Validate another user's code

`POST /api/v1/referrals/validate`

```json
{"referralCode":"NL0123456789ABCDEF01234567"}
```

Successful response:

```json
{"success":true,"data":{"referralCode":"NL0123456789ABCDEF01234567","valid":true}}
```

Whitespace and lowercase input are normalized. Malformed input and self-referrals
return 400; unknown codes and blocked/non-user owners return 404. Authentication
is required. No owner identity is returned.

Web and Flutter should retrieve `/me` for the share/copy UI, then submit the same
code to `/validate`. Frontend routing and app deep links can carry this code.
Do not treat validation alone as an applied referral.

## Apply a referral

After authenticating, call `POST /api/v1/referrals/apply` with
`{"referralCode":"NL0123456789ABCDEF01234567"}` before the first paid lead
purchase. This shared endpoint supports local, Google and OTP accounts without
modifying their login flows. Accounts with existing paid lead orders are ineligible.
Retrying the same code is safe; switching referrers returns 409. Self-referrals,
blocked referrers and admin referrers are rejected.

`GET /api/v1/referrals/me` also returns `invited`, `qualified`, `pending` and
`appliedReferral`. `GET /api/v1/referrals/history?page=1&limit=20` returns the
current referrer's activity, with no referred-user contact details (maximum 50 rows).

The first successfully fulfilled captured lead payment transitions a referral
from `PENDING` to `QUALIFIED` inside the checkout transaction. Failed payments,
membership payments and refund-pending checkouts do not qualify. Duplicate
callbacks cannot qualify a referral twice. Qualification records a completed
purchase, not spendable credit. Wallet credits, withdrawals, refund reversals,
automatic signup attribution and a share-link landing page are not implemented.
Keep the frontend reward offer labelled as a preview until wallet issuance exists.

## Frontend connections

`/me` returns `referralLink`, for example
`https://www.trynextlead.com/auth/mobile?ref=NL0123456789ABCDEF01234567`.
Set `REFERRAL_WEB_URL` to override the web origin for local testing.
The web login page pre-fills the code and preserves it in session storage through
OTP and Google redirects until it is applied during profile completion.
Links carry an invitation, not an authentication token; the recipient signs in.
`APP_DOWNLOAD_URL` may contain the published app-store URL. Until publication,
the UI shows a coming-soon preview, not a functioning store link. These links
open the web portal; app deep links and install attribution are not implemented.

Flutter applies entered codes during category/profile setup using its authenticated
Dio client. Its live Profile and More screens load `/referrals/me` to display the
real code and counts. Preview mode retains sample data.

User web applies entered codes during profile completion. Its signed-in account
history panel displays the invitation code and counts from `/referrals/me`, using
the same Bearer token as checkout. Empty code fields skip applying a referral;
API errors keep the user on setup so they can correct or remove their entry.

Local frontends and backend must use the same API host and MongoDB database.
Restart frontend and backend processes after changing environment URLs.
For production, deploy the backend referral routes and frontend builds together;
installed Flutter apps need a rebuilt release to receive the new UI.

MongoDB must support transactions (replica set or Atlas). With automatic indexes
disabled, also create the unique attribution index before enabling this feature:

```javascript
db.referrals.createIndex({ referredUser: 1 }, { unique: true })
db.referrals.createIndex({ referrer: 1 })
```

Before deploying with MongoDB automatic index creation disabled, create the index:

```javascript
db.users.createIndex(
  { referralCode: 1 },
  { unique: true, partialFilterExpression: { referralCode: { $type: "string" } } }
)
```
