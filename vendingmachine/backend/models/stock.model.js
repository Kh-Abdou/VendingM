const mongoose = require('mongoose');

const stockSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    default: 0,
    min: 0
  },
  location: {
    type: String,
    required: true
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  threshold: {
    type: Number,
    default: 5,
    min: 0
  },
  isLowStock: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Middleware pour vérifier et mettre à jour le statut de stock faible
stockSchema.pre('save', function(next) {
  this.isLowStock = this.quantity <= this.threshold;
  next();
});

module.exports = mongoose.model('Stock', stockSchema);