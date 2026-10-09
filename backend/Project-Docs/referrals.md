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
code to `/validate`. Frontend routing and app deep links can carry this code;
this API does not implement a landing page, attribution, rewards or wallet credit.
Do not treat validation alone as an applied referral.

Before deploying with MongoDB automatic index creation disabled, create the index:

```javascript
db.users.createIndex(
  { referralCode: 1 },
  { unique: true, partialFilterExpression: { referralCode: { $type: "string" } } }
)
```
