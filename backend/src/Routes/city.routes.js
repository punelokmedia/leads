import express from "express";
import { auth, isAdmin } from "../Middlewares/auth.middleware.js";
import {
  createCity,
  deleteCity,
  getAllCities,
  updateCity,
} from "../Controllers/Admin/city.controller.js";

const router = express.Router();

router.get("/get-all-cities", getAllCities);
router.post("/add-city", auth, isAdmin, createCity);
router.put("/update-city", auth, isAdmin, updateCity);
router.delete("/delete-city", auth, isAdmin, deleteCity);

export default router;
