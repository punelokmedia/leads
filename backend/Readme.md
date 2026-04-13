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
│
└── app.js
```


# 🔐 Environment Variables

Create a `.env` file:

```env
PORT=3000

MONGO_URI=your_mongodb_connection

JWT_SECRET=your_secret

GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_secret

RAZORPAY_KEY_ID=your_key
RAZORPAY_KEY_SECRET=your_secret

EMAIL_API_KEY=your_email_service_key
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
leads-collections.json
```

---

# 🚀 Deployment

* Use **PM2** or **Docker**
* Deploy on:

  * AWS / EC2
  * Render
  * Railway

---

# ⚠️ Important Notes

* Always validate user input
* Use proper error handling
* Secure routes using middleware
* Never expose secrets in code

---




# ⭐ Future Improvements

* Swagger API Docs
* Redis Caching
* WebSockets for real-time leads
* Admin Dashboard UI
* Notifications system

---

# 💡 License

This project is licensed under MIT License.
