import XLSX from "xlsx";
import { Lead, resolveLeadStatus } from "../../Models/leads.model.js";
import { Category } from "../../Models/category.model.js";
import { UploadLog } from "../../Models/uploadLog.model.js";

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
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required",
      });
    }

    const lead = await Lead.findById(id);

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    // ✅ Optional: Prevent updating expired leads
    if (lead.expiresAt < new Date()) {
      return res.status(400).json({
        success: false,
        message: "Cannot update an expired lead",
      });
    }

    // ✅ Optional: Prevent update if sold out
    if (lead.buyers.length >= lead.maxBuyers) {
      return res.status(400).json({
        success: false,
        message: "Cannot update a sold-out lead",
      });
    }

    // ✅ Allowed fields (prevent unwanted updates)
    const allowedFields = [
      "title",
      "description",
      "category",
      "city",
      "state",
      "address",
      "price",
      "budget",
      "expiresAt",
      "location",
    ];

    const updates = {};

    Object.keys(req.body).forEach((key) => {
      if (allowedFields.includes(key)) {
        updates[key] = req.body[key];
      }
    });

    const updatedLead = await Lead.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    }).populate("category", "name");

    return res.status(200).json({
      success: true,
      message: "Lead updated successfully by admin",
      data: updatedLead,
    });
  } catch (error) {
    console.error("Admin Update Lead Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to update lead",
      error: error.message,
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

    const {
      page = 1,
      limit = 10,
      category,
      city,
      state,
      search,
      sort = "latest", // latest | cheapest | expensive
    } = req.query;

    const query = {
      status: "ACTIVE",
      expiresAt: { $gt: new Date() },
    };

    // ✅ Filters
    if (category) query.category = category;
    if (city) query.city = new RegExp(city, "i");
    if (state) query.state = new RegExp(state, "i");

    // ✅ Search (title + city)
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: "i" } },
        { city: { $regex: search, $options: "i" } },
      ];
    }

    // ✅ Sorting
    let sortOption = { createdAt: -1 }; // latest

    if (sort === "cheapest") sortOption = { price: 1 };
    if (sort === "expensive") sortOption = { price: -1 };

    const skip = (Number(page) - 1) * Number(limit);

    const [leads, total] = await Promise.all([
      Lead.find(query)
        .select("-__v")
        .populate("category", "name")
        .sort(sortOption)
        .skip(skip)
        .limit(Number(limit)),

      Lead.countDocuments(query),
    ]);

    const modifiedLeads = leads.map((lead) => {
      const isPurchased = userId
        ? lead.buyers.some((b) => b.user.toString() === userId)
        : false;

      const obj = lead.toObject();

      // ✅ Hide sensitive data
      delete obj.buyers;
      delete obj.phone;
      delete obj.customerName;
      delete obj.address;

      return {
        ...obj,
        isPurchased,
      };
    });

    return res.status(200).json({
      success: true,
      message: modifiedLeads.length
        ? "Leads fetched successfully"
        : "No leads found based on your criteria",
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
      },
      filters: {
        category,
        city,
        state,
        search,
        sort,
      },
      data: modifiedLeads,
    });
  } catch (error) {
    console.error("Get Leads Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch leads",
      error: error.message,
    });
  }
};

const getLeadDetailsById = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required",
      });
    }

    const lead = await Lead.findById(id).populate("category", "name");

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    const isPurchased = userId
      ? lead.buyers.some((b) => b.user.toString() === userId)
      : false;

    const status =
      lead.expiresAt < new Date()
        ? "EXPIRED"
        : lead.buyers.length >= lead.maxBuyers
          ? "SOLD_OUT"
          : "ACTIVE";

    const responseLead = lead.toObject();

    // ✅ Hide sensitive info if not purchased
    if (!isPurchased) {
      responseLead.phone = null;
      responseLead.address = null;
      responseLead.customerName = null;
    }

    return res.status(200).json({
      success: true,
      message: "Lead details fetched successfully",
      data: {
        ...responseLead,
        isPurchased,
        status,
      },
    });
  } catch (error) {
    console.error("Get Lead Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch lead details",
      error: error.message,
    });
  }
};

// const uploadLeadsFromExcel = async (req, res) => {
//   const session = await mongoose.startSession();

//   try {
//     if (!req.file) {
//       return res.status(400).json({
//         success: false,
//         message: "Excel file is required",
//       });
//     }

