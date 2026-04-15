# 🧑‍💼 Admin API Documentation

This document covers all **Admin APIs** including authentication, dashboard analytics, and lead management.

---

# 🔐 Base URL

```http
http://localhost:5000/api/v1/admin
```

---

# 🔑 Authentication

Most APIs require **Admin JWT Token**

### Header:

```json
{
  "Authorization": "Bearer <admin_token>"
}
```

---

# 📊 APIs Overview

## 🔐 Admin Auth

| Method | Endpoint      | Description              |
| ------ | ------------- | ------------------------ |
| POST   | `/send-otp`   | Send OTP for admin login |
| POST   | `/verify-otp` | Verify OTP & login admin |

---

## 👨‍💼 Admin Management

| Method | Endpoint      | Description           |
| ------ | ------------- | --------------------- |
| POST   | `/make-admin` | Promote user to admin |

---

## 📊 Dashboard Analytics

| Method | Endpoint                    | Description            |
| ------ | --------------------------- | ---------------------- |
| GET    | `/dashboard/overview`       | Dashboard stats        |
| GET    | `/dashboard/revenue`        | Revenue analytics      |
| GET    | `/dashboard/top-categories` | Top selling categories |
| GET    | `/dashboard/recent-orders`  | Latest orders          |

---

## 📋 Admin Leads

| Method | Endpoint                   | Description                   |
| ------ | -------------------------- | ----------------------------- |
| GET    | `/dashboard/get-all-leads` | Get all leads (admin view)    |
| GET    | `/dashboard/get-leads/:id` | Get lead details (admin view) |

---

# 🔐 1. Send OTP (Admin Login)

### 📍 Endpoint:

```http
POST /send-otp
```

---

### 📥 Request Body:

```json
{
  "email": "admin@gmail.com"
}
```

---

### ✅ Success Response:

```json
{
  "success": true,
  "message": "OTP sent to admin email"
}
```

---

### ❌ Error:

```json
{
  "success": false,
  "message": "Access denied. Not an admin."
}
```

---

# 🔐 2. Verify OTP

### 📍 Endpoint:

```http
POST /verify-otp
```

---

### 📥 Request Body:

```json
{
  "email": "admin@gmail.com",
  "otp": "123456"
}
```

---

### ✅ Success Response:

```json
{
  "success": true,
  "message": "Admin login successful",
  "token": "jwt_token",
  "data": {
    "id": "admin123",
    "fullname": "Admin User",
    "email": "admin@gmail.com",
    "role": "ADMIN"
  }
}
```

---

### ❌ Error:

```json
{
  "success": false,
  "message": "Invalid OTP"
}
```

---

# 👨‍💼 3. Make Admin

### 📍 Endpoint:

```http
POST /make-admin
```

---

### 📥 Request Body:

```json
{
  "userId": "user123"
}
```

---

### 🔐 Access:

Admin only

---

### ✅ Success Response:

```json
{
  "success": true,
  "message": "User promoted to admin successfully",
  "user": {
    "id": "user123",
    "email": "user@gmail.com",
    "role": "ADMIN"
  }
}
```

---

# 📊 4. Dashboard Overview

### 📍 Endpoint:

```http
GET /dashboard/overview
```

---

### ✅ Response:

```json
{
  "success": true,
  "message": "Dashboard overview data fetched successfully.",
  "data": {
    "totalUsers": 1200,
    "totalLeads": 340,
    "activeLeads": 200,
    "soldLeads": 100,
    "expiredLeads": 40,
    "totalOrders": 180,
    "totalRevenue": 50000
  }
}
```

---

# 📈 5. Revenue Analytics

### 📍 Endpoint:

```http
GET /dashboard/revenue
```

---

### ✅ Response:

```json
{
  "success": true,
  "message": "Revenue analytics fetched successfully.",
  "data": [
    { "_id": { "month": 1, "year": 2026 }, "total": 12000 },
    { "_id": { "month": 2, "year": 2026 }, "total": 18000 }
  ]
}
```

---

# 🥇 6. Top Categories

### 📍 Endpoint:

```http
GET /dashboard/top-categories
```

---

### ✅ Response:

```json
{
  "success": true,
  "message": "Top performing categories fetched successfully.",
  "data": [
    { "_id": "Real Estate", "totalSold": 45 },
    { "_id": "Jobs", "totalSold": 30 }
  ]
}
```

---

# 🧾 7. Recent Orders

### 📍 Endpoint:

```http
GET /dashboard/recent-orders
```

---

### ✅ Response:

```json
{
  "success": true,
  "message": "Recent orders fetched successfully.",
  "data": [
    {
      "_id": "order123",
      "totalAmount": 1200,
      "status": "PAID"
    }
  ]
}
```

---

# 📋 8. Get All Leads (Admin)

### 📍 Endpoint:

```http
GET /dashboard/get-all-leads
```

---

### 🧠 Description:

Returns all leads with full data (including sensitive info)

---

### ✅ Response:

```json
{
  "success": true,
  "message": "Leads fetched successfully",
  "data": [
    {
      "_id": "lead123",
      "title": "Buyer for property",
      "phone": "9876543210",
      "customerName": "Rahul"
    }
  ]
}
```

---

# 📋 9. Get Lead By ID (Admin)

### 📍 Endpoint:

```http
GET /dashboard/get-leads/:id
```

---

### ✅ Response:

```json
{
  "success": true,
  "message": "Lead fetched successfully",
  "data": {
    "_id": "lead123",
    "title": "Buyer for property",
    "phone": "9876543210",
    "customerName": "Rahul",
    "address": "Pune"
  }
}
```

---

# ⚠️ Common Errors

### Unauthorized:

```json
{
  "success": false,
  "message": "Access denied. Admin only."
}
```

---

# 🧠 Notes

* Admin login is OTP-based (no password)
* Dashboard APIs are protected
* Admin can see full lead data
* Revenue is calculated from paid orders

---

# 🚀 Summary

* 🔐 Secure OTP-based admin login
* 📊 Full analytics dashboard
* 👨‍💼 Admin role management
* 📋 Full access to leads

---

# 💡 Future Enhancements

* Admin activity logs
* Role-based permissions (super admin, manager)
* Real-time dashboard updates
* Export analytics reports

---

