const mongoose = require('mongoose');

const StockSchema = new mongoose.Schema({
  symbol: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    uppercase: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  exchange: {
    type: String,
    required: true,
    enum: ['NSE', 'BSE'],
    default: 'NSE'
  },
  currentPrice: {
    type: Number,
    required: true
  },
  openPrice: {
    type: Number,
    required: true
  },
  pChange: {
    type: Number,
    required: true,
    default: 0.0
  },
  isGainer: {
    type: Boolean,
    required: true,
    default: false
  },
  sector: {
    type: String,
    required: true,
    trim: true
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Stock', StockSchema);
