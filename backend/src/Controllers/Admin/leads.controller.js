import XLSX from "xlsx";
import ExcelJS from "exceljs";
import mongoose from "mongoose";
import { Lead, resolveLeadStatus } from "../../Models/leads.model.js";
import { Category } from "../../Models/category.model.js";
import { UploadLog } from "../../Models/uploadLog.model.js";
import { Order } from "../../Models/orders.models.js";

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
      sort = "latest",
    } = req.query;

    const normalizedPage = Math.max(Number(page) || 1, 1);
    const normalizedLimit = Math.min(Math.max(Number(limit) || 10, 1), 50);

    const query = {};

    if (category) query.category = category;
    if (city) query.city = new RegExp(city, "i");
    if (state) query.state = new RegExp(state, "i");

    if (search) {
      query.$or = [
        { title: { $regex: search, $options: "i" } },
        { city: { $regex: search, $options: "i" } },
      ];
    }

    let sortOption = { createdAt: -1 };
    if (sort === "cheapest") sortOption = { price: 1 };
    if (sort === "expensive") sortOption = { price: -1 };

    const skip = (normalizedPage - 1) * normalizedLimit;
    const total = await Lead.countDocuments(query);

    const leads = await Lead.find(query)
      .populate("category", "name")
      .sort(sortOption)
      .limit(normalizedLimit)
      .skip(skip);

    const modified = leads.map((lead) => {
      
      const isPurchased = userId
        ? lead.buyers.some((b) => b.user.toString() === userId)
        : false;

      const obj = lead.toObject();

      delete obj.buyers;
      delete obj.phone;
      delete obj.customerName;
      delete obj.address;

      return {
        ...obj,
        isPurchased,
        price: obj.price,
        originalPrice: obj.originalPrice || null,
      };
    });

    return res.json({
      success: true,
      message: "Leads fetched successfully",
      data: modified,
      pagination: {
        total,
        page: normalizedPage,
        limit: normalizedLimit,
        totalPages: Math.ceil(total / normalizedLimit),
      },
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch leads",
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

        price: lead.price,
        originalPrice: lead.originalPrice || null,
        discount:
          lead.originalPrice && lead.originalPrice > lead.price
            ? lead.originalPrice - lead.price
            : 0,
      },
    });
  } catch (error) {
    console.error("Get Lead Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch lead details",
    });
  }
};

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
      originalPrice,
      expiresAt,
      coordinates,
    } = req.body;

    const normalizedTitle = String(title ?? "").trim();
    const normalizedDescription = String(description ?? "").trim();
    const normalizedCategory = String(category ?? "").trim();
    const normalizedCity = String(city ?? "").trim();
    const normalizedState = String(state ?? "").trim();
    const normalizedAddress = address ? String(address).trim() : "";
    const parsedPrice = Number(price);
    const parsedOriginalPrice =
      originalPrice !== undefined && originalPrice !== null && originalPrice !== ""
        ? Number(originalPrice)
        : undefined;

    if (
      !normalizedTitle ||
      !normalizedDescription ||
      !normalizedCategory ||
      !normalizedCity ||
      !normalizedState ||
      Number.isNaN(parsedPrice) ||
      parsedPrice <= 0 ||
      !expiresAt
    ) {
      return res.status(400).json({
        success: false,
        message: "Required fields missing",
      });
    }

    if (!mongoose.isValidObjectId(normalizedCategory)) {
      return res.status(400).json({
        success: false,
        message: "Invalid category ID",
      });
    }

    const existingCategory = await Category.findById(normalizedCategory).select("_id");
    if (!existingCategory) {
      return res.status(400).json({
        success: false,
        message: "Category not found",
      });
    }

    if (
      parsedOriginalPrice !== undefined &&
      (Number.isNaN(parsedOriginalPrice) || parsedOriginalPrice <= parsedPrice)
    ) {
      return res.status(400).json({
        success: false,
        message: "Original price must be greater than price",
      });
    }

    const expiryDate = new Date(expiresAt);
    if (isNaN(expiryDate) || expiryDate <= new Date()) {
      return res.status(400).json({
        success: false,
        message: "Invalid expiry date",
      });
    }

    if (!Array.isArray(coordinates) || coordinates.length !== 2) {
      return res.status(400).json({
        success: false,
        message: "Coordinates must be [lng, lat]",
      });
    }

    const parsedLng = Number(coordinates[0]);
    const parsedLat = Number(coordinates[1]);

    if (
      Number.isNaN(parsedLng) ||
      Number.isNaN(parsedLat) ||
      parsedLng < -180 ||
      parsedLng > 180 ||
      parsedLat < -90 ||
      parsedLat > 90
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid coordinates",
      });
    }

    const lead = await Lead.create({
      title: normalizedTitle,
      description: normalizedDescription,
      category: normalizedCategory,
      city: normalizedCity,
      state: normalizedState,
      address: normalizedAddress,
      price: parsedPrice,
      originalPrice: parsedOriginalPrice,
      expiresAt: expiryDate,
      location: {
        type: "Point",
        coordinates: [parsedLng, parsedLat],
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

    const lead = await Lead.findById(id);

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    const allowedFields = [
      "title",
      "description",
      "category",
      "city",
      "state",
      "address",
      "price",
      "originalPrice", 
      "budget",
      "expiresAt",
      "location",
    ];

    const updates = {};

    for (const key of Object.keys(req.body)) {
      if (allowedFields.includes(key)) {
        updates[key] = req.body[key];
      }
    }

    if (
      updates.originalPrice &&
      updates.price &&
      updates.originalPrice <= updates.price
    ) {
      return res.status(400).json({
        success: false,
        message: "Original price must be greater than price",
      });
    }

    const updatedLead = await Lead.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    }).populate("category", "name");

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

//const uploadLeadsFromExcel = async (req, res) => {
//    const session = await mongoose.startSession();

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
//};

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

    const categoryValues = [
      ...new Set(
        data.map((row) => row.Category || row.category).filter(Boolean),
      ),
    ];

    const categories = await Category.find({
      $or: [
        {
          _id: {
            $in: categoryValues.filter((v) => mongoose.isValidObjectId(v)),
          },
        },
        { name: { $in: categoryValues } },
      ],
    });

    const categoryMap = new Map();
    categories.forEach((c) => {
      categoryMap.set(String(c._id), c._id);
      categoryMap.set(c.name, c._id);
    });

    const uploadLog = await UploadLog.create({
      totalRows: data.length,
    });

    res.status(202).json({
      success: true,
      message: "Upload started successfully. Processing in background.",
      uploadId: uploadLog._id,
      totalRows: data.length,
    });

    processLeadsInBackground(data, categoryMap, uploadLog._id, req.user.id);
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
  categoryMap,
  uploadId,
  userId,
) => {
  const BATCH_SIZE = 50;

  await UploadLog.findByIdAndUpdate(uploadId, {
    processedRows: 0,
    successCount: 0,
    failedCount: 0,
    logs: [],
    status: "processing",
  });

  let totalProcessed = 0;
  let totalSuccess = 0;
  let totalFailed = 0;

  for (let i = 0; i < data.length; i += BATCH_SIZE) {
    const batch = data.slice(i, i + BATCH_SIZE);

    let leadsToInsert = [];
    let logs = [];

    for (let j = 0; j < batch.length; j++) {
      const row = batch[j];
      const rowIndex = i + j + 2;

      try {
        const get = (keys) => {
          for (const k of keys) {
            if (row[k] !== undefined) return row[k];
          }
        };

        const title = get(["Title", "title"]);
        const description = get(["Description", "description"]);
        const categoryValue = get(["Category", "category"]);
        const city = get(["City", "city"]);
        const state = get(["State", "state"]);
        const address = get(["Address", "address"]);

        const price = Number(get(["Price", "price"]));
        const originalPriceRaw = get([
          "Original Price",
          "OriginalPrice",
          "originalPrice",
        ]);

        const originalPrice =
          originalPriceRaw !== undefined ? Number(originalPriceRaw) : undefined;

        const budgetMin = get(["Budget Min", "budgetMin"]);
        const budgetMax = get(["Budget Max", "budgetMax"]);

        const customerName = get(["Customer Name", "customerName"]);
        const phone = get(["Phone", "phone"]);

        const expiresAt = get(["Expires At", "expiresAt"]);

        const lng = Number(get(["Longitude", "lng"]));
        const lat = Number(get(["Latitude", "lat"]));

        const maxBuyers = Number(get(["Max Buyers"]) || 3);
        const image = get(["Image"]) || "";

        if (
          !title ||
          !description ||
          !categoryValue ||
          !city ||
          !state ||
          price === undefined ||
          expiresAt === undefined
        ) {
          throw new Error("Missing required fields");
        }

        const categoryId = categoryMap.get(categoryValue);
        if (!categoryId) throw new Error("Invalid category");

        if (isNaN(price) || price <= 0) {
          throw new Error("Invalid price");
        }

        if (
          originalPrice !== undefined &&
          (isNaN(originalPrice) || originalPrice <= price)
        ) {
          throw new Error("Original price must be greater than price");
        }

        let expiryDate;

        if (typeof expiresAt === "number") {
          expiryDate = new Date((expiresAt - 25569) * 86400 * 1000);
        } else {
          expiryDate = new Date(expiresAt);
        }

        if (!expiryDate || isNaN(expiryDate.getTime())) {
          throw new Error("Invalid expiry date");
        }

        expiryDate.setHours(23, 59, 59, 999);

        if (expiryDate <= new Date()) {
          throw new Error("Expiry date must be in future");
        }

        if (
          isNaN(lng) ||
          isNaN(lat) ||
          lng < -180 ||
          lng > 180 ||
          lat < -90 ||
          lat > 90
        ) {
          throw new Error("Invalid coordinates");
        }

        const location = {
          type: "Point",
          coordinates: [lng, lat],
        };

        leadsToInsert.push({
          title,
          description,
          category: categoryId,
          city,
          state,
          address,
          location,
          price,
          originalPrice,
          budget: {
            min: budgetMin ? Number(budgetMin) : undefined,
            max: budgetMax ? Number(budgetMax) : undefined,
          },
          customerName,
          phone,
          image,
          maxBuyers,
          expiresAt: expiryDate,
          createdBy: userId,
        });
      } catch (err) {
        logs.push({
          row: rowIndex,
          message: err.message,
        });
      }
    }

    let insertedDocs = [];

    if (leadsToInsert.length > 0) {
      try {
        insertedDocs = await Lead.insertMany(leadsToInsert, {
          ordered: false,
        });
      } catch (err) {
        if (err.insertedDocs) {
          insertedDocs = err.insertedDocs;
        }
      }
    }

    totalProcessed += batch.length;
    totalSuccess += insertedDocs.length;
    totalFailed += logs.length;

    await UploadLog.findByIdAndUpdate(uploadId, {
      processedRows: totalProcessed,
      successCount: totalSuccess,
      failedCount: totalFailed,
      $push: { logs: { $each: logs } },
    });

    console.log(
      `Processed ${Math.min(i + BATCH_SIZE, data.length)}/${data.length}`,
    );
  }

  await UploadLog.findByIdAndUpdate(uploadId, {
    status: "completed",
    finalMessage: `Upload completed. ${totalSuccess} success, ${totalFailed} failed.`,
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


const getUserHistory = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({
        success: false,
        message: "User not authenticated",
      });
    }

    const userId = req.user.id;

    const orders = await Order.find({
      user: userId,
      status: "PAID",
    })
      .populate({
        path: "leads.lead",
        select: "title city customerName address phone image",
      })
      .sort({ createdAt: -1 });

    if (!orders.length) {
      return res.status(200).json({
        success: true,
        message: "No purchase history found",
        count: 0,
        data: [],
      });
    }

    const history = [];

    for (const order of orders) {
      let totalAmount = 0;

      const items = order.leads
        .filter((item) => item.lead) 
        .map((item) => {
          const lead = item.lead;

          const quantity = item.quantity || 1;
          const price = item.price || 0;

          totalAmount += price * quantity;

          return {
            leadId: lead._id,
            title: lead.title || "N/A",
            city: lead.city || "N/A",
            customerName: lead.customerName || "N/A",
            address: lead.address || "N/A",
            phone: lead.phone || "N/A",
            price,
            quantity,
            total: price * quantity, 
          };
        });

      history.push({
        orderId: order._id,
        status: order.status,
        isDownloaded: order.isDownloaded,
        paidAt: order.paidAt,
        totalAmount, 
        totalItems: items.reduce((sum, i) => sum + i.quantity, 0), 
        items, 
      });
    }

    return res.status(200).json({
      success: true,
      message: "User purchase history fetched successfully",
      count: history.length,
      data: history,
    });
  } catch (error) {
    console.error("Get History Error:", error);

    return res.status(500).json({
      success: false,
      message: "Something went wrong while fetching history",
    });
  }
};

