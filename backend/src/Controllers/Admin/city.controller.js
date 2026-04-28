import { City } from "../../Models/city.model.js";

const getAllCities = async (req, res) => {
  try {
    const cities = await City.find().sort({ name: 1 }).select("-__v");
    return res.status(200).json({
      success: true,
      message: "Cities fetched successfully",
      data: cities,
    });
  } catch (error) {
    console.error("Get Cities Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch cities",
    });
  }
};

const createCity = async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({
        success: false,
        message: "City name is required",
      });
    }

    const normalizedName = name.trim().toLowerCase();
    const existing = await City.findOne({ name: normalizedName }).select("_id");
    if (existing) {
      return res.status(409).json({
        success: false,
        message: "City already exists",
      });
    }

    const city = await City.create({ name: normalizedName });
    return res.status(201).json({
      success: true,
      message: "City added successfully",
      data: city,
    });
  } catch (error) {
    console.error("Create City Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add city",
    });
  }
};

const updateCity = async (req, res) => {
  try {
    const { cityId, name } = req.body;
    if (!cityId || !name) {
      return res.status(400).json({
        success: false,
        message: "cityId and name are required",
      });
    }

    const city = await City.findById(cityId);
    if (!city) {
      return res.status(404).json({
        success: false,
        message: "City not found",
      });
    }

    const normalizedName = name.trim().toLowerCase();
    const existing = await City.findOne({
      name: normalizedName,
      _id: { $ne: cityId },
    }).select("_id");
    if (existing) {
      return res.status(409).json({
        success: false,
        message: "City already exists",
      });
    }

    city.name = normalizedName;
    await city.save();

    return res.status(200).json({
      success: true,
      message: "City updated successfully",
      data: city,
    });
  } catch (error) {
    console.error("Update City Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update city",
    });
  }
};

const deleteCity = async (req, res) => {
  try {
    const { cityId } = req.body;
    if (!cityId) {
      return res.status(400).json({
        success: false,
        message: "cityId is required",
      });
    }

    const city = await City.findById(cityId);
    if (!city) {
      return res.status(404).json({
        success: false,
        message: "City not found",
      });
    }

    await City.findByIdAndDelete(cityId);
    return res.status(200).json({
      success: true,
      message: "City deleted successfully",
    });
  } catch (error) {
    console.error("Delete City Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete city",
    });
  }
};

export { getAllCities, createCity, updateCity, deleteCity };
