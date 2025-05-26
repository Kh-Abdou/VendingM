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
    const { orderId, vendingMachineId, details } = req.body;

    if (!orderId || !vendingMachineId) {
      return res.status(400).json({ message: 'Order ID and vending machine ID are required' });
    }    const Order = require('../models/order.model');
    const Product = require('../models/product.model');
    const EWalletModel = require('../models/ewallet.model');
    const NotificationModel = require('../models/notification.model');

    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Extract dispensing details from hardware
    const totalDispensed = details?.totalDispensed || 0;
    const totalExpected = details?.totalExpected || 0;
    const hasPartialDispensing = details?.hasPartialDispensing || false;
    const completionPercentage = details?.completionPercentage || 0;

    // Check for partial dispensing scenario
    let isPartialDispensing = false;
    if (totalDispensed > 0 && totalDispensed < totalExpected) {
      isPartialDispensing = true;
    }

    // Mark that dispensing is done and record the machine that dispensed it
    order.isDispensingInProgress = false;
    order.dispensedAt = new Date();
    order.vendingMachineId = vendingMachineId;
    
    // Set status to COMPLETED even for partial dispensing (per requirements)
    order.status = 'COMPLETED';
    
    // Store dispensing details for frontend to use
    order.dispensingDetails = {
      totalDispensed,
      totalExpected,
      isPartialDispensing,
      completionPercentage
    };    // NOW is the time to actually process payment
    if (order.paymentMethod === 'EWALLET') {
      // Find e-wallet
      const wallet = await EWalletModel.findOne({ userId: order.userId });
      
      if (!wallet) {
        console.error('E-wallet not found for user:', order.userId);
        return res.status(404).json({ message: 'E-wallet not found' });
      }
        // Calculate payment amount - for partial dispensing, only charge for dispensed products
      let paymentAmount = order.totalAmount;
      if (isPartialDispensing) {
        // Calculate actual payment based on dispensed products and their individual prices
        paymentAmount = 0;
        
        // Get detailed dispensing info if available
        const dispensingStatus = details || {};
          for (const orderProduct of order.products) {
          // Get product details to find the chariot mapping
          const productDoc = await Product.findById(orderProduct.productId);
          let dispensedQuantity = 0;
          
          if (productDoc && productDoc.chariotId) {
            const chariot = await require('../models/chariot.model').findById(productDoc.chariotId);
            if (chariot) {
              // Extract chariot number from name (e.g., "CHARIOT1" -> 1)
              const chariotNumber = parseInt(chariot.name.replace(/\D/g, ''));
              
              if (!isNaN(chariotNumber)) {
                dispensedQuantity = dispensingStatus.details
                  ? dispensingStatus.details
                      .filter(detail => detail.couloir === chariotNumber)
                      .reduce((sum, detail) => sum + detail.detectedCount, 0)
                  : Math.floor((totalDispensed * orderProduct.quantity) / totalExpected); // Fallback if no detailed info
              }
            }
          }
          
          // If we couldn't get chariot mapping, use proportional fallback
          if (dispensedQuantity === 0 && !dispensingStatus.details) {
            dispensedQuantity = Math.floor((totalDispensed * orderProduct.quantity) / totalExpected);
          }
          
          // Only charge for the quantity that was actually dispensed
          const actualDispensedForProduct = Math.min(dispensedQuantity, orderProduct.quantity);
          paymentAmount += orderProduct.price * actualDispensedForProduct;
          
          console.log(`Product ${productDoc?.name}: expected ${orderProduct.quantity}, dispensed ${actualDispensedForProduct}, charged ${(orderProduct.price * actualDispensedForProduct).toFixed(2)} DA`);
        }
        console.log(`Partial dispensing: Charging ${paymentAmount.toFixed(2)} DA for actually dispensed products (was ${order.totalAmount.toFixed(2)} DA)`);
      }
      
      // Check balance against the calculated payment amount
      if (wallet.balance < paymentAmount) {
        order.status = 'FAILED';
        order.failureReason = 'Insufficient funds';
        await order.save();
        
        // Create notification for insufficient funds
        const insufficientFundsNotification = new NotificationModel({
          userId: order.userId,
          title: 'Paiement échoué',
          message: `Solde insuffisant pour votre commande de ${paymentAmount.toFixed(2)} DA.`,
          type: 'ORDER',
          orderId: order._id,
          priority: 5,
          status: 'UNREAD',
        });
        await insufficientFundsNotification.save();
        
        return res.status(400).json({ message: 'Insufficient funds' });
      }
      
      // Now actually deduct the calculated amount
      wallet.balance -= paymentAmount;
      
      // Save transaction history
      wallet.transactions.push({
        type: "PAYMENT",
        amount: -paymentAmount,
        date: new Date(),
        orderId: order._id,
        description: isPartialDispensing ? `Paiement partiel (${totalDispensed}/${totalExpected} produits)` : 'Paiement complet'
      });
        await wallet.save();
        // Check for existing payment notification to prevent duplicates
      const existingPaymentNotification = await NotificationModel.findOne({
        orderId: order._id,
        title: 'Paiement effectué',
        type: 'TRANSACTION'
      });
        // Only create payment notification if one doesn't already exist
      if (!existingPaymentNotification) {        // Create appropriate notification based on dispensing status
        let notificationTitle, notificationMessage, notificationProducts = order.products;
        
        if (isPartialDispensing) {
          notificationTitle = 'Paiement partiel effectué';
          
          // Build detailed message with specific undispensed products
          let undispensedDetails = [];
          for (const orderProduct of order.products) {
            // Find dispensing details for this product's chariot
            const productDoc = await Product.findById(orderProduct.productId);
            if (productDoc && productDoc.chariotId) {
              const chariot = await require('../models/chariot.model').findById(productDoc.chariotId);
              if (chariot) {
                const chariotNumber = parseInt(chariot.name.replace(/\D/g, ''));
                const dispensedForProduct = details?.details
                  ? details.details
                      .filter(detail => detail.couloir === chariotNumber)
                      .reduce((sum, detail) => sum + detail.detectedCount, 0)
                  : Math.floor((totalDispensed * orderProduct.quantity) / totalExpected);
                
                const expectedQuantity = orderProduct.quantity;
                const actualDispensed = Math.min(dispensedForProduct, expectedQuantity);
                
                if (actualDispensed < expectedQuantity) {
                  const missing = expectedQuantity - actualDispensed;
                  undispensedDetails.push(`${productDoc.name}: ${missing} manquant(s)`);
                }
              }
            }
          }
          
          if (undispensedDetails.length > 0) {
            notificationMessage = `Distribution partielle détectée. Produits non distribués:\n${undispensedDetails.join('\n')}\n\nVous n'avez été facturé que ${paymentAmount.toFixed(2)} DA pour les produits reçus.`;
          } else {
            notificationMessage = `Il y a eu une erreur lors de la distribution de tous les produits, mais ne vous inquiétez pas, nous n'avons débité que le paiement pour les produits distribués (${paymentAmount.toFixed(2)} DA pour ${totalDispensed}/${totalExpected} produits).`;
          }
        } else {
          notificationTitle = 'Paiement effectué';
          notificationMessage = `Votre paiement de ${paymentAmount.toFixed(2)} DA a été effectué avec succès.`;
        }        
        const paymentNotification = new NotificationModel({
          userId: order.userId,
          title: notificationTitle,
          message: notificationMessage,
          type: 'TRANSACTION',
          amount: -paymentAmount,
          orderId: order._id,
          products: notificationProducts,
        });
        await paymentNotification.save();
        console.log(`Payment notification created for order ${order._id} - Partial: ${isPartialDispensing}`);
      } else {
        console.log(`Payment notification already exists for order ${order._id}, skipping duplicate`);
      }
    }

    await order.save();

    res.status(200).json({
      message: 'Order dispensing completed successfully',
      order: {
        id: order._id,
        status: order.status,
        products: order.products
      }
    });
  } catch (error) {
    console.error('Error completing order dispensing:', error);
    res.status(500).json({ message: 'Error completing order dispensing' });
  }
};
