# Web Auth API Endpoints (Single Reference)

Base URL: `http://localhost:5000/api/v1/auth`

## 1) Request Mobile OTP

- **Method:** `POST`
- **Endpoint:** `/mobile/request-otp`
- **Purpose:** New/existing user ke mobile par OTP bhejna.

Request body:
```json
{
  "phoneNumber": "9876543210"
}
```

Success response:
```json
{
  "success": true,
  "code": "OTP_SENT",
  "message": "OTP sent successfully.",
  "data": {
    "phoneNumber": "9876543210",
    "otp": "123456"
  }
}
```

> Note: `otp` sirf non-production mode me debugging ke liye aata hai.

---

## 2) Verify Mobile OTP (Login/Signup)

- **Method:** `POST`
- **Endpoint:** `/mobile/verify-otp`
- **Purpose:** OTP verify karke token return karta hai. Existing user login hota hai, new user ka lightweight signup bhi ho jata hai.

Request body:
```json
{
  "phoneNumber": "9876543210",
  "otp": "123456"
}
```

Success response:
```json
{
  "success": true,
  "code": "LOGIN_SUCCESS",
  "message": "Mobile login successful.",
  "token": "jwt-token",
  "data": {
    "_id": "user_id",
    "firstname": "New",
    "lastname": "User",
    "phoneNumber": "9876543210",
    "businessName": "",
    "workType": "",
    "email": "9876543210.1714287891000@mobile.nextleads.local"
  },
  "meta": {
    "isNewUser": true,
    "needsProfile": true
  }
}
```

---

## 3) Complete Profile (Legacy / Optional)

- **Method:** `POST`
- **Endpoint:** `/mobile/complete-profile`
- **Auth:** `Bearer <token>`
- **Purpose:** OTP login ke baad onboarding details save karna (without payment verification).

Request body:
```json
{
  "fullName": "Rohit Sharma",
  "email": "rohit@example.com",
  "city": "Bangalore",
  "businessName": "Sharma Interior Works",
  "workType": "Interior Designer"
}
```

Success response:
```json
{
  "success": true,
  "code": "PROFILE_COMPLETED",
  "message": "Profile completed successfully.",
  "data": {
    "_id": "user_id",
    "firstname": "Rohit",
    "lastname": "Sharma",
    "email": "rohit@example.com",
    "city": "Bangalore",
    "businessName": "Sharma Interior Works",
    "workType": "Interior Designer"
  }
}
```

---

## 4) Create Registration Payment Order (Signup Flow)

- **Method:** `POST`
- **Endpoint:** `/mobile/create-registration-order`
- **Auth:** `Bearer <token>`
- **Purpose:** Razorpay order create karna for one-time registration fee.

Success response:
```json
{
  "success": true,
  "code": "ORDER_CREATED",
  "message": "Registration order created successfully.",
  "data": {
    "orderId": "order_Pabc123",
    "amount": 49900,
    "currency": "INR",
    "keyId": "rzp_test_xxx"
  }
}
```

---

## 5) Verify Registration Payment + Complete Signup

- **Method:** `POST`
- **Endpoint:** `/mobile/verify-registration-payment`
- **Auth:** `Bearer <token>`
- **Purpose:** Razorpay payment verify karke profile complete karta hai aur `registrationFeePaid=true` set karta hai.
- **Important:** Payment success ke baad user role `USER` rehta hai (admin nahi banta).
- **One-time rule:** Ek user se registration fee sirf 1 baar li ja sakti hai.

Request body:
```json
{
  "razorpayOrderId": "order_Pabc123",
  "razorpayPaymentId": "pay_Pxyz456",
  "razorpaySignature": "generated_signature",
  "fullName": "Rohit Sharma",
  "email": "rohit@example.com",
  "city": "Bangalore",
  "businessName": "Sharma Interior Works",
  "workType": "Interior Designer"
}
```

Success response:
```json
{
  "success": true,
  "code": "REGISTRATION_PAYMENT_SUCCESS",
  "message": "Payment successful. Registration completed.",
  "data": {
    "_id": "user_id",
    "firstname": "Rohit",
    "lastname": "Sharma",
    "role": "USER",
    "registrationFeePaid": true
  }
}
```

---

## 6) Common Error Codes (Signup Payment Flow)

- `RAZORPAY_NOT_CONFIGURED` → Razorpay keys server par missing.
- `ORDER_CREATE_FAILED` → Razorpay order create failed.
- `INVALID_PAYMENT_SIGNATURE` → Payment signature verify nahi hui.
- `REGISTRATION_FEE_ALREADY_PAID` → User already paid (repeat payment blocked).
- `EMAIL_ALREADY_IN_USE` → Email kisi aur account me already use ho rahi hai.

---

## 7) Other APIs Added/Updated Today (Single List)

### City APIs
Base URL: `http://localhost:5000/api/v1/cities`

- `GET /get-all-cities`
- `POST /add-city` (Auth + Admin)
- `PUT /update-city` (Auth + Admin)
- `DELETE /delete-city` (Auth + Admin)

### Lead APIs (fields updated)
Base URL: `http://localhost:5000/api/v1/leads`

- `POST /create-lead`
- `PUT /update-lead/:id`
- `DELETE /delete-lead`
- `POST /upload-leads`
- `GET /upload-status/:id`

Lead payload me aaj add/updated fields:
- `customerName`
- `clientType` (`Individual` / `Business` / `Any`)
- `primaryPhone`
- `alternatePhone` (optional)
- `email` (optional)
- `city`
- `areaLocality`
- `requirement`
- `propertyType` (free text: e.g. `2BHK`, `10 CCTV`, `N/A`)
- `areaSize` (optional)
- `budgetRange`
- `timeline`

---

## 8) Google Login First-Time Payment Rule

- `GET /google` + `GET /google/callback` login ke baad user payload me `registrationFeePaid` aata hai.
- Agar `registrationFeePaid = false` ho, to frontend user ko onboarding flow (`/auth/mobile?flow=google`) par redirect karega.
- Is onboarding me pehle mobile number + OTP verification mandatory hai.
- First-time Google login user ke liye bhi registration fee mandatory hai.
- Payment successful hone ke baad hi registration complete maana jayega.

---

## 9) Session OTP APIs for Google Onboarding

- **Method:** `POST`
- **Endpoint:** `/mobile/request-otp-session`
- **Auth:** `Bearer <token>`
- **Purpose:** Logged-in (Google) user ke current session par mobile OTP bhejna.

Request body:
```json
{
  "phoneNumber": "9876543210"
}
```

---

- **Method:** `POST`
- **Endpoint:** `/mobile/verify-otp-session`
- **Auth:** `Bearer <token>`
- **Purpose:** Session OTP verify karke current Google user account par phone number link/verify karna.

Request body:
```json
{
  "phoneNumber": "9876543210",
  "otp": "123456"
}
```

Success response:
```json
{
  "success": true,
  "code": "PHONE_VERIFIED",
  "message": "Phone verified successfully.",
  "data": {
    "phoneNumber": "9876543210"
  }
}
```

---

## Existing Auth Endpoints (Already Available)

- `POST /register`
- `POST /login`
- `GET /profile`
- `GET /logout`
- `PUT /update-profile`
- `POST /change-password`
- `POST /add-address`
- `POST /forgot-password`
- `POST /verify-otp`
- `POST /reset-password`
- `GET /google`
- `GET /google/callback`