// const getUserHistory = async (req, res) => {
//   try {
//     if (!req.user || !req.user.id) {
//       return res.status(401).json({
//         success: false,
//         message: "User not authenticated",
//       });
//     }

//     const userId = req.user.id;

//     const orders = await Order.find({
//       user: userId,
//       status: "PAID",
//     })
//       .populate({
//         path: "leads.lead",
//         select: "title city customerName address phone image",
//       })
//       .sort({ createdAt: -1 });

//     if (!orders.length) {
//       return res.status(200).json({
//         success: true,
//         message: "No purchase history found",
//         count: 0,
//         data: [],
//       });
//     }

//     const history = [];

//     for (const order of orders) {
//       for (const item of order.leads) {
//         if (!item.lead) continue;

//         const lead = item.lead;

//         history.push({
//           id: lead._id,
//           orderId: order._id,
//           title: lead.title || "N/A",
//           city: lead.city || "N/A",
//           customerName: lead.customerName || "N/A",
//           address: lead.address || "N/A",
//           phone: lead.phone || "N/A",
//           price: item.price || 0,
//           status: order.status,
//           isDownloaded: order.isDownloaded,
//           paidAt: order.paidAt,
//         });
//       }
//     }

//     return res.status(200).json({
//       success: true,
//       message: "User purchase history fetched successfully",
//       count: history.length,
//       data: history,
//     });
//   } catch (error) {
//     console.error("Get History Error:", error);