//     if (
//       !req.file.mimetype.includes("sheet") &&
//       !req.file.originalname.endsWith(".xlsx")
//     ) {
//       return res.status(400).json({
//         success: false,
//         message: "Only Excel (.xlsx) files are allowed",
//       });
//     }

//     const workbook = XLSX.read(req.file.buffer, { type: "buffer" });
//     const sheet = workbook.Sheets[workbook.SheetNames[0]];
//     const data = XLSX.utils.sheet_to_json(sheet);

//     if (!data.length) {
//       return res.status(400).json({
//         success: false,
//         message: "Excel file is empty",
//       });
//     }

//     const categoryIds = [
//       ...new Set(data.map((row) => row.category).filter(Boolean)),
//     ];

//     const categories = await Category.find({
//       _id: { $in: categoryIds },
//     }).select("_id");

//     const categorySet = new Set(categories.map((c) => c._id.toString()));

//     const leadsToInsert = [];
//     const failedRows = [];

//     for (let i = 0; i < data.length; i++) {
//       const row = data[i];

//       try {
//         const {
//           title,
//           description,
//           category,
//           city,
//           state,
//           price,
//           budgetMin,
//           budgetMax,
//           customerName,
//           phone,
//           expiresAt,
//           lng,
//           lat,
//         } = row;

//         if (
//           !title ||
//           !description ||
//           !category ||
//           !city ||
//           !state ||
//           !price ||
//           !expiresAt
//         ) {
//           throw new Error("Missing required fields");
//         }

//         // ✅ Category validation
//         if (!categorySet.has(category)) {
//           throw new Error("Invalid category");
//         }

//         const parsedPrice = Number(price);
//         if (isNaN(parsedPrice) || parsedPrice <= 0) {
//           throw new Error("Invalid price");
//         }

//         const expiryDate = new Date(expiresAt);
//         if (isNaN(expiryDate) || expiryDate <= new Date()) {
//           throw new Error("Invalid expiry date");
//         }

//         // ✅ Phone validation
//         if (phone && !/^[6-9]\d{9}$/.test(phone)) {
//           throw new Error("Invalid phone number");
//         }

//         // ✅ Coordinates validation
//         const longitude = Number(lng);
//         const latitude = Number(lat);

//         if (isNaN(longitude) || isNaN(latitude)) {
//           throw new Error("Invalid coordinates");
//         }

//         leadsToInsert.push({
//           title,
//           description,
//           category,
//           city,
//           state,
//           price: parsedPrice,
//           budget: {
//             min: budgetMin ? Number(budgetMin) : undefined,
//             max: budgetMax ? Number(budgetMax) : undefined,
//           },
//           customerName,
//           phone,
//           expiresAt: expiryDate,
//           location: {
//             type: "Point",
//             coordinates: [longitude, latitude],
//           },
//           createdBy: req.user.id,
//         });
//       } catch (err) {
//         failedRows.push({
//           row: i + 1,
//           error: err.message,
//         });
//       }
//     }

//     if (!leadsToInsert.length) {
//       return res.status(400).json({
//         success: false,
//         message: "No valid leads found",
//         failedRows,
//       });
//     }

//     await session.withTransaction(async () => {
//       await Lead.insertMany(leadsToInsert);
//     });

//     return res.status(201).json({
//       success: true,
//       message: "Leads uploaded successfully",
//       totalInserted: leadsToInsert.length,
//       totalFailed: failedRows.length,
//       failedRows,
//     });
//   } catch (error) {
//     console.error("Upload Leads Error:", error);

//     return res.status(500).json({
//       success: false,
//       message: "Failed to upload leads",
//       error: error.message,
//     });
//   } finally {
//     session.endSession();
//   }
// };

const uploadLeadsFromExcel = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Excel file is required",
      });
    }

    if (
      !req.file.mimetype.includes("sheet") &&
      !req.file.originalname.endsWith(".xlsx")
    ) {
      return res.status(400).json({
        success: false,
        message: "Only Excel (.xlsx) files are allowed",
      });
    }

    const workbook = XLSX.read(req.file.buffer, { type: "buffer" });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const data = XLSX.utils.sheet_to_json(sheet);

    if (!data.length) {
      return res.status(400).json({
        success: false,
        message: "Excel file is empty",
      });
    }

    const categoryIds = [
      ...new Set(data.map((row) => row.category).filter(Boolean)),
    ];

    const categories = await Category.find({
      _id: { $in: categoryIds },
    }).select("_id");

    const categorySet = new Set(categories.map((c) => c._id.toString()));

    const uploadLog = await UploadLog.create({
      totalRows: data.length,
    });

    // ✅ Response with message
    res.status(202).json({
      success: true,
      message: "Upload started successfully. Processing in background.",
      uploadId: uploadLog._id,
      totalRows: data.length,
    });

    processLeadsInBackground(data, categorySet, uploadLog._id, req.user.id);
  } catch (err) {
    console.error(err);
    return res.status(500).json({
      success: false,
      message: "Failed to start upload process",
    });
  }
};

