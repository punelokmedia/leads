# 🛠 Admin APIs

base_url: `http://localhost:3000/api/v1`

Base URL: `{{base_url}}/admin`  

---

## 📌 Send OTP

**POST** `/send-otp`

```json
{
  "email": "admin@gmail.com"
}
```

---

## 📌 Verify OTP (Admin Login)

**POST** `/verify-otp`

```json
{
  "email": "admin@gmail.com",
  "otp": "123456"
}
```

### Response

```json
{
  "success": true,
  "message": "Admin login successful",
  "token": "JWT_TOKEN",
  "data": {
    "role": "ADMIN"
  }
}
```

---

## 📌 Make User Admin

**POST** `/make-admin` 🔐

```json
{
  "userId": "USER_ID"
}
```

---

## 🔐 Notes

* Only ADMIN can access protected routes
* Token required for role-based actions
