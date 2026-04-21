import jwt from "jsonwebtoken";
import mongoose from "mongoose";
import { User } from "../../Models/user.model.js";
import { sendAdminOtpEmail } from "../../Utils/email.resend.utils.js";
import { Lead } from "../../Models/leads.model.js";
import { Order } from "../../Models/orders.models.js";
import { ENV } from "../../Config/env.config.js";

const getEmailMatcher = (email = "") => ({
  $regex: `^${email.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`,
  $options: "i",
});

const isEnvAdminEmail = (email = "") =>
  ENV.ADMIN_EMAIL?.trim().toLowerCase() === email.trim().toLowerCase();

const isValidEmail = (email = "") =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());

const getNameFromEmail = (email = "") => {
  const localPart = email.trim().split("@")[0] || "Admin";
  const cleaned = localPart.replace(/[^a-zA-Z0-9]+/g, " ").trim();
  if (!cleaned) return "Admin";
  return cleaned
    .split(" ")
    .filter(Boolean)
    .map((chunk) => chunk.charAt(0).toUpperCase() + chunk.slice(1).toLowerCase())
    .join(" ");
};

const resolveAdminByEmail = async (email = "") => {
  const user = await User.findOne({
    email: getEmailMatcher(email),
  });

  if (user) {
    if (user.role === "ADMIN") return user;

    if (isEnvAdminEmail(email)) {
      user.role = "ADMIN";
      await user.save();
      return user;
    }

    return null;
  }

  if (!isEnvAdminEmail(email)) return null;

  const envAdminEmail = ENV.ADMIN_EMAIL?.trim().toLowerCase();
  if (!envAdminEmail) return null;

  const createdAdmin = await User.create({
    firstname: ENV.ADMIN_FIRSTNAME?.trim() || "Super",
    lastname: ENV.ADMIN_LASTNAME?.trim() || "Admin",
    email: envAdminEmail,
    role: "ADMIN",
    providers: ["LOCAL"],
  });

  return createdAdmin;
};

const resolveUserByIdentifier = async ({ userId, email }) => {
  const trimmedUserId = typeof userId === "string" ? userId.trim() : "";
  const normalizedEmail = typeof email === "string" ? email.trim().toLowerCase() : "";

  if (normalizedEmail) {
    if (!isValidEmail(normalizedEmail)) {
      return { error: "Please provide a valid email" };
    }
    const user = await User.findOne({ email: getEmailMatcher(normalizedEmail) });
    return { user };
  }

  if (!trimmedUserId) {
    return { error: "Either userId or email is required" };
  }

  if (!mongoose.Types.ObjectId.isValid(trimmedUserId)) {
    return { error: "Invalid userId format" };
  }

  const user = await User.findById(trimmedUserId);
  return { user };
};

const sendOtpForAdminLogin = async (req, res) => {
  try {
    const { email } = req.body;
    const normalizedEmail = email?.trim();

    if (!normalizedEmail) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const admin = await resolveAdminByEmail(normalizedEmail);

    if (!admin) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Not an admin.",
      });
    }
    if (admin.isBlocked) {
      return res.status(403).json({
        success: false,
        message: "Admin account is blocked",
      });
    }
    const otp = Math.floor(1000 + Math.random() * 9000).toString();

    const otpExpire = new Date(Date.now() + 10 * 60 * 1000);
    admin.resetOtp = otp;
    admin.resetOtpExpire = otpExpire;
    await admin.save();

    try {
      await sendAdminOtpEmail(
        admin.email,
        `${admin.firstname} ${admin.lastname}`,
        otp,
      );

      return res.status(200).json({
        success: true,
        message: "OTP sent to admin email",
      });
    } catch (mailError) {
      console.error("❌ Email failed:", mailError.message);
      const restrictionError =
        typeof mailError?.message === "string" &&
        mailError.message.includes(
          "You can only send testing emails to your own email address",
        );

      if (restrictionError && process.env.NODE_ENV !== "production") {
        return res.status(200).json({
          success: true,
          message:
            "Resend test mode restriction detected. Use this OTP for local testing.",
          devOtp: otp,
        });
      }

      return res.status(500).json({
        success: false,
        message:
          restrictionError
            ? "Email provider is in test mode. Verify a domain in Resend and set RESEND_FROM_EMAIL."
            : mailError.message,
      });
    }
  } catch (error) {
    console.error("❌ Server error:", error);

    return res.status(500).json({
      success: false,
      message: "Something went wrong",
    });
  }
};

const verifyAdminOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    const normalizedEmail = email?.trim();

    if (!normalizedEmail) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const admin = await resolveAdminByEmail(normalizedEmail);

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }
    if (admin.isBlocked) {
      return res.status(403).json({
        success: false,
        message: "Admin account is blocked",
      });
    }

    if (admin.resetOtp !== otp) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP",
      });
    }

    if (admin.resetOtpExpire < new Date()) {
      return res.status(400).json({
        success: false,
        message: "OTP expired",
      });
    }

    admin.resetOtp = null;
    admin.resetOtpExpire = null;
    await admin.save();

    const token = jwt.sign(
      { id: admin._id, role: admin.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" },
    );

    return res.status(200).json({
      success: true,
      message: "Admin login successful",
      token,
      data: {
        id: admin._id,
        fullname: admin.firstname + " " + admin.lastname,
        email: admin.email,
        role: admin.role,
      },
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      success: false,
      message: "OTP verification failed",
    });
  }
};

const changeUserRoleToAdmin = async (req, res) => {
  try {
    const { userId, email, firstname, lastname } = req.body;

    console.log("req.user.role ", req.user.role);

    if (req.user.role !== "ADMIN") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Only admin can change roles.",
      });
    }

    const trimmedUserId = typeof userId === "string" ? userId.trim() : "";
    const normalizedEmail = typeof email === "string" ? email.trim().toLowerCase() : "";

    // 🔍 2. Validate input
    if (!trimmedUserId && !normalizedEmail) {
      return res.status(400).json({
        success: false,
        message: "Either userId or email is required",
      });
    }

    const useEmailFlow = Boolean(normalizedEmail);

    if (
      !useEmailFlow &&
      trimmedUserId &&
      !mongoose.Types.ObjectId.isValid(trimmedUserId)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid userId format",
      });
    }

    let user = null;
    let responseMessage = "User promoted to admin successfully";
    let createdNewAdmin = false;

    if (!useEmailFlow && trimmedUserId) {
      user = await User.findById(trimmedUserId);

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }
    } else {
      if (!isValidEmail(normalizedEmail)) {
        return res.status(400).json({
          success: false,
          message: "Please provide a valid email",
        });
      }

      user = await User.findOne({
        email: getEmailMatcher(normalizedEmail),
      });

      if (!user) {
        const safeFirstName = (firstname || "").trim() || getNameFromEmail(normalizedEmail);
        const safeLastName = (lastname || "").trim() || "Admin";

        try {
          user = await User.create({
            firstname: safeFirstName,
            lastname: safeLastName,
            email: normalizedEmail,
            role: "ADMIN",
            providers: ["LOCAL"],
          });
        } catch (createError) {
          // In race conditions, same email may be created by another request.
          if (createError?.code === 11000) {
            user = await User.findOne({
              email: getEmailMatcher(normalizedEmail),
            });
          } else {
            throw createError;
          }
        }

        if (!user) {
          return res.status(409).json({
            success: false,
            message: "Unable to create admin for this email",
          });
        }

        responseMessage = "Admin account created successfully";
        createdNewAdmin = true;
      }
    }

    // ⚠️ 4. Prevent changing already ADMIN
    if (user.role === "ADMIN" && !createdNewAdmin) {
      return res.status(400).json({
        success: false,
        message: "User is already an admin",
      });
    }

    // 🔄 5. Update role
    if (!createdNewAdmin) {
      user = await User.findByIdAndUpdate(
        user._id,
        { $set: { role: "ADMIN" } },
        { new: true },
      );

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }
    }

    return res.status(200).json({
      success: true,
      message: responseMessage,
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Change Role Error:", error);
    return res.status(500).json({
      success: false,
      message: "Something went wrong",
    });
  }
};

