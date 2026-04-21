import { Category } from "../../Models/category.model.js";
import { Lead } from "../../Models/leads.model.js";

const createCategory = async (req, res) => {
  try {
    const { name, icon } = req.body;

    if (!name) {
      return res.status(400).json({
        success: false,
        message: "Category name is required",
      });
    }

    const normalizedName = name.trim().toLowerCase();

    const existing = await Category.findOne({ name: normalizedName });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Category already exists",
      });
    }

    const category = await Category.create({
      name: normalizedName,
      icon,
    });

    return res.status(201).json({
      success: true,
      message: "Category created successfully",
      data: category,
    });
  } catch (error) {
    console.error("Create Category Error:", error);
    return res.status(500).json({
      success: false,
      message: "Error creating category",
    });
  }
};

const getAllCategories = async (req, res) => {
  try {
    const categories = await Category.find()
      .sort({ createdAt: -1 })
      .select("-__v");

    return res.status(200).json({
      success: true,
      message: "Categories fetched successfully",
      data: categories,
    });
  } catch (error) {
    console.error("Get Categories Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch categories",
    });
  }
};

const getCategoryById = async (req, res) => {
  try {
    const { id } = req.params;

    const category = await Category.findById(id).select("-__v");

    if (!category) {
      return res.status(404).json({
        success: false,
        message: "Category not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Category fetched successfully",
      data: category,
    });
  } catch (error) {
    console.error("Get Category Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch category",
    });
  }
};

const updateCategory = async (req, res) => {
  try {
    const { categoryId } = req.body;
    const { name, icon } = req.body;

    if (!categoryId) {
      return res.status(404).json({
        success: false,
        message: "categoryId is required",
      });
    }

    const category = await Category.findById(categoryId);

    if (!category) {
      return res.status(404).json({
        success: false,
        message: "Category not found",
      });
    }

    if (name) {
      const normalizedName = name.trim().toLowerCase();

      const existing = await Category.findOne({
        name: normalizedName,
        _id: { $ne: categoryId },
      });

      if (existing) {
        return res.status(400).json({
          success: false,
          message: "Category name already in use",
        });
      }

      category.name = normalizedName;
    }

    if (icon !== undefined) {
      category.icon = icon;
    }

    await category.save();

    return res.status(200).json({
      success: true,
      message: "Category updated successfully",
      data: category,
    });
  } catch (error) {
    console.error("Update Category Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update category",
    });
  }
};

const deleteCategory = async (req, res) => {
  try {
    const { categoryId } = req.body;

    if (!categoryId) {
      return res.status(404).json({
        success: false,
        message: "categoryId is required",
      });
    }

    const category = await Category.findById(categoryId);

    if (!category) {
      return res.status(404).json({
        success: false,
        message: "Category not found",
      });
    }

    // ⚠️ Optional: prevent delete if used in leads
    const isUsed = await Lead.exists({ category: categoryId });
    if (isUsed) {
      return res.status(400).json({
        success: false,
        message: "Category is in use and cannot be deleted",
      });
    }

    await Category.findByIdAndDelete(categoryId);

    return res.status(200).json({
      success: true,
      message: "Category deleted successfully",
    });
  } catch (error) {
    console.error("Delete Category Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete category",
    });
  }
};

export {
  createCategory,
  getAllCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
};
