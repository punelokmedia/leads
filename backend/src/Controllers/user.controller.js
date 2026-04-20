import { User } from "../Models/user.model.js";

const addAddress = async (req, res) => {
  try {
    const userId = req.user.id;

    const {
      label,
      street,
      landmark,
      city,
      state,
      country,
      zipcode,
    } = req.body;

    if (!street || !city || !state || !zipcode) {
      return res.status(400).json({
        success: false,
        message: "street, city, state and zipcode are required",
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const newAddress = {
      label,
      street,
      landmark,
      city,
      state,
      country,
      zipcode,
    };

    // 🔥 Replace instead of push
    user.address = newAddress;

    await user.save();

    return res.status(200).json({
      success: true,
      message: user.address
        ? "Address updated successfully"
        : "Address added successfully",
      data: user.address,
    });

  } catch (error) {
    console.error("Add Address Error:", error);

    return res.status(500).json({
      success: false,
      message: "Error saving address",
    });
  }
};

export { addAddress };
