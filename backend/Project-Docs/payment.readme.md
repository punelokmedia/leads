# 💳 Payment API Documentation (Razorpay Integration)

This document explains how **payment flow works** in your system using Razorpay.

---

# 🔐 Base URL

```
http://localhost:3000/api/v1/payment
```

---

# 🔑 Authentication

All APIs require JWT token.

### Header:

```json
{
  "Authorization": "Bearer <your_token>"
}
```

---

# 📊 Payment Flow (Important)

```
User → Add to Cart
     → Create Order
     → Pay via Razorpay
     → Verify Payment
     → Unlock Leads
```

---

# 📌 APIs Overview

| Method | Endpoint            | Description                    |
| ------ | ------------------- | ------------------------------ |
| POST   | `/create`           | Create Razorpay order          |
| POST   | `/verify`           | Verify payment & unlock leads  |
| POST   | `/razorpay-webhook` | Razorpay webhook (auto verify) |

---

# 🧾 1. CREATE ORDER

### 📍 Endpoint:

```
POST /create
```

### 🔐 Access:

Authenticated User

---

### 📥 Request Body:

```json
{}
```

👉 No body required — it uses user's **cart**

---

### 🧠 What happens:

- Fetch user cart
- Calculate total price
- Create Razorpay order
- Store order in DB

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "ORDER_CREATED",
  "message": "Order created successfully",
  "data": {
    "razorpayOrderId": "order_ABC123",
    "internalOrderId": "65f1abc123",
    "amount": 1500,
    "currency": "INR",
    "leadsCount": 3
  }
}
```

---

### ❌ Error Response:

```json
{
  "success": false,
  "code": "CART_EMPTY",
  "message": "Your cart is empty. Please add leads before placing an order."
}
```

---

# 💰 2. VERIFY PAYMENT

### 📍 Endpoint:

```
POST /verify
```

---

### 📥 Request Body:

```json
{
  "razorpayOrderId": "order_ABC123",
  "razorpayPaymentId": "pay_ABC456",
  "razorpaySignature": "generated_signature"
}
```

---

### 🧠 What happens:

- Verify signature (security 🔐)
- Mark order as **PAID**
- Add user to lead buyers
- Unlock lead details
- Clear cart

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "PAYMENT_SUCCESS",
  "message": "Payment successful. Leads unlocked successfully.",
  "data": {
    "orderId": "65f1abc123",
    "paymentId": "pay_ABC456",
    "status": "PAID"
  }
}
```

---

### ❌ Invalid Signature:

```json
{
  "success": false,
  "code": "INVALID_SIGNATURE",
  "message": "Payment verification failed. Invalid signature."
}
```

---

# 🔔 3. RAZORPAY WEBHOOK (IMPORTANT)

### 📍 Endpoint:

```
POST /razorpay-webhook
```

---

### 🔐 Note:

- This should **NOT use auth middleware** ❗
- Called directly by Razorpay

---

### 🧠 What happens:

- Verifies webhook signature
- Confirms payment automatically
- Updates order
- Unlocks leads
- Clears cart

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "WEBHOOK_PROCESSED",
  "message": "Webhook processed successfully",
  "data": {
    "orderId": "65f1abc123",
    "paymentId": "pay_ABC456"
  }
}
```

---

# 🧠 Security Features

- ✅ Signature verification (prevents fraud)
- ✅ Idempotency (prevents duplicate payments)
- ✅ Cart cleared after payment
- ✅ Leads unlocked only after payment

---

# 🚀 Testing Flow (Postman)

### Step 1:

Login → get token

### Step 2:

Add leads to cart

### Step 3:

```
POST /create
```

### Step 4:

Use Razorpay test payment

### Step 5:

```
POST /verify
```

---

# 🧪 Razorpay Test Cards

| Card                | Result  |
| ------------------- | ------- |
| 4111 1111 1111 1111 | Success |
| 4000 0000 0000 0002 | Failure |

CVV: `123`
Expiry: Any future date

---

# 📦 Final Notes

- Payment is **mandatory before unlocking leads**
- Webhook ensures reliability even if frontend fails
- System is **secure & production-ready**

---

# 🎯 Summary

- 🛒 Cart → Order → Payment → Unlock
- 🔒 Fully secure
- ⚡ Scalable architecture
- 💰 Revenue-safe system

---