const removeAdminRole = async (req, res) => {
  try {
    const { userId, email } = req.body;
    const { user, error } = await resolveUserByIdentifier({ userId, email });

    if (error) {
      return res.status(400).json({
        success: false,
        message: error,
      });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (String(user._id) === String(req.user.id)) {
      return res.status(400).json({
        success: false,
        message: "You cannot remove your own admin access",
      });
    }

    if (user.role !== "ADMIN") {
      return res.status(400).json({
        success: false,
        message: "User is not an admin",
      });
    }

    const updatedUser = await User.findByIdAndUpdate(
      user._id,
      { $set: { role: "USER" } },
      { new: true },
    );

    return res.status(200).json({
      success: true,
      message: "Admin role removed successfully",
      user: {
        id: updatedUser?._id,
        email: updatedUser?.email,
        role: updatedUser?.role,
      },
    });
  } catch (error) {
    console.error("Remove Admin Error:", error);
    return res.status(500).json({
      success: false,
      message: "Something went wrong",
    });
  }
};

const updateUserBlockStatus = async (req, res) => {
  try {
    const { userId, email, isBlocked } = req.body;
    const { user, error } = await resolveUserByIdentifier({ userId, email });

    if (error) {
      return res.status(400).json({
        success: false,
        message: error,
      });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (String(user._id) === String(req.user.id)) {
      return res.status(400).json({
        success: false,
        message: "You cannot block your own account",
      });
    }

    const targetBlockedState = Boolean(isBlocked);
    const updatedUser = await User.findByIdAndUpdate(
      user._id,
      { $set: { isBlocked: targetBlockedState } },
      { new: true },
    );

    return res.status(200).json({
      success: true,
      message: targetBlockedState
        ? "User blocked successfully"
        : "User unblocked successfully",
      user: {
        id: updatedUser?._id,
        email: updatedUser?.email,
        role: updatedUser?.role,
        isBlocked: updatedUser?.isBlocked,
      },
    });
  } catch (error) {
    console.error("Block User Error:", error);
    return res.status(500).json({
      success: false,
      message: "Something went wrong",
    });
  }
};

const deleteUserByAdmin = async (req, res) => {
  try {
    const { userId, email } = req.body;
    const { user, error } = await resolveUserByIdentifier({ userId, email });

    if (error) {
      return res.status(400).json({
        success: false,
        message: error,
      });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (String(user._id) === String(req.user.id)) {
      return res.status(400).json({
        success: false,
        message: "You cannot delete your own account",
      });
    }

    await User.findByIdAndDelete(user._id);

    return res.status(200).json({
      success: true,
      message: "User deleted successfully",
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Delete User Error:", error);
    return res.status(500).json({
      success: false,
      message: "Something went wrong",
    });
  }
};

const getAllUsersAdmin = async (req, res) => {
  try {
    const { page = 1, limit = 20, search = "" } = req.query;
    const normalizedLimit = Math.min(Math.max(Number(limit) || 20, 1), 200);
    const normalizedPage = Math.max(Number(page) || 1, 1);
    const skip = (normalizedPage - 1) * normalizedLimit;

    const query = {};
    const trimmedSearch = String(search || "").trim();
    if (trimmedSearch) {
      query.$or = [
        { email: { $regex: trimmedSearch, $options: "i" } },
        { firstname: { $regex: trimmedSearch, $options: "i" } },
        { lastname: { $regex: trimmedSearch, $options: "i" } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(query)
        .select("-password -resetOtp -resetOtpExpire")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(normalizedLimit),
      User.countDocuments(query),
    ]);

    return res.status(200).json({
      success: true,
      message: users.length ? "Users fetched successfully" : "No users found",
      meta: {
        total,
        page: normalizedPage,
        limit: normalizedLimit,
        totalPages: Math.ceil(total / normalizedLimit) || 1,
      },
      data: users,
    });
  } catch (error) {
    console.error("Get All Users Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch users",
    });
  }
};

const getAllAdmins = async (req, res) => {
  try {
    const { page = 1, limit = 20, search = "" } = req.query;
    const normalizedLimit = Math.min(Math.max(Number(limit) || 20, 1), 200);
    const normalizedPage = Math.max(Number(page) || 1, 1);
    const skip = (normalizedPage - 1) * normalizedLimit;

    const query = { role: "ADMIN" };
    const trimmedSearch = String(search || "").trim();
    if (trimmedSearch) {
      query.$or = [
        { email: { $regex: trimmedSearch, $options: "i" } },
        { firstname: { $regex: trimmedSearch, $options: "i" } },
        { lastname: { $regex: trimmedSearch, $options: "i" } },
      ];
    }

    const [admins, total] = await Promise.all([
      User.find(query)
        .select("-password -resetOtp -resetOtpExpire")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(normalizedLimit),
      User.countDocuments(query),
    ]);

    return res.status(200).json({
      success: true,
      message: admins.length ? "Admins fetched successfully" : "No admins found",
      meta: {
        total,
        page: normalizedPage,
        limit: normalizedLimit,
        totalPages: Math.ceil(total / normalizedLimit) || 1,
      },
      data: admins,
    });
  } catch (error) {
    console.error("Get All Admins Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch admins",
    });
  }
};

const getDashboardOverview = async (req, res) => {
  try {
    const [
      totalUsers,
      totalAdmins,
      totalLeads,
      activeLeads,
      soldLeads,
      expiredLeads,
      totalOrders,
      pendingOrders,
      revenueData,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ role: "ADMIN" }),
      Lead.countDocuments(),
      Lead.countDocuments({ status: "ACTIVE" }),
      Lead.countDocuments({ status: "SOLD_OUT" }),
      Lead.countDocuments({ status: "EXPIRED" }),
      Order.countDocuments({ status: "PAID" }),
      Order.countDocuments({ status: "CREATED" }),
      Order.aggregate([
        { $match: { status: "PAID" } },
        { $group: { _id: null, total: { $sum: "$totalAmount" } } },
      ]),
    ]);

    const totalRevenue = revenueData[0]?.total || 0;

    return res.status(200).json({
      success: true,
      code: "DASHBOARD_OVERVIEW_FETCHED",
      message: "Dashboard overview data fetched successfully.",
      data: {
        totalUsers,
        totalAdmins,
        totalLeads,
        activeLeads,
        soldLeads,
        expiredLeads,
        totalOrders,
        pendingOrders,
        totalRevenue,
      },
    });
  } catch (error) {
    console.error("Dashboard Error:", error);

    return res.status(500).json({
      success: false,
      code: "DASHBOARD_OVERVIEW_FAILED",
      message: "Failed to fetch dashboard overview. Please try again later.",
    });
  }
};

const getRevenueAnalytics = async (req, res) => {
  try {
    const revenue = await Order.aggregate([
      { $match: { status: "PAID" } },
      {
        $group: {
          _id: {
            month: { $month: "$createdAt" },
            year: { $year: "$createdAt" },
          },
          total: { $sum: "$totalAmount" },
        },
      },
      { $sort: { "_id.year": 1, "_id.month": 1 } },
    ]);

    return res.status(200).json({
      success: true,
      code: "REVENUE_ANALYTICS_FETCHED",
      message:
        revenue.length > 0
          ? "Revenue analytics fetched successfully."
          : "No revenue data available yet.",
      data: revenue,
    });
  } catch (error) {
    console.error("Revenue Error:", error);

    return res.status(500).json({
      success: false,
      code: "REVENUE_ANALYTICS_FAILED",
      message: "Failed to fetch revenue analytics.",
    });
  }
};

const getTopCategories = async (req, res) => {
  try {
    const soldByLeadBuyers = await Lead.aggregate([
      { $unwind: "$buyers" },
      {
        $lookup: {
          from: "leads",
          localField: "lead",
          foreignField: "_id",
          as: "leadData",
        },
      },
      {
        $lookup: {
          from: "categories",
          localField: "_id",
          foreignField: "_id",
          as: "category",
        },
      },
      {
        $unwind: {
          path: "$category",
          preserveNullAndEmptyArrays: true,
        },
      },
      {
        $project: {
          _id: 0,
          totalSold: 1,
          categoryId: "$_id",
          categoryName: { $ifNull: ["$category.name", "Unknown"] },
        },
      },
      { $sort: { totalSold: -1 } },
      { $limit: 5 },
    ]);

    // Fallback: some old/partial flows may create paid orders but not update lead.buyers.
    // In that case we derive category sales directly from paid order line items.
    const soldByOrders =
      soldByLeadBuyers.length > 0
        ? soldByLeadBuyers
        : await Order.aggregate([
            { $match: { status: "PAID" } },
            { $unwind: "$leads" },
            {
              $lookup: {
                from: "leads",
                localField: "leads.lead",
                foreignField: "_id",
                as: "leadDoc",
              },
            },
            {
              $unwind: {
                path: "$leadDoc",
                preserveNullAndEmptyArrays: false,
              },
            },
            {
              $group: {
                _id: "$leadDoc.category",
                totalSold: { $sum: { $ifNull: ["$leads.quantity", 1] } },
              },
            },
            {
              $lookup: {
                from: "categories",
                localField: "_id",
                foreignField: "_id",
                as: "category",
              },
            },
            {
              $unwind: {
                path: "$category",
                preserveNullAndEmptyArrays: true,
              },
            },
            {
              $project: {
                _id: 0,
                totalSold: 1,
                categoryId: "$_id",
                categoryName: { $ifNull: ["$category.name", "Unknown"] },
              },
            },
            { $sort: { totalSold: -1 } },
            { $limit: 5 },
          ]);

    return res.status(200).json({
      success: true,
      code: "TOP_CATEGORIES_FETCHED",
      message:
        soldByOrders.length > 0
          ? "Top performing categories fetched successfully."
          : "No category sales data available yet.",
      data: soldByOrders,
    });
  } catch (error) {
    console.error("Top Categories Error:", error);

    return res.status(500).json({
      success: false,
      code: "TOP_CATEGORIES_FAILED",
      message: "Failed to fetch top categories.",
    });
  }
};

const getRecentOrders = async (req, res) => {
  try {
    const { page = 1, limit = 5, period = "all", date } = req.query;
    const normalizedLimit = Math.min(Math.max(Number(limit) || 5, 1), 50);
    const normalizedPage = Math.max(Number(page) || 1, 1);
    const skip = (normalizedPage - 1) * normalizedLimit;
    const now = new Date();
    const orderQuery = { status: "PAID" };

    const rangeStart = new Date(now);
    rangeStart.setHours(0, 0, 0, 0);
    const rangeEnd = new Date(now);
    rangeEnd.setHours(23, 59, 59, 999);

    if (period === "today") {
      orderQuery.createdAt = { $gte: rangeStart, $lte: rangeEnd };
    } else if (period === "weekly") {
      const weeklyStart = new Date(rangeStart);
      weeklyStart.setDate(weeklyStart.getDate() - 6);
      orderQuery.createdAt = { $gte: weeklyStart, $lte: rangeEnd };
    } else if (period === "monthly") {
      const monthlyStart = new Date(now.getFullYear(), now.getMonth(), 1);
      orderQuery.createdAt = { $gte: monthlyStart, $lte: rangeEnd };
    } else if (period === "quarterly") {
      const quarter = Math.floor(now.getMonth() / 3);
      const quarterStart = new Date(now.getFullYear(), quarter * 3, 1);
      orderQuery.createdAt = { $gte: quarterStart, $lte: rangeEnd };
    } else if (period === "yearly") {
      const yearStart = new Date(now.getFullYear(), 0, 1);
      orderQuery.createdAt = { $gte: yearStart, $lte: rangeEnd };
    } else if (period === "custom" && typeof date === "string" && date.trim()) {
      const selectedDate = new Date(date);
      if (!Number.isNaN(selectedDate.getTime())) {
        const customStart = new Date(selectedDate);
        customStart.setHours(0, 0, 0, 0);
        const customEnd = new Date(selectedDate);
        customEnd.setHours(23, 59, 59, 999);
        orderQuery.createdAt = { $gte: customStart, $lte: customEnd };
      }
    }

    const [orders, total] = await Promise.all([
      Order.find(orderQuery)
      .populate("user", "email firstname lastname")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(normalizedLimit),
      Order.countDocuments(orderQuery),
    ]);

    return res.status(200).json({
      success: true,
      code: "RECENT_ORDERS_FETCHED",
      message:
        orders.length > 0
          ? "Recent orders fetched successfully."
          : "No recent orders found.",
      meta: {
        total,
        page: normalizedPage,
        limit: normalizedLimit,
        totalPages: Math.ceil(total / normalizedLimit) || 1,
      },
      data: orders,
    });
  } catch (error) {
    console.error("Recent Orders Error:", error);

    return res.status(500).json({
      success: false,
      code: "RECENT_ORDERS_FAILED",
      message: "Failed to fetch recent orders.",
    });
  }
};

const getAllLeadsAdmin = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      category,
      city,
      state,
      search,
      status,
      sort = "latest",
    } = req.query;

    const query = {};

    // ✅ Filters
    if (category) query.category = category;
    if (city) query.city = new RegExp(city, "i");
    if (state) query.state = new RegExp(state, "i");
    if (status) query.status = status;

    // ✅ Search
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: "i" } },
        { city: { $regex: search, $options: "i" } },
      ];
    }

    // ✅ Sorting
    let sortOption = { createdAt: -1 };
    if (sort === "cheapest") sortOption = { price: 1 };
    if (sort === "expensive") sortOption = { price: -1 };

    const skip = (page - 1) * limit;

    const [leads, total] = await Promise.all([
      Lead.find(query)
        .populate("category", "name")
        .populate("createdBy", "firstname email")
        .sort(sortOption)
        .skip(skip)
        .limit(Number(limit))
        .lean(),

      Lead.countDocuments(query),
    ]);

    // ✅ Add computed fields
    const formattedLeads = leads.map((lead) => ({
      ...lead,
      remainingSlots: lead.maxBuyers - (lead.buyersCount || 0),
      isSoldOut: lead.buyersCount >= lead.maxBuyers,
    }));

    return res.status(200).json({
      success: true,
      message: formattedLeads.length
        ? "Admin leads fetched successfully"
        : "No leads found",
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
      },
      data: formattedLeads,
    });
  } catch (error) {
    console.error("Admin Get Leads Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch leads (admin)",
    });
  }
};

const getLeadByIdAdmin = async (req, res) => {
  try {
    const lead = await Lead.findById(req.params.id)
      .populate("category", "name")
      .populate("createdBy", "firstname email")
      .lean();

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    const purchases = await LeadPurchase.find({ lead: lead._id })
      .populate("user", "firstname email")
      .sort({ purchasedAt: -1 })
      .lean();

    const formattedLead = {
      ...lead,
      remainingSlots: lead.maxBuyers - (lead.buyersCount || 0),
      totalSold: lead.buyersCount,
      purchases, 
    };

    return res.status(200).json({
      success: true,
      message: "Lead fetched successfully (admin)",
      data: formattedLead,
    });
  } catch (error) {
    console.error("Get Lead Admin Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch lead",
    });
  }
};

export {
  sendOtpForAdminLogin,
  verifyAdminOtp,
  changeUserRoleToAdmin,
  removeAdminRole,
  updateUserBlockStatus,
  deleteUserByAdmin,
  getAllUsersAdmin,
  getAllAdmins,
  getDashboardOverview,
  getRevenueAnalytics,
  getTopCategories,
  getRecentOrders,
  getAllLeadsAdmin,
  getLeadByIdAdmin,
};
