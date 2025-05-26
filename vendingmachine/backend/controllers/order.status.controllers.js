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
    }    // Include product dispensing status in response
    // We'll consider products detected when dispensing is not in progress anymore
    // and the order has been marked dispensed with a timestamp
    const allProductsDetected = !order.isDispensingInProgress && order.dispensedAt !== null;
    
    // Check for partial dispensing
    const isPartialDispensing = order.dispensingDetails?.isPartialDispensing || false;
    const totalDispensed = order.dispensingDetails?.totalDispensed || 0;
    const totalExpected = order.dispensingDetails?.totalExpected || 0;
    
    // Determine explicit success flag for frontend
    const success = order.status === 'COMPLETED' && allProductsDetected;
    
    res.status(200).json({
      orderId: order._id,
      status: order.status,
      success: success, // Explicit success flag for clear frontend determination
      isPartialDispensing: isPartialDispensing,
      paymentProcessed: order.paymentMethod === 'EWALLET',
      failureReason: order.failureReason || null,
      failedAt: order.failedAt || null,
      failureDetails: order.failureDetails || null,
      dispensingStatus: {
        allProductsDetected,
        isPartialDispensing,
        totalDispensed,
        totalExpected,
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
