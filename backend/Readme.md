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

Create a `.env` file:

```env
PORT=3000
API_VERSION=v1
NODE_ENV=development
DATABASE_URL=mongodb://localhost:27017/dash-leads
JWT_SECRET=Le@ds

EMAIL_USER=demo@gmail.com
EMAIL_PASSWORD=bscd pqen wjix caem  

RESEND_API_KEY=re_TJc2F2gS_5nzMYezxq6mSYtwG 

RAZORPAY_KEY=DEMO_test_SSbtfEMzhQazC4
RAZORPAY_SECRET=DEMO_rDqIcNTyATWoIXS3HXEF0
RAZORPAY_WEBHOOK_SECRET=DEMO_test_SbtfEMzhQazC4

GOOGLE_CLIENT_ID=DEMO-b4d70qstp21qfpingbn9j4ucne.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=DEMO-1kThon3zFHjwNktAygMBlKlVrWi1
GOOGLE_CALLBACK_URL=http://localhost:3000/api/v1/auth/google/callback

ADMIN_EMAIL=admin@gmail.com
ADMIN_PASSWORD=ADMIN123
ADMIN_FIRSTNAME=super
ADMIN_LASTNAME=admin
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
