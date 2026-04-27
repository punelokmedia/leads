import express from "express";
import { auth, isAdmin } from "../Middlewares/auth.middleware.js";
import {
  createCategory,
  getAllCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
} from "../Controllers/Admin/category.controller.js";

const router = express.Router();

router.get("/get-all-categories", getAllCategories);
router.get("/get-category/:id", getCategoryById);

router.post("/add-category", auth, isAdmin, createCategory);
router.put("/update-category", auth, isAdmin, updateCategory);
router.delete("/delete-category", auth, isAdmin, deleteCategory);


export default router;
