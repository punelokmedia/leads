# 🔐 Auth API Documentation

---

# 🌐 Base URL

```http
http://localhost:3000/api/v1/auth
```

---

# 🔑 Authentication

Protected APIs require JWT token.

```json
{
  "Authorization": "Bearer <your_token>"
}
```

---

# 📊 APIs Overview

| Method | Endpoint           | Description                              | Access |
|--------|--------------------|------------------------------------------|--------|
| POST   | `/register`        | Register a new user account              | Public |
| POST   | `/login`           | Authenticate user and return JWT token   | Public |
| GET    | `/google`          | Redirect to Google OAuth login           | Public |
| GET    | `/google/callback` | Handle Google OAuth callback             | Public |
| GET    | `/profile`         | Get logged-in user profile details       | User   |
| PUT    | `/update-profile`  | Update user profile information          | User   |
| GET    | `/logout`          | Logout user (invalidate session/token)   | User   |
| POST   | `/change-password` | Change user password                     | User   |
| POST   | `/add-address`     | Add or update user address               | User   |
| POST   | `/forgot-password` | Send OTP to user email for reset         | Public |
| POST   | `/verify-otp`      | Verify OTP before password reset         | Public |
| POST   | `/reset-password`  | Reset password after OTP verification    | Public |

---

# 📌 1. Register User

### Endpoint

```http
POST /register
```

### Request

```json
{
  "firstname": "Swapnil",
  "lastname": "Sutar",
  "email": "swapnil@gmail.com",
  "phoneNumber": "9876543210",
  "password": "123456"
}
```

### Success Response

```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "_id": "user_id",
    "email": "swapnil@gmail.com"
  }
}
```

### Error

```json
{
  "success": false,
  "message": "User already exists"
}
```

---

# 📌 2. Login User

### Endpoint

```http
POST /login
```

### Request

```json
{
  "email": "swapnil@gmail.com",
  "password": "123456"
}
```

### Success Response

```json
{
  "success": true,
  "token": "jwt_token",
  "data": {
    "_id": "user_id",
    "email": "swapnil@gmail.com"
  }
}
```

### Error

```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

# 📌 3. Get Profile

### Endpoint

```http
GET /profile
```

### Headers

```json
{
  "Authorization": "Bearer token"
}
```

### Success Response

```json
{
  "success": true,
  "data": {
    "_id": "user_id",
    "firstname": "Swapnil",
    "email": "swapnil@gmail.com"
  }
}
```

---

# 📌 4. Update Profile

### Endpoint

```http
PUT /update-profile
```

### Headers

```json
{
  "Authorization": "Bearer token"
}
```

### Request

```json
{
  "firstname": "Swapnil",
  "lastname": "Sutar"
}
```

### Success Response

```json
{
  "success": true,
  "message": "Profile updated successfully"
}
```

---

# 📌 5. Logout

### Endpoint

```http
GET /logout
```

### Success Response

```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

# 📌 6. Google Login

### Endpoint

```http
GET /google
```

👉 Redirects to Google

---

# 📌 7. Google Callback

### Endpoint

```http
GET /google/callback
```

### Success Response

```json
{
  "success": true,
  "token": "jwt_token"
}
```

---

# 📌 8. Change Password

### Endpoint

```http
POST /change-password
```

### Headers

```json
{
  "Authorization": "Bearer token"
}
```

### Request

```json
{
  "oldPassword": "123456",
  "newPassword": "new123",
  "confirmPassword": "new123"
}
```

### Success Response

```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

# 📌 9. Add Address

### Endpoint

```http
POST /add-address
```

### Headers

```json
{
  "Authorization": "Bearer token"
}
```

### Request

```json
{
  "address": "Baner, Pune"
}
```

### Success Response

```json
{
  "success": true,
  "message": "Address added successfully"
}
```

---

# 📌 10. Forgot Password

### Endpoint

```http
POST /forgot-password
```

### Request

```json
{
  "email": "swapnil@gmail.com"
}
```

### Response

```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

---

# 📌 11. Verify OTP

### Endpoint

```http
POST /verify-otp
```

### Request

```json
{
  "email": "swapnil@gmail.com",
  "otp": "1234"
}
```

### Response

```json
{
  "success": true,
  "message": "OTP verified successfully"
}
```

---

# 📌 12. Reset Password

### Endpoint

```http
POST /reset-password
```

### Request

```json
{
  "email": "swapnil@gmail.com",
  "newPassword": "new123",
  "confirmPassword": "new123"
}
```

### Response

```json
{
  "success": true,
  "message": "Password reset successful"
}
```

---

# ⚠️ Common Errors

```json
{
  "success": false,
  "message": "All fields are required"
}
```

---

# 🚀 Summary

* JWT-based authentication
* Google + Email login
* OTP-based password reset
* Secure password handling
* User profile management

---
