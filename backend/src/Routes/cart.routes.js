import express from "express";
import {
  addToCart,
  getCart,
  removeFromCart,
  clearCart,
} from "../Controllers/orders/cart.controller.js";
import { auth } from "../Middlewares/auth.middleware.js";

const router = express.Router();

router.post("/add-cart", auth, addToCart);
router.get("/get-cart", auth, getCart);
router.delete("/delete-cart-item", auth, removeFromCart);
router.delete("/delete-cart", auth, clearCart);
export default router;
