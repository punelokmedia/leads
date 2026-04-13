# 🔐 Authentication APIs

base_url: `http://localhost:3000/api/v1`

Base URL: `{{base_url}}/auth`

---

## 🔑 Headers (Protected Routes)

```
Authorization: Bearer <token>
Content-Type: application/json
```

---

## 📌 Register User

**POST** `/register`

### Request

```json
{
  "firstname": "Swapnil",
  "lastname": "Sutar",
  "email": "swap@gmail.com",
  "phoneNumber": "9359248889",
  "password": "Swap@123"
}
```

### Response

```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "id": "USER_ID",
    "email": "swap@gmail.com"
  }
}
```

---

## 📌 Login User

**POST** `/login`

```json
{
  "email": "swap@gmail.com",
  "password": "Swap@123"
}
```

---

## 📌 Google Auth

**GET** `/google`

---

## 📌 Change Password

**POST** `/change-password` 🔐

```json
{
  "oldPassword": "old",
  "newPassword": "new",
  "confirmPassword": "new"
}
```

---

## 📌 Forgot Password (Send OTP)

**POST** `/forgot-password`

```json
{
  "email": "user@gmail.com"
}
```

---

## 📌 Reset Password

**POST** `/reset-password`

```json
{
  "email": "user@gmail.com",
  "otp": "123456",
  "newPassword": "123456",
  "confirmPassword": "123456"
}
```

---

## 📌 Add Address

**POST** `/add-address` 🔐

```json
{
  "label": "HOME",
  "street": "Flat 203",
  "landmark": "Near Temple",
  "city": "Nashik",
  "state": "Maharashtra",
  "zipcode": "422001",
  "isDefault": true
}
```
