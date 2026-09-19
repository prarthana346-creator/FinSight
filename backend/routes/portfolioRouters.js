const express = require('express');
const mongoose = require('mongoose');
const Portfolio = require('../models/Portfolio');

const router = express.Router();

/*
  GET USER PORTFOLIO
  GET /api/portfolio/:userId
*/
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        message: 'Invalid user ID',
      });
    }

    let portfolio = await Portfolio.findOne({ userId });

    // If user has never saved a portfolio before,
    // return an empty portfolio.
    if (!portfolio) {
      portfolio = {
        userId,
        investments: [],
        goldRecords: [],
        deposits: [],
        insurancePolicies: [],
        futureGoalNotes: [],
      };
    }

    res.status(200).json({
      success: true,
      portfolio,
    });
  } catch (error) {
    console.error('GET PORTFOLIO ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to load portfolio',
    });
  }
});


/*
  SAVE ENTIRE PORTFOLIO
  PUT /api/portfolio/:userId
*/
router.put('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        message: 'Invalid user ID',
      });
    }

    const {
      investments = [],
      goldRecords = [],
      deposits = [],
      insurancePolicies = [],
      futureGoalNotes = [],
    } = req.body;

    const portfolio = await Portfolio.findOneAndUpdate(
      { userId },

      {
        $set: {
          investments,
          goldRecords,
          deposits,
          insurancePolicies,
          futureGoalNotes,
        },
      },

      {
        new: true,
        upsert: true,
        runValidators: true,
      }
    );

    res.status(200).json({
      success: true,
      message: 'Portfolio saved permanently',
      portfolio,
    });
  } catch (error) {
    console.error('SAVE PORTFOLIO ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to save portfolio',
      error: error.message,
    });
  }
});


/*
  DELETE ENTIRE PORTFOLIO
  Optional endpoint.
*/
router.delete('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        message: 'Invalid user ID',
      });
    }

    await Portfolio.findOneAndDelete({ userId });

    res.status(200).json({
      success: true,
      message: 'Portfolio deleted',
    });
  } catch (error) {
    console.error('DELETE PORTFOLIO ERROR:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to delete portfolio',
    });
  }
});

module.exports = router;