//     return res.status(500).json({
//       success: false,
//       message: "Something went wrong while fetching history",
//     });
//   }
// };

const downloadLeads = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { orderId } = req.params;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    if (!orderId) {
      return res.status(400).json({
        success: false,
        message: "Order ID is required",
      });
    }

    const order = await Order.findOne({
      _id: orderId,
      user: userId,
      status: "PAID",
    }).populate({
      path: "leads.lead",
      populate: {
        path: "category",
        select: "name",
      },
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found or not paid",
      });
    }

    if (order.isDownloaded) {
      return res.status(400).json({
        success: false,
        message: "Leads already downloaded",
      });
    }

    if (!order.leads || order.leads.length === 0) {
      return res.status(400).json({
        success: false,
        message: "No leads found in this order",
      });
    }

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Leads");

    worksheet.columns = [
      { header: "Customer Name", key: "name", width: 25 },
      { header: "Phone", key: "phone", width: 18 },
      { header: "City", key: "city", width: 18 },
      { header: "State", key: "state", width: 18 },
      { header: "Address", key: "address", width: 35 },
      { header: "Category", key: "category", width: 25 },
      { header: "Requirement", key: "title", width: 30 },
      { header: "Description", key: "description", width: 40 },
      { header: "Lead Price", key: "price", width: 15 },
      { header: "Created At", key: "createdAt", width: 20 },
    ];

    worksheet.getRow(1).font = { bold: true };

    for (const item of order.leads) {
      const lead = item.lead;

      if (!lead) continue;

      for (let i = 0; i < item.quantity; i++) {
        worksheet.addRow({
          name: lead.customerName || "N/A",
          phone: lead.phone || "N/A",
          city: lead.city || "N/A",
          state: lead.state || "N/A",
          address: lead.address || "N/A",
          category: lead.category?.name || "N/A",
          title: lead.title || "N/A",
          description: lead.description || "N/A",
          price: item.price || 0,
          createdAt: lead.createdAt
            ? new Date(lead.createdAt).toLocaleDateString()
            : "N/A",
        });
      }
    }

    order.isDownloaded = true;
    order.downloadedAt = new Date();
    await order.save();

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );

    res.setHeader(
      "Content-Disposition",
      `attachment; filename=leads-${orderId}.xlsx`,
    );

    await workbook.xlsx.write(res);

    res.end();
  } catch (error) {
    console.error("Download Error:", error);

    if (!res.headersSent) {
      return res.status(500).json({
        success: false,
        message: "Failed to generate leads file",
      });
    }
  }
};

export {
  createLead,
  updateLead,
  deleteLead,
  getLeadDetailsById,
  getAllLeads,
  uploadLeadsFromExcel,
  getUploadStatus,
  getUserHistory,
  downloadLeads,
};
