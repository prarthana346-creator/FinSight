const mongoose = require('mongoose');

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
    amount: {
      type: Number,
      default: 0,
    },
    notes: {
      type: String,
      default: '',
    },
  },
  { _id: true }
);

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
  { _id: true }
);

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
  { _id: true }
);

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
  { _id: true }
);

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
  { _id: true }
);

const PortfolioSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },

    investments: {
      type: [FinancialDataSchema],
      default: [],
    },

    goldRecords: {
      type: [GoldRecordSchema],
      default: [],
    },

    deposits: {
      type: [DepositRecordSchema],
      default: [],
    },

    insurancePolicies: {
      type: [InsuranceRecordSchema],
      default: [],
    },

    futureGoalNotes: {
      type: [FutureGoalNoteSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Portfolio', PortfolioSchema);