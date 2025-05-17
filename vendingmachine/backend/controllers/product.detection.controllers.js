const Order = require('../models/order.model');

// Controller for registering a product detection from Arduino
exports.registerProductDetection = async (req, res) => {
  try {
    const { orderId, couloir, quantity } = req.body;
    
    if (!orderId) {
      return res.status(400).json({ message: 'Order ID is required' });
    }
    
    const order = await Order.findById(orderId);
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
      // Update order to indicate product detection
    // Simplified approach: mark the whole order as dispensed
    // More complex systems would track detection per product
    order.isDispensingInProgress = false;
    order.dispensedAt = new Date(); // Mark when product was detected
    order.status = 'COMPLETED'; // Update status to COMPLETED once products are detected
    
    await order.save();
    
    console.log(`Product detected for order ${orderId} in couloir ${couloir}, quantity: ${quantity}`);
    
    res.status(200).json({
      message: 'Product detection registered successfully',
      orderId: order._id,
      detectedAt: order.dispensedAt
    });
  } catch (error) {
    console.error('Error registering product detection:', error);
    res.status(500).json({
      message: 'Error registering product detection',
      error: error.message
    });
  }
};
