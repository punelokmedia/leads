import { Lead } from "../../Models/leads.model.js";
import { Category } from "../../Models/category.model.js";

const createLead = async (req, res) => {
  try {
    const {
      title,
      description,
      category,
      city,
      state,
      address,
      price,
      budgetMin,
      budgetMax,
      customerName,
      phone,
      expiresAt,
      coordinates,
    } = req.body;

    if (
      !title ||
      !description ||
      !category ||
      !city ||
      !state ||
      !price ||
      !expiresAt
    ) {
      return res.status(400).json({
        success: false,
        message: "Required fields missing",
      });
    }

    if (typeof price !== "number" || price <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid price",
      });
    }

    const expiryDate = new Date(expiresAt);
    if (isNaN(expiryDate) || expiryDate <= new Date()) {
      return res.status(400).json({
        success: false,
        message: "Invalid expiry date",
      });
    }

    if (
      (budgetMin && typeof budgetMin !== "number") ||
      (budgetMax && typeof budgetMax !== "number") ||
      (budgetMin && budgetMax && budgetMin > budgetMax)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid budget range",
      });
    }

    if (phone && !/^[6-9]\d{9}$/.test(phone)) {
      return res.status(400).json({
        success: false,
        message: "Invalid phone",
      });
    }

    if (
      !coordinates ||
      !Array.isArray(coordinates) ||
      coordinates.length !== 2
    ) {
      return res.status(400).json({
        success: false,
        message: "Coordinates must be [lng, lat]",
      });
    }

    const categoryExists = await Category.findById(category);
    if (!categoryExists) {
      return res.status(404).json({
        success: false,
        message: "Category not found",
      });
    }

    const lead = await Lead.create({
      title,
      description,
      category,
      city,
      state,
      address,
      price,
      budget: { min: budgetMin, max: budgetMax },
      customerName,
      phone,
      expiresAt: expiryDate,
      location: {
        type: "Point",
        coordinates,
      },
      createdBy: req.user.id,
    });

    return res.status(201).json({
      success: true,
      message: "Lead created successfully",
      data: lead,
    });
  } catch (error) {
    console.error("Create Lead Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create lead",
    });
  }
};

const updateLead = async (req, res) => {
  try {
    const { leadId } = req.body;
    const userId = req.user.id;

    if (!leadId) {
      return res.status(404).json({
        success: false,
        message: "leadId is required",
      });
    }

    const lead = await Lead.findById(leadId);

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    if (lead.createdBy.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: "Unauthorized",
      });
    }

    if (lead.expiresAt < new Date()) {
      return res.status(400).json({
        success: false,
        message: "Cannot update expired lead",
      });
    }

    const updatedLead = await Lead.findByIdAndUpdate(leadId, req.body, {
      new: true,
      runValidators: true,
    });

    return res.status(200).json({
      success: true,
      message: "Lead updated successfully",
      data: updatedLead,
    });
  } catch (error) {
    console.error("Update Lead Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update lead",
    });
  }
};

const deleteLead = async (req, res) => {
  try {
    const { leadId } = req.body;
    const userId = req.user.id;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID required",
      });
    }

    const lead = await Lead.findById(leadId);

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    if (lead.createdBy.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: "Unauthorized",
      });
    }

    await Lead.findByIdAndDelete(leadId);

    return res.status(200).json({
      success: true,
      message: "Lead deleted successfully",
    });
  } catch (error) {
    console.error("Delete Lead Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete lead",
    });
  }
};

const getAllLeads = async (req, res) => {
  try {
    const userId = req.user?.id;

    const { page = 1, limit = 10, category, city, state } = req.query;

    const query = {
      status: "ACTIVE",
      expiresAt: { $gt: new Date() },
    };

    if (category) query.category = category;
    if (city) query.city = city;
    if (state) query.state = state;

    const skip = (page - 1) * limit;

    const [leads, total] = await Promise.all([
      Lead.find(query)
        .select("-phone -customerName -address -__v -buyers")
        .populate("category", "name")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit)),

      Lead.countDocuments(query),
    ]);

    const modifiedLeads = leads.map((lead) => {
      const isPurchased = userId
        ? lead.buyers?.some((b) => b.user.toString() === userId)
        : false;

      return {
        ...lead.toObject(),
        isPurchased,
      };
    });

    return res.status(200).json({
      success: true,
      message: "Leads fetched",
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
      },
      data: modifiedLeads,
    });
  } catch (error) {
    console.error("Get Leads Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch leads",
    });
  }
};

const getLeadDetailsById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const lead = await Lead.findById(id);

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    const purchased = lead.buyers.some((b) => b.user.toString() === userId);

    const responseLead = lead.toObject();

    if (!purchased) {
      responseLead.phone = null;
      responseLead.address = null;
      responseLead.customerName = null;
    }

    return res.status(200).json({
      success: true,
      message: "Lead details fetched",
      data: {
        ...responseLead,
        isPurchased: purchased,
      },
    });
  } catch (error) {
    console.error("Get Lead Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch lead",
    });
  }
};

export { createLead, updateLead, deleteLead, getLeadDetailsById, getAllLeads };
