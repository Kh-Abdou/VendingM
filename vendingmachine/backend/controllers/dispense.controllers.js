// Function to get completed orders for hardware to dispense
exports.getNewOrdersForDispensing = async (req, res) => {  try {
    const { vendingMachineId } = req.body;

    if (!vendingMachineId) {
      return res.status(400).json({ message: 'Vending machine ID is required' });
    }

    // Import the Order model here to prevent circular imports
    const Order = require('../models/order.model');
    const Product = require('../models/product.model');

    // Find newest PENDING orders that haven't been assigned to be dispensed yet
    // Only get orders that are in PENDING status (not COMPLETED) to avoid
    // picking up orders that have already been processed
    const pendingOrder = await Order.findOne({
      status: 'PENDING', // Changed from COMPLETED to PENDING for better workflow
      isDispensingInProgress: { $ne: true }, // Not already being dispensed
      dispensedAt: null // Ensure the order hasn't been dispensed already
    }).sort({ createdAt: -1 }); // Get newest pending order first

    if (!pendingOrder) {
      return res.status(404).json({ message: 'No new orders to dispense' });
    }

    // Mark this order as being processed by the hardware
    pendingOrder.isDispensingInProgress = true;
    await pendingOrder.save();

    // Transform order for Arduino
    const dispensableProducts = [];
    
    for (const orderProduct of pendingOrder.products) {
      const product = await Product.findById(orderProduct.productId)
        .populate('chariotId');
      
      if (!product || !product.chariotId) {
        continue;
      }

      // Get the chariot number from chariot name (e.g., "CHARIOT1" -> 1)
      const chariotNumber = parseInt(product.chariotId.name.replace(/\D/g, ''));
      
      if (!isNaN(chariotNumber) && chariotNumber >= 1 && chariotNumber <= 4) {
        dispensableProducts.push({
          couloir: chariotNumber,
          quantity: orderProduct.quantity
        });
      }
    }

    if (dispensableProducts.length === 0) {
      // Reset flag if no dispensable products
      pendingOrder.isDispensingInProgress = false;
      await pendingOrder.save();
      return res.status(400).json({ message: 'No dispensable products in order' });
    }

    res.status(200).json({
      orderId: pendingOrder._id,
      products: dispensableProducts
    });
  } catch (error) {
    console.error('Error getting new orders for dispensing:', error);
    res.status(500).json({ message: 'Error getting new orders for dispensing' });
  }
};

// Function to mark an order as complete after hardware dispensed all products
exports.completeOrderDispensing = async (req, res) => {
  try {
    const { orderId, vendingMachineId } = req.body;

    if (!orderId || !vendingMachineId) {
      return res.status(400).json({ message: 'Order ID and vending machine ID are required' });
    }

    const Order = require('../models/order.model');
    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }    // No need to change the status since it's already COMPLETED,
    // just mark that dispensing is done and record the machine that dispensed it
    order.isDispensingInProgress = false;
    order.dispensedAt = new Date();
    order.vendingMachineId = vendingMachineId;
    // Ensure the status is set to COMPLETED
    order.status = 'COMPLETED';

    await order.save();

    res.status(200).json({
      message: 'Order dispensing completed successfully'
    });
  } catch (error) {
    console.error('Error completing order dispensing:', error);
    res.status(500).json({ message: 'Error completing order dispensing' });
  }
};
