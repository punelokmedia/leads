# 📌 Leads API Documentation

This document provides a complete overview of all **Lead-related APIs** in the system, including request structure, authentication, and responses.

---

# 🔐 Base URL

```
http://localhost:5000/api/v1/leads
```

---

# 🔑 Authentication

All APIs require a valid JWT token unless specified.

### Header:

```json
{
  "Authorization": "Bearer <your_token>"
}
```

---

# 📖 APIs Overview

| Method | Endpoint             | Description                  | Access       |
| ------ | -------------------- | ---------------------------- | ------------ |
| GET    | `/get-all-leads`     | Fetch all leads with filters | User         |
| GET    | `/get-lead/:id`      | Get single lead details      | User         |
| POST   | `/create-lead`       | Create a new lead            | Admin        |
| PUT    | `/update-lead/:id`   | Update a lead                | Admin        |
| DELETE | `/delete-lead`       | Delete a lead                | Admin        |
| POST   | `/upload-leads`      | Upload leads via Excel       | Admin        |
| GET    | `/upload-status/:id` | Check upload progress        | Public/Admin |

---

# 📌 1. Get All Leads

### 📍 Endpoint:

```
GET /get-all-leads
```

### 🔎 Query Params (Optional):

* `page`
* `limit`
* `category`
* `city`
* `state`
* `search`
* `sort` → `latest | cheapest | expensive`

### ✅ Response:

```json
{
  "success": true,
  "message": "Leads fetched successfully",
  "meta": {
    "total": 120,
    "page": 1,
    "limit": 10,
    "totalPages": 12
  },
  "data": [
    {
      "_id": "lead123",
      "title": "Property Buyer",
      "price": 500,
      "city": "Pune",
      "state": "Maharashtra",
      "isPurchased": false
    }
  ]
}
```

---

# 📌 2. Get Lead Details

### 📍 Endpoint:

```
GET /get-lead/:id
```

### ✅ Behavior:

* If **not purchased** → sensitive data hidden
* If **purchased** → full details shown

### ✅ Response:

```json
{
  "success": true,
  "message": "Lead details fetched successfully",
  "data": {
    "_id": "lead123",
    "title": "Property Buyer",
    "price": 500,
    "phone": null,
    "customerName": null,
    "isPurchased": false
  }
}
```

---

# 📌 3. Create Lead (Admin)

### 📍 Endpoint:

```
POST /create-lead
```

### 🔐 Access:

Admin only

### 📥 Body:

```json
{
  "title": "Need Car Loan",
  "description": "Customer looking for loan",
  "category": "categoryId",
  "city": "Mumbai",
  "state": "Maharashtra",
  "price": 1000,
  "expiresAt": "2026-05-01",
  "coordinates": [72.8777, 19.0760]
}
```

### ✅ Response:

```json
{
  "success": true,
  "message": "Lead created successfully",
  "data": { ... }
}
```

---

# 📌 4. Update Lead (Admin)

### 📍 Endpoint:

```
PUT /update-lead/:id
```

### 🔐 Access:

Admin only

### 📥 Body:

Any fields to update

### ✅ Response:

```json
{
  "success": true,
  "message": "Lead updated successfully",
  "data": { ... }
}
```

---

# 📌 5. Delete Lead (Admin)

### 📍 Endpoint:

```
DELETE /delete-lead
```

### 📥 Body:

```json
{
  "leadId": "lead123"
}
```

### ✅ Response:

```json
{
  "success": true,
  "message": "Lead deleted successfully"
}
```

---

# 📌 6. Upload Leads via Excel (Admin)

### 📍 Endpoint:

```
POST /upload-leads
```

### 🔐 Access:

Admin only

### 📥 Form Data:

* `file` → Excel (.xlsx)

### ✅ Response:

```json
{
  "success": true,
  "message": "Upload started successfully. Processing in background.",
  "uploadId": "upload123",
  "totalRows": 200
}
```

---

# 📌 7. Get Upload Status

### 📍 Endpoint:

```
GET /upload-status/:id
```

### ✅ Response:

```json
{
  "success": true,
  "message": "Upload in progress",
  "status": "processing",
  "progress": "65%",
  "processed": 130,
  "total": 200,
  "success": 120,
  "failed": 10,
  "logs": [
    {
      "row": 5,
      "message": "Invalid price"
    }
  ]
}
```

---

# ⚠️ Error Response Format

```json
{
  "success": false,
  "message": "Something went wrong"
}
```

---

# 🧠 Notes

* Leads expire based on `expiresAt`
* A lead becomes:

  * `ACTIVE`
  * `SOLD_OUT`
  * `EXPIRED`
* Sensitive data is hidden until purchase
* Bulk upload runs in background (non-blocking)

---

# 🚀 Summary

* 👤 Users can browse and view leads
* 👨‍💼 Admins manage leads
* 📊 Excel upload supports bulk operations
* 🔒 Secure data exposure based on purchase


