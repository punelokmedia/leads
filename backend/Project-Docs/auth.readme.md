# 🔐 Auth API Documentation

This document covers all **Authentication & User Account APIs** including register, login, Google auth, and password management.

---

# 🔐 Base URL

```http
http://localhost:3000/api/v1/auth
```

---

# 🔑 Authentication

Some APIs require JWT token.

### Header:

```json
{
  "Authorization": "Bearer <your_token>"
}
```

---

# 📊 APIs Overview

| Method | Endpoint           | Description           | Access |
| ------ | ------------------ | --------------------- | ------ |
| POST   | `/register`        | Register new user     | Public |
| POST   | `/login`           | Login user            | Public |
| GET    | `/google`          | Google login redirect | Public |
| GET    | `/google/callback` | Google callback       | Public |
| POST   | `/change-password` | Change password       | User   |
| POST   | `/forgot-password` | Send OTP              | Public |
| POST   | `/reset-password`  | Reset password        | Public |

---

# 📌 1. Register User

### 📍 Endpoint:

```http
POST /register
```

---

### 📥 Request Body:

```json
{
  "firstname": "Swapnil",
  "lastname": "Patil",
  "email": "swapnil@gmail.com",
  "phoneNumber": "9876543210",
  "password": "123456"
}
```

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "REGISTER_SUCCESS",
  "message": "Account created successfully.",
  "data": {
    "_id": "user123",
    "firstname": "Swapnil",
    "lastname": "Patil",
    "email": "swapnil@gmail.com"
  }
}
```

---

### 🔁 If Google Account Exists:

```json
{
  "success": true,
  "code": "ACCOUNT_LINKED",
  "message": "Your account was created using Google. A password has been added successfully."
}
```

---

### ❌ Error:

```json
{
  "success": false,
  "code": "USER_ALREADY_EXISTS",
  "message": "An account with this email already exists. Please login instead."
}
```

---

# 📌 2. Login User

### 📍 Endpoint:

```http
POST /login
```

---

### 📥 Request Body:

```json
{
  "email": "swapnil@gmail.com",
  "password": "123456"
}
```

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "LOGIN_SUCCESS",
  "message": "Login successful.",
  "token": "jwt_token_here",
  "data": {
    "_id": "user123",
    "email": "swapnil@gmail.com"
  }
}
```

---

### ❌ Wrong Password:

```json
{
  "success": false,
  "code": "INVALID_PASSWORD",
  "message": "Incorrect password. Please try again."
}
```

---

### ❌ Google Account:

```json
{
  "success": false,
  "code": "USE_GOOGLE_LOGIN",
  "message": "This account is registered with Google. Please login using Google."
}
```

---

# 📌 3. Google Login

### 📍 Endpoint:

```http
GET /google
```

👉 Redirects user to Google authentication

---

### 📍 Callback:

```http
GET /google/callback
```

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "GOOGLE_LOGIN_SUCCESS",
  "message": "Logged in successfully using Google.",
  "token": "jwt_token",
  "data": {
    "_id": "user123",
    "email": "swapnil@gmail.com"
  }
}
```

---

# 📌 4. Change Password

### 📍 Endpoint:

```http
POST /change-password
```

### 🔐 Access:

Authenticated User

---

### 📥 Request Body:

```json
{
  "oldPassword": "123456",
  "newPassword": "new123",
  "confirmPassword": "new123"
}
```

---

### ✅ Success Response:

```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

### ❌ Error:

```json
{
  "success": false,
  "message": "Old password is incorrect"
}
```

---

# 📌 5. Forgot Password (Send OTP)

### 📍 Endpoint:

```http
POST /forgot-password
```

---

### 📥 Request Body:

```json
{
  "email": "swapnil@gmail.com"
}
```

---

### ✅ Response:

```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

---

### 🔒 Security Note:

Even if user doesn't exist:

```json
{
  "success": true,
  "message": "If account exists, OTP sent"
}
```

---

# 📌 6. Reset Password

### 📍 Endpoint:

```http
POST /reset-password
```

---

### 📥 Request Body:

```json
{
  "email": "swapnil@gmail.com",
  "otp": "123456",
  "newPassword": "new123",
  "confirmPassword": "new123"
}
```

---

### ✅ Success Response:

```json
{
  "success": true,
  "message": "Password reset successful"
}
```

---

### ❌ Invalid OTP:

```json
{
  "success": false,
  "message": "Invalid or expired OTP"
}
```

---

# ⚠️ Common Errors

### Validation Error:

```json
{
  "success": false,
  "code": "VALIDATION_ERROR",
  "message": "All fields are required"
}
```

---

# 🧠 Notes

* Passwords are securely hashed
* JWT token expires in **7 days**
* Google + Local login supported
* Account linking supported
* OTP expires in **10 minutes**

---

# 🚀 Summary

* 👤 Users can register/login
* 🔐 Secure authentication system
* 🔁 Supports Google + Local login
* 🔑 Password reset via OTP

---


