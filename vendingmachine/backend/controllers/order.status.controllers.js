const Order = require('../models/order.model');

// Controller to handle the order status endpoint that includes product detection info
exports.getOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    
    if (!orderId) {
      return res.status(400).json({ message: 'Order ID is required' });
    }
    
    const order = await Order.findById(orderId);
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Include product dispensing status in response
    // We'll consider products detected when dispensing is not in progress anymore
    // and the order has been marked dispensed with a timestamp
    const allProductsDetected = !order.isDispensingInProgress && order.dispensedAt !== null;
    
    res.status(200).json({
      orderId: order._id,
      status: order.status,
      paymentProcessed: order.paymentMethod === 'EWALLET',
      dispensingStatus: {
        allProductsDetected,
        dispensedAt: order.dispensedAt,
        isDispensingInProgress: order.isDispensingInProgress
      },
      products: order.products.map(p => ({
        productId: p.productId,
        quantity: p.quantity,
        price: p.price
      }))
    });
  } catch (error) {
    console.error('Error getting order status:', error);
    res.status(500).json({
      message: 'Error getting order status',
      error: error.message
    });
  }
};
