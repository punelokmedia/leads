# 📂 Category APIs

---

## 📌 Create Category

**POST** `/categories/add-category` 🔐

```json
{
  "name": "Plumber",
  "icon": "plumber.png"
}
```

---

## 📌 Update Category

**PUT** `/categories/update-category` 🔐

```json
{
  "categoryId": "CATEGORY_ID",
  "name": "Updated Name",
  "icon": "icon.png"
}
```

---

## 📌 Delete Category

**DELETE** `/categories/delete-category` 🔐

```json
{
  "categoryId": "CATEGORY_ID"
}
```

---

## 📌 Get Category by ID

**GET** `/categories/get-category/:id`

---

## 📌 Get All Categories

**GET** `/categories/get-all-categories`
