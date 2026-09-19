const express = require("express");
const mongoose = require("mongoose");
const Portfolio = require("../models/Portfolio");

const router = express.Router();

console.log("Portfolio router loaded successfully");

// GET PORTFOLIO
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    console.log("GET PORTFOLIO:", userId);

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    const portfolio = await Portfolio.findOne({ userId });

    return res.status(200).json({
      success: true,
      portfolio: portfolio || {
        userId,
        investments: [],
        goldRecords: [],
        deposits: [],
        insurancePolicies: [],
        futureGoalNotes: [],
      },
    });
  } catch (error) {
    console.error("GET PORTFOLIO ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to load portfolio",
      error: error.message,
    });
  }
});


// PUT / SAVE PORTFOLIO
router.put("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    console.log("=================================");
    console.log("SAVE PORTFOLIO REQUEST");
    console.log("USER ID:", userId);
    console.log("=================================");

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    const {
      investments = [],
      goldRecords = [],
      deposits = [],
      insurancePolicies = [],
      futureGoalNotes = [],
    } = req.body;

    console.log("Investments:", investments.length);
    console.log("Gold:", goldRecords.length);
    console.log("Deposits:", deposits.length);
    console.log("Insurance:", insurancePolicies.length);
    console.log("Future Notes:", futureGoalNotes.length);

    const portfolio = await Portfolio.findOneAndUpdate(
      { userId: userId },
      {
        $set: {
          userId: userId,
          investments: investments,
          goldRecords: goldRecords,
          deposits: deposits,
          insurancePolicies: insurancePolicies,
          futureGoalNotes: futureGoalNotes,
        },
      },
      {
        new: true,
        upsert: true,
        runValidators: true,
      }
    );

    console.log("PORTFOLIO SAVED SUCCESSFULLY!");

    return res.status(200).json({
      success: true,
      message: "Portfolio saved permanently",
      portfolio: portfolio,
    });

  } catch (error) {
    console.error("SAVE PORTFOLIO ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to save portfolio",
      error: error.message,
    });
  }
});


// DELETE PORTFOLIO
router.delete("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
    }

    await Portfolio.findOneAndDelete({ userId });

    return res.status(200).json({
      success: true,
      message: "Portfolio deleted",
    });

  } catch (error) {
    console.error("DELETE PORTFOLIO ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to delete portfolio",
    });
  }
});

module.exports = router;