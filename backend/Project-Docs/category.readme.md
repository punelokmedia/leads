# 📂 Category API Documentation

This document covers all **Category-related APIs** used in the system.

---

# 🔐 Base URL

```http
http://localhost:3000/api/v1/category
```

---

# 🔑 Authentication

All APIs require a valid JWT token.

### Header:

```json
{
  "Authorization": "Bearer <your_token>"
}
```

---

# 📊 APIs Overview

| Method | Endpoint              | Description          | Access |
| ------ | --------------------- | -------------------- | ------ |
| GET    | `/get-all-categories` | Fetch all categories | User   |
| GET    | `/get-category/:id`   | Get category by ID   | User   |
| POST   | `/add-category`       | Create new category  | Admin  |
| PUT    | `/update-category`    | Update category      | Admin  |
| DELETE | `/delete-category`    | Delete category      | Admin  |

---

# 📌 1. Get All Categories

### 📍 Endpoint:

```http
GET /get-all-categories
```

---

### 🧠 Description:

Fetch all available categories sorted by latest.

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "CATEGORIES_FETCHED",
  "message": "Categories fetched successfully",
  "data": [
    {
      "_id": "cat123",
      "name": "real estate",
      "icon": "🏠",
      "createdAt": "2026-04-15T10:00:00Z"
    },
    {
      "_id": "cat456",
      "name": "jobs",
      "icon": "💼",
      "createdAt": "2026-04-14T08:00:00Z"
    }
  ]
}
```

---

### ❌ Error Response:

```json
{
  "success": false,
  "code": "CATEGORIES_FETCH_FAILED",
  "message": "Failed to fetch categories"
}
```

---

# 📌 2. Get Category By ID

### 📍 Endpoint:

```http
GET /get-category/:id
```

---

### 🧠 Description:

Fetch a single category using its ID.

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "CATEGORY_FETCHED",
  "message": "Category fetched successfully",
  "data": {
    "_id": "cat123",
    "name": "real estate",
    "icon": "🏠"
  }
}
```

---

### ❌ Not Found:

```json
{
  "success": false,
  "code": "CATEGORY_NOT_FOUND",
  "message": "Category not found"
}
```

---

# 📌 3. Create Category (Admin)

### 📍 Endpoint:

```http
POST /add-category
```

---

### 🔐 Access:

Admin only

---

### 📥 Request Body:

```json
{
  "name": "Real Estate",
  "icon": "🏠"
}
```

---

### 🧠 Description:

* Creates a new category
* Name is normalized (lowercase)
* Prevents duplicate categories

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "CATEGORY_CREATED",
  "message": "Category created successfully",
  "data": {
    "_id": "cat789",
    "name": "real estate",
    "icon": "🏠"
  }
}
```

---

### ❌ Duplicate Category:

```json
{
  "success": false,
  "code": "CATEGORY_ALREADY_EXISTS",
  "message": "Category already exists"
}
```

---

# 📌 4. Update Category (Admin)

### 📍 Endpoint:

```http
PUT /update-category
```

---

### 📥 Request Body:

```json
{
  "categoryId": "cat123",
  "name": "Updated Name",
  "icon": "📊"
}
```

---

### 🧠 Description:

* Update category name or icon
* Prevents duplicate names

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "CATEGORY_UPDATED",
  "message": "Category updated successfully",
  "data": {
    "_id": "cat123",
    "name": "updated name",
    "icon": "📊"
  }
}
```

---

### ❌ Error:

```json
{
  "success": false,
  "code": "CATEGORY_UPDATE_FAILED",
  "message": "Failed to update category"
}
```

---

# 📌 5. Delete Category (Admin)

### 📍 Endpoint:

```http
DELETE /delete-category
```

---

### 📥 Request Body:

```json
{
  "categoryId": "cat123"
}
```

---

### 🧠 Description:

* Deletes category
* Prevents deletion if used in leads

---

### ✅ Success Response:

```json
{
  "success": true,
  "code": "CATEGORY_DELETED",
  "message": "Category deleted successfully"
}
```

---

### ❌ If Category in Use:

```json
{
  "success": false,
  "code": "CATEGORY_IN_USE",
  "message": "Category is in use and cannot be deleted"
}
```

---

# ⚠️ Common Errors

### Unauthorized:

```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "Access denied. Admin only."
}
```

---

# 🧠 Notes

* Category names are stored in lowercase
* Only admins can create/update/delete
* Categories are linked with leads
* Deletion is restricted if in use

---

# 🚀 Summary

* 👤 Users can view categories
* 👨‍💼 Admins manage categories
* 🔒 Safe operations with validation
* ⚡ Clean and scalable structure

---

