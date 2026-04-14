# 🛠 Admin APIs

Use this command to create the default admin:

```bash
npm run seed:admin
```

---

## 🌐 Base URL

```
http://localhost:3000/api/v1
```

### Admin Base Path

```
{{base_url}}/admin
```

---

# 🔐 Authentication Flow

1. Send OTP → `/send-otp`
2. Verify OTP → `/verify-otp`
3. Receive JWT Token
4. Use token for protected routes

---

## 📌 1. Send OTP (Admin Login)

**POST** `/admin/send-otp`

### Request

```json
{
  "email": "admin@gmail.com"
}
```

### Response

```json
{
  "success": true,
  "message": "OTP sent to admin email"
}
```

---

## 📌 2. Verify OTP (Admin Login)

**POST** `/admin/verify-otp`

### Request

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
    "id": "ADMIN_ID",
    "email": "admin@gmail.com",
    "role": "ADMIN"
  }
}
```

---

## 📌 3. Make User Admin 🔐

**POST** `/admin/make-admin`

### Headers

```
Authorization: Bearer <JWT_TOKEN>
```

### Request

```json
{
  "userId": "USER_ID"
}
```

### Response

```json
{
  "success": true,
  "message": "User promoted to admin successfully"
}
```

---

# 🔐 Authorization Rules

- Only users with role `ADMIN` can access protected routes
- JWT token is required in headers:

```
Authorization: Bearer <token>
```

---

# ⚠️ Important Notes

- OTP is valid for **10 minutes**
- Only seeded/admin users can log in via OTP
- Do not expose admin email publicly
- Always protect admin routes with middleware

---

# 🚀 Developer Tips

- Seed admin only once:

  ```bash
  npm run seed:admin
  ```

- Use environment variables:

  ```env
  ADMIN_EMAIL=admin@gmail.com
  ADMIN_PASSWORD=Admin@123
  ```

- Ensure JWT secret is set:

  ```env
  JWT_SECRET=your_secret_key
  ```

---

# ✅ Summary

| Feature            | Status |
| ------------------ | ------ |
| Admin Seeder       | ✅     |
| OTP Login          | ✅     |
| JWT Authentication | ✅     |
| Role-based Access  | ✅     |
