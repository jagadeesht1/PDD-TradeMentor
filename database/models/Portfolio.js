const mongoose = require('mongoose');

// Sub-document for each holding in the portfolio
const HoldingSchema = new mongoose.Schema({
  symbol: {
    type: String,
    required: true,
    trim: true,
    uppercase: true
  },
  stockName: {
    type: String,
    required: true,
    trim: true
  },
  exchange: {
    type: String,
    enum: ['NSE', 'BSE'],
    default: 'NSE'
  },
  quantity: {
    type: Number,
    required: true,
    default: 0
  },
  averageBuyPrice: {
    type: Number,
    required: true,
    default: 0
  },
  totalInvested: {
    type: Number,
    required: true,
    default: 0
  }
}, { _id: false });

const PortfolioSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  holdings: {
    type: [HoldingSchema],
    default: []
  },
  totalRealizedPnL: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Helper: find holding index by symbol
PortfolioSchema.methods.findHolding = function (symbol) {
  return this.holdings.findIndex(h => h.symbol === symbol.toUpperCase());
};

module.exports = mongoose.model('Portfolio', PortfolioSchema);
