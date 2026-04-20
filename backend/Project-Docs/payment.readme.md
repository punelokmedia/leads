# 💳 Payment APIs

---

## 📌 Create Order

**POST** `/order/create` 🔐

---

### Response

```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "razorpayOrderId": "order_xxx",
    "internalOrderId": "ORDER_ID",
    "amount": 199,
    "currency": "INR",
    "leadsCount": 1
  }
}
```

---

## 📌 Notes

* Uses Razorpay
* Amount is in INR
* Always verify payment on backend
