const mongoose = require('mongoose');

const hardwareSchema = new mongoose.Schema({
  vendingMachineId: {
    type: String,
    default: 'VM001', // Default ID for our single machine
    index: true       // Index for faster lookups but no longer required or unique
  },
  name: {
    type: String,
    default: 'Main Vending Machine'
  },
  location: {
    type: String,
    default: 'Main Building'
  },
  status: {
    type: String,
    enum: ['OPERATIONAL', 'MAINTENANCE', 'ERROR', 'OFFLINE'],
    default: 'OPERATIONAL'
  },
  temperature: {
    type: Number,
    default: 0
  },
  humidity: {
    type: Number,
    default: 0
  },
  lastCommunication: {
    type: Date,
    default: Date.now
  },
  maintainer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  productMapping: [{
    couloir: {
      type: Number,
      required: true,
      min: 1,
      max: 4
    },
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true
    },
    stockLevel: {
      type: Number,
      default: 0
    }
  }]
}, {
  timestamps: true
});

// Method to check if a product is available in a specific couloir
hardwareSchema.methods.isProductAvailable = function(couloir, quantity) {
  const mapping = this.productMapping.find(
    (p) => p.couloir === couloir
  );
  
  return mapping && mapping.stockLevel >= quantity;
};

// Method to update stock level for a product in a specific couloir
hardwareSchema.methods.updateStockLevel = async function(couloir, amount) {
  const mapping = this.productMapping.find(
    (p) => p.couloir === couloir
  );
  
  if (mapping) {
    mapping.stockLevel += amount;
    if (mapping.stockLevel < 0) mapping.stockLevel = 0;
    await this.save();
    return mapping.stockLevel;
  }
  
  return null;
};

const Hardware = mongoose.model('Hardware', hardwareSchema);
module.exports = Hardware;
