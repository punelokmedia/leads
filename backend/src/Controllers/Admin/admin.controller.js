import jwt from "jsonwebtoken";
import { User } from "../../Models/user.model.js";
import { sendAdminOtpEmail } from "../../Utils/email.resend.utils.js";
import { Lead } from "../../Models/leads.model.js";
import { Order } from "../../Models/orders.models.js";

const sendOtpForAdminLogin = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const admin = await User.findOne({ email, role: "ADMIN" });

    if (!admin) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Not an admin.",
      });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpire = new Date(Date.now() + 10 * 60 * 1000);

    try {
      const emailResponse = await sendAdminOtpEmail(email, otp);

      admin.resetOtp = otp;
      admin.resetOtpExpire = otpExpire;
      await admin.save();

      return res.status(200).json({
        success: true,
        message: "OTP sent to admin email",
      });
    } catch (mailError) {
      console.error("❌ Email failed:", mailError.message);

      return res.status(500).json({
        success: false,
        message: mailError.message,
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

    const admin = await User.findOne({ email, role: "ADMIN" });

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
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
    const { userId } = req.body;

    console.log("req.user.role ", req.user.role);

    if (req.user.role !== "ADMIN") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Only admin can change roles.",
      });
    }

    // 🔍 2. Validate input
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User ID is required",
      });
    }

    // 🔎 3. Find user
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // ⚠️ 4. Prevent changing already ADMIN
    if (user.role === "ADMIN") {
      return res.status(400).json({
        success: false,
        message: "User is already an admin",
      });
    }

    // 🔄 5. Update role
    user.role = "ADMIN";
    await user.save();

    return res.status(200).json({
      success: true,
      message: "User promoted to admin successfully",
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

 const getDashboardOverview = async (req, res) => {
  try {
    const [
      totalUsers,
      totalLeads,
      activeLeads,
      soldLeads,
      expiredLeads,
      totalOrders,
      revenueData,
    ] = await Promise.all([
      User.countDocuments(),
      Lead.countDocuments(),
      Lead.countDocuments({ status: "ACTIVE" }),
      Lead.countDocuments({ status: "SOLD_OUT" }),
      Lead.countDocuments({ status: "EXPIRED" }),
      Order.countDocuments({ status: "PAID" }),
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
        totalLeads,
        activeLeads,
        soldLeads,
        expiredLeads,
        totalOrders,
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
    const data = await Lead.aggregate([
      { $unwind: "$buyers" },
      {
        $group: {
          _id: "$category",
          totalSold: { $sum: 1 },
        },
      },
      { $sort: { totalSold: -1 } },
      { $limit: 5 },
    ]);

    return res.status(200).json({
      success: true,
      code: "TOP_CATEGORIES_FETCHED",
      message:
        data.length > 0
          ? "Top performing categories fetched successfully."
          : "No category sales data available yet.",
      data,
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
    const orders = await Order.find({ status: "PAID" })
      .populate("user", "email firstname lastname")
      .sort({ createdAt: -1 })
      .limit(10);

    return res.status(200).json({
      success: true,
      code: "RECENT_ORDERS_FETCHED",
      message:
        orders.length > 0
          ? "Recent orders fetched successfully."
          : "No recent orders found.",
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
      status, // 🔥 admin can filter by status
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
        .populate("buyers.user", "firstname email") // 🔥 admin visibility
        .populate("createdBy", "firstname email")
        .sort(sortOption)
        .skip(skip)
        .limit(Number(limit)),

      Lead.countDocuments(query),
    ]);

    return res.status(200).json({
      success: true,
      message: leads.length
        ? "Admin leads fetched successfully"
        : "No leads found",
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
      },
      data: leads,
    });
  } catch (error) {
    console.error("Admin Get Leads Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch leads (admin)",
      error: error.message,
    });
  }
};

const getLeadByIdAdmin = async (req, res) => {
  try {
    const lead = await Lead.findById(req.params.id)
      .populate("category", "name")
      .populate("buyers.user", "firstname email")
      .populate("createdBy", "firstname email");

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Lead fetched successfully (admin)",
      data: lead,
    });
  } catch (error) {
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
  getDashboardOverview,
  getRevenueAnalytics,
  getTopCategories,
  getRecentOrders,
  getAllLeadsAdmin,
  getLeadByIdAdmin

};
