const Order = require('../models/order.model');
const NotificationModel = require('../models/notification.model');

// Handler for order failures reported by the ESP32
exports.handleOrderFailure = async (req, res) => {
  try {
    const { orderId, vendingMachineId, reason, details } = req.body;

    if (!orderId) {
      return res.status(400).json({ message: 'Order ID is required' });
    }

    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Update order with failure information
    order.status = 'FAILED';
    order.isDispensingInProgress = false;
    order.failureReason = reason || 'Unknown error';
    order.failureDetails = details || {};
    order.failedAt = new Date();
    order.vendingMachineId = vendingMachineId;

    await order.save();    // Create a notification for both the user and technicians
    const userNotification = new NotificationModel({
      userId: order.userId,
      title: 'Problème avec votre commande',
      message: `Votre commande n'a pas pu être distribuée. Raison: ${reason || 'Erreur technique'}`,
      type: 'ORDER', // Now using the proper ORDER type that we added to the schema enum
      orderId: order._id,
      priority: 5, // 5 = highest priority (critical)
      status: 'UNREAD',
      // Include more details about the order in the notification
      metadata: {
        orderId: order._id.toString(),
        failureReason: reason || 'Erreur technique',
        failureDetails: details || {},
        failedAt: new Date().toISOString(),
        refundStatus: "NO_PAYMENT_PROCESSED", // To indicate no money was deducted
        orderDetails: {
          totalAmount: order.totalAmount,
          paymentMethod: order.paymentMethod,
          products: order.products
        }
      }
    });

    await userNotification.save();

    res.status(200).json({
      message: 'Order failure recorded successfully',
      orderId: order._id
    });
  } catch (error) {
    console.error('Error handling order failure:', error);
    res.status(500).json({ 
      message: 'Error handling order failure',
      error: error.message
    });
  }
};
