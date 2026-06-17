const mongoose = require('mongoose');

const AlertSchema = new mongoose.Schema({
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
  targetPrice: {
    type: Number,
    required: true
  },
  isTriggered: {
    type: Boolean,
    required: true,
    default: false
  },
  triggeredAt: {
    type: Date
  },
  criteria: {
    type: String,
    required: true,
    enum: ['GREATER_THAN', 'LESS_THAN', 'STOP_LOSS']
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Alert', AlertSchema);
