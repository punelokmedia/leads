# 🚀 Leads Marketplace Backend

A scalable backend for a **Lead Marketplace Platform** where users can browse, purchase, and manage service leads (Plumber, Carpenter, Construction, etc.).

---

# 📌 Features

* 🔐 Authentication (JWT + Google Login)
* 👨‍💼 Admin Panel (OTP-based login)
* 📂 Category Management
* 🛒 Cart System
* 💳 Payment Integration (Razorpay)
* 🔓 Lead Unlock System (limited buyers per lead)
* 📍 Location-based leads (GeoJSON support)

---

# 🏗 Tech Stack

* **Backend:** Node.js, Express.js
* **Database:** MongoDB + Mongoose
* **Auth:** JWT, Google OAuth
* **Payments:** Razorpay
* **Email:** Resend / Nodemailer

---

# 📁 Project Structure

```bash
src/
│
├── Controllers/
├── Models/
├── Routes/
├── Middleware/
├── Utils/
├── Config/
├── app.js 
└── index.js
```


# 🔐 Environment Variables

Create a backend `.env` file:

```env
PORT=5000
API_VERSION=v1
NODE_ENV=development
API_BASE_URL=http://localhost:5000
DATABASE_URL=mongodb://localhost:27017/dash-leads
JWT_SECRET=your_jwt_secret

# Email (optional)
EMAIL_USER=
EMAIL_PASSWORD=
RESEND_API_KEY=
RESEND_FROM_EMAIL=

# Razorpay (any one naming style works)
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxx
# OR (legacy supported)
RAZORPAY_KEY=rzp_test_xxxxxxxxxxxx
RAZORPAY_SECRET=xxxxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=

# Google OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_CALLBACK_URL=http://localhost:5000/api/v1/auth/google/callback

# Seeder admin
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=ADMIN#123
ADMIN_FIRSTNAME=Super
ADMIN_LASTNAME=Admin
```

Frontend env (`frontend/apps/user-web/.env`) for API keys:

```env
VITE_API_BASE_URL=http://localhost:5000
VITE_RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx
```

---

# 🔑 Authentication

All protected routes require:

```bash
Authorization: Bearer <token>
```

---

# 📚 API Documentation

Detailed module-wise APIs:

* 📄 `auth.readme.md`
* 📄 `admin.readme.md`
* 📄 `cart.readme.md`
* 📄 `category.readme.md`
* 📄 `payment.readme.md`
* 📄 `web-auth-api.readme.md`

---

# 🔄 API Overview

## 🔐 Auth

* Register / Login
* Google OAuth
* Forgot / Reset Password
* Change Password
* Address Management

## 👨‍💼 Admin

* OTP Login
* Make Admin
* Manage Categories
* Create Leads

## 🛒 Cart

* Add to cart
* Get cart
* Remove items

## 💳 Payment

* Create order
* Razorpay integration

---

# 🧠 Business Logic

* ✅ Each lead can be purchased by **max 3 users**
* ⏳ Leads expire after a specific time
* 🔒 Contact details unlocked only after purchase
* 🛒 Cart before checkout
* 💰 Payment required to access leads

---

# 🧪 Testing

Use Postman Collection:

```id="testblock"
api-collections.json
```

---

# 🚀 Deployment

* Use **PM2** or **Docker**
* Deploy on:

  * AWS / EC2
  * Render
  * Railway

---




# 💡 License

This project is licensed under MIT License.
