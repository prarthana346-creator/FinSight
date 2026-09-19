const mongoose = require('mongoose');

// ============================================================
// FINANCIAL DATA
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

    // For normal investments this is the investment amount.
    // For Financial Goal this stores the target amount.
    amount: {
      type: Number,
      default: 0,
    },

    notes: {
      type: String,
      default: '',
    },

    // ==========================================================
    // FINANCIAL GOAL FIELDS
    // ==========================================================

    currentSavings: {
      type: Number,
      default: 0,
    },

    targetDate: {
      type: String,
      default: '',
    },

    monthlyContribution: {
      type: Number,
      default: 0,
    },

    status: {
      type: String,
      enum: [
        'Work Done',
        'In Progress',
        'To Do',
      ],
      default: 'To Do',
    },
  },
  {
    _id: true,
  }
);


// ============================================================
// GOLD RECORD
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
// FD / RD DEPOSIT RECORD
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
// LIFE INSURANCE RECORD
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

    // Mutual Funds, SIP, PF, Financial Goals, Other
    investments: {
      type: [FinancialDataSchema],
      default: [],
    },

    // Gold records
    goldRecords: {
      type: [GoldRecordSchema],
      default: [],
    },

    // FD and RD records
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


// ============================================================
// EXPORT MODEL
// ============================================================

module.exports = mongoose.model(
  'Portfolio',
  PortfolioSchema
);