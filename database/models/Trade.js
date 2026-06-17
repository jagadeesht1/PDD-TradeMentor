const mongoose = require('mongoose');

const TradeSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
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
  type: {
    type: String,
    required: true,
    enum: ['BUY', 'SELL']
  },
  quantity: {
    type: Number,
    required: true,
    min: 1
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  totalValue: {
    type: Number,
    required: true
  },
  // Calculated at time of SELL to record realized P&L
  realizedPnL: {
    type: Number,
    default: null
  }
}, {
  timestamps: true
});

// Compute totalValue pre-save
TradeSchema.pre('save', function (next) {
  this.totalValue = Number((this.quantity * this.price).toFixed(2));
  next();
});

module.exports = mongoose.model('Trade', TradeSchema);
