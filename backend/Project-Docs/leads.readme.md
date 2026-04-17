# 📌 Leads API Documentation

This document provides a complete overview of all **Lead-related APIs**, including browsing, purchase history, downloads, and admin operations.

---

# 🌐 Base URL

```http
http://localhost:3000/api/v1/leads
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

| Method | Endpoint             | Description                               | Access |
| ------ | -------------------- | ----------------------------------------- | ------ |
| GET    | `/get-all-leads`     | Fetch all leads with filters & pagination | Public |
| GET    | `/get-lead/:id`      | Get single lead details                   | Public |
| GET    | `/history`           | Get user's purchased leads history        | User   |
| GET    | `/download/:orderId` | Download purchased leads as Excel         | User   |
| POST   | `/create-lead`       | Create a new lead                         | Admin  |
| PUT    | `/update-lead/:id`   | Update existing lead                      | Admin  |
| DELETE | `/delete-lead`       | Delete a lead                             | Admin  |
| POST   | `/upload-leads`      | Upload leads via Excel                    | Admin  |
| GET    | `/upload-status/:id` | Check Excel upload progress               | Admin  |

---

# 📌 1. Get All Leads

### Endpoint

```http
GET /get-all-leads
```

### Query Params (Optional)

* page
* limit
* category
* city
* state
* search
* sort → latest | cheapest | expensive

### Response

```json
{
  "success": true,
  "data": []
}
```

---

# 📌 2. Get Lead Details

### Endpoint

```http
GET /get-lead/:id
```

### Behavior

* Not purchased → sensitive data hidden
* Purchased → full details shown

---

# 📌 3. Get Purchase History

### Endpoint

```http
GET /history
```

### Headers

```json
{
  "Authorization": "Bearer token"
}
```

### Response

```json
{
  "success": true,
  "data": [
    {
      "orderId": "123",
      "status": "PAID",
      "paidAt": "2026-04-17",
      "leads": []
    }
  ]
}
```

---

# 📌 4. Download Leads

### Endpoint

```http
GET /download/:orderId
```

### Description

* Download purchased leads in **Excel (.xlsx)** format
* Only available for **paid orders**
* Can be restricted to **one-time download**

---

# 📌 5. Create Lead (Admin)

### Endpoint

```http
POST /create-lead
```

### Body

```json
{
  "title": "Interior Design Lead",
  "description": "Looking for 2BHK design",
  "category": "categoryId",
  "city": "Pune",
  "state": "Maharashtra",
  "price": 500,
  "expiresAt": "2026-05-01",
  "coordinates": [73.78, 19.99]
}
```

---

# 📌 6. Update Lead (Admin)

### Endpoint

```http
PUT /update-lead/:id
```

---

# 📌 7. Delete Lead (Admin)

### Endpoint

```http
DELETE /delete-lead
```

### Body

```json
{
  "leadId": "leadId"
}
```

---

# 📌 8. Upload Leads via Excel

### Endpoint

```http
POST /upload-leads
```

### Form Data

* file → Excel (.xlsx)

### Response

```json
{
  "success": true,
  "uploadId": "123"
}
```

---

# 📌 9. Get Upload Status

### Endpoint

```http
GET /upload-status/:id
```

### Response

```json
{
  "success": true,
  "status": "processing",
  "processed": 50,
  "total": 100
}
```

---

# ⚠️ Error Format

```json
{
  "success": false,
  "message": "Error message"
}
```

---

# 🧠 Notes

* Leads have statuses: ACTIVE, SOLD_OUT, EXPIRED
* Sensitive data is hidden until purchase
* Bulk upload runs in background
* Download API returns Excel file
* Purchase history is based on orders

---

# 🚀 Summary

* 👤 Users can browse & purchase leads
* 📥 Users can download purchased leads
* 👨‍💼 Admins manage and upload leads
* ⚡ System supports bulk operations

---
