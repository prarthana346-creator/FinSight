const mongoose = require('mongoose');

// ============================================================
// FINANCIAL DATA
// Used for:
// Mutual Fund
// SIP
// PF
// Financial Goal
// Other Investment
// ============================================================

const FinancialDataSchema = new mongoose.Schema(
  {
    portfolioCategory: {
      type: String,
      default: '',
    },

    type: {
      type: String,
      default: '',
    },

    name: {
      type: String,
      default: '',
    },

    // For normal investments:
    // amount = invested amount
    //
    // For Financial Goal:
    // amount = target amount
    amount: {
      type: Number,
      default: 0,
    },

    // ========================================================
    // FINANCIAL GOAL FIELDS
    // ========================================================

    currentSavings: {
      type: Number,
      default: 0,
    },

    monthlyContribution: {
      type: Number,
      default: 0,
    },

    targetDate: {
      type: String,
      default: '',
    },

    notes: {
      type: String,
      default: '',
    },
  },
  {
    _id: true,
  }
);

// ============================================================
// GOLD
// ============================================================

const GoldRecordSchema = new mongoose.Schema(
  {
    date: {
      type: Date,
      default: Date.now,
    },

    pricePerGram: {
      type: Number,
      default: 0,
    },

    grams: {
      type: Number,
      default: 0,
    },

    amountInvested: {
      type: Number,
      default: 0,
    },
  },
  {
    _id: true,
  }
);

// ============================================================
// FD / RD
// ============================================================

const DepositRecordSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      default: '',
    },

    bank: {
      type: String,
      default: '',
    },

    accountNumber: {
      type: String,
      default: '',
    },

    principal: {
      type: Number,
      default: 0,
    },

    monthlyDeposit: {
      type: Number,
      default: 0,
    },

    interestRate: {
      type: Number,
      default: 0,
    },

    startDate: {
      type: String,
      default: '',
    },

    maturityDate: {
      type: String,
      default: '',
    },

    maturityAmount: {
      type: Number,
      default: 0,
    },
  },
  {
    _id: true,
  }
);

// ============================================================
// LIFE INSURANCE
// ============================================================

const InsuranceRecordSchema = new mongoose.Schema(
  {
    company: {
      type: String,
      default: '',
    },

    policyNumber: {
      type: String,
      default: '',
    },

    policyType: {
      type: String,
      default: '',
    },

    premium: {
      type: Number,
      default: 0,
    },

    frequency: {
      type: String,
      default: '',
    },

    startDate: {
      type: String,
      default: '',
    },

    maturityDate: {
      type: String,
      default: '',
    },

    sumAssured: {
      type: Number,
      default: 0,
    },
  },
  {
    _id: true,
  }
);

// ============================================================
// FUTURE GOALS / NOTEPAD
// ============================================================

const FutureGoalNoteSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      default: '',
    },

    note: {
      type: String,
      default: '',
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    _id: true,
  }
);

// ============================================================
// PORTFOLIO
// One portfolio document per user
// ============================================================

const PortfolioSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },

    // Mutual Fund / SIP / PF / Financial Goal / Other
    investments: {
      type: [FinancialDataSchema],
      default: [],
    },

    // Gold holdings
    goldRecords: {
      type: [GoldRecordSchema],
      default: [],
    },

    // FD and RD
    deposits: {
      type: [DepositRecordSchema],
      default: [],
    },

    // Life Insurance
    insurancePolicies: {
      type: [InsuranceRecordSchema],
      default: [],
    },

    // Future Goals / Notepad
    futureGoalNotes: {
      type: [FutureGoalNoteSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  'Portfolio',
  PortfolioSchema
);