const processLeadsInBackground = async (
  data,
  categorySet,
  uploadId,
  userId,
) => {
  const BATCH_SIZE = 50;

  for (let i = 0; i < data.length; i += BATCH_SIZE) {
    const batch = data.slice(i, i + BATCH_SIZE);

    let leadsToInsert = [];
    let logs = [];

    for (let j = 0; j < batch.length; j++) {
      const row = batch[j];
      const rowIndex = i + j + 1;

      try {
        const {
          title,
          description,
          category,
          city,
          state,
          price,
          budgetMin,
          budgetMax,
          customerName,
          phone,
          expiresAt,
          lng,
          lat,
        } = row;

        if (
          !title ||
          !description ||
          !category ||
          !city ||
          !state ||
          !price ||
          !expiresAt
        ) {
          throw new Error("Missing required fields");
        }

        if (!categorySet.has(String(category))) {
          throw new Error("Invalid category");
        }

        const parsedPrice = Number(price);
        if (isNaN(parsedPrice) || parsedPrice <= 0) {
          throw new Error("Invalid price");
        }

        const expiryDate = new Date(expiresAt);
        if (isNaN(expiryDate) || expiryDate <= new Date()) {
          throw new Error("Invalid expiry date");
        }

        if (phone && !/^[6-9]\d{9}$/.test(phone)) {
          throw new Error("Invalid phone number");
        }

        const longitude = Number(lng);
        const latitude = Number(lat);

        if (
          isNaN(longitude) ||
          isNaN(latitude) ||
          longitude < -180 ||
          longitude > 180 ||
          latitude < -90 ||
          latitude > 90
        ) {
          throw new Error("Invalid coordinates");
        }

        const location = {
          type: "Point",
          coordinates: [longitude, latitude],
        };

        leadsToInsert.push({
          title,
          description,
          category,
          city,
          state,
          price: parsedPrice,
          budget: {
            min: budgetMin ? Number(budgetMin) : undefined,
            max: budgetMax ? Number(budgetMax) : undefined,
          },
          customerName,
          phone,
          expiresAt: expiryDate,
          location,
          createdBy: userId,
        });
      } catch (err) {
        logs.push({
          row: rowIndex,
          message: err.message,
        });
      }
    }

    if (leadsToInsert.length) {
      await Lead.insertMany(leadsToInsert, { ordered: false });
    }

    await UploadLog.findByIdAndUpdate(uploadId, {
      $inc: {
        processedRows: batch.length,
        successCount: leadsToInsert.length,
        failedCount: logs.length,
      },
      $push: {
        logs: { $each: logs },
      },
    });

    console.log(
      `Processed ${Math.min(i + BATCH_SIZE, data.length)}/${data.length}`,
    );
  }

  // ✅ Final message stored
  const finalLog = await UploadLog.findById(uploadId);

  await UploadLog.findByIdAndUpdate(uploadId, {
    status: "completed",
    finalMessage: `Upload completed. ${finalLog.successCount} leads added, ${finalLog.failedCount} failed.`,
  });
};

const getUploadStatus = async (req, res) => {
  const log = await UploadLog.findById(req.params.id);

  if (!log) {
    return res.status(404).json({
      success: false,
      message: "Upload not found",
    });
  }

  const progress = ((log.processedRows / log.totalRows) * 100).toFixed(2);

  let message = "Upload in progress";

  if (log.status === "completed") {
    message =
      log.finalMessage ||
      `Upload completed. ${log.successCount} success, ${log.failedCount} failed.`;
  }

  res.json({
    success: true,
    message,
    status: log.status,
    progress: `${progress}%`,
    processed: log.processedRows,
    total: log.totalRows,
    success: log.successCount,
    failed: log.failedCount,
    logs: log.logs.slice(-10),
  });
};

export {
  createLead,
  updateLead,
  deleteLead,
  getLeadDetailsById,
  getAllLeads,
  uploadLeadsFromExcel,
  getUploadStatus,
};
