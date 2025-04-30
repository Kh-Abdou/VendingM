const CodeModel = require("../models/code.model");
const NotificationModel = require("../models/notification.model");
const OrderModel = require("../models/order.model");

// Generate a new code
module.exports.generateCode = async (req, res) => {
  try {
    const { userId, products, totalAmount } = req.body;
    
    // Generate a random 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Set expiry time (5 minutes from now)
    const expiryTime = new Date();
    expiryTime.setMinutes(expiryTime.getMinutes() + 5);
    
    // Create order
    const order = new OrderModel({
      userId,
      products,
      totalAmount,
      paymentMethod: "CODE",
      code,
      codeExpiryTime: expiryTime,
      codeStatus: "ACTIVE",
    });
    
    await order.save();
    
    // Create notification
    const notification = new NotificationModel({
      userId,
      title: "Code généré",
      message: "Code généré pour votre commande",
      type: "CODE",
      code,
      codeStatus: "GENERATED",
      codeExpiryTime: expiryTime,
      products,
      amount: totalAmount,
      orderId: order._id,
    });
    
    await notification.save();
    
    // Schedule expiration check
    setTimeout(async () => {
      try {
        const orderCheck = await OrderModel.findById(order._id);
        if (orderCheck && orderCheck.codeStatus === "ACTIVE") {
          // Update order status
          orderCheck.codeStatus = "EXPIRED";
          orderCheck.status = "CANCELED";
          await orderCheck.save();
          
          // Create expiration notification
          const expirationNotification = new NotificationModel({
            userId,
            title: "Code expiré",
            message: "Votre code a expiré",
            type: "CODE",
            code,
            codeStatus: "EXPIRED",
            orderId: order._id,
          });
          
          await expirationNotification.save();
        }
      } catch (error) {
        console.error("Error in expiration check:", error);
      }
    }, 300000); // 5 minutes
    
    res.status(201).json({
      code,
      expiryTime,
      order: order._id,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Validate a code (used by vending machine)
module.exports.validateCode = async (req, res) => {
  try {
    const { code, vendingMachineId } = req.body;
    
    if (!code || !vendingMachineId) {
      return res.status(400).json({
        message: "Code and vending machine ID are required",
      });
    }
    
    // Find the order with this code
    const order = await OrderModel.findOne({
      code,
      codeStatus: "ACTIVE",
    }).populate("products.productId");
    
    if (!order) {
      return res.status(404).json({
        message: "Invalid or expired code",
      });
    }
    
    // Check if code is expired
    if (new Date() > order.codeExpiryTime) {
      order.codeStatus = "EXPIRED";
      order.status = "CANCELED";
      await order.save();
      
      // Create expiration notification
      const notification = new NotificationModel({
        userId: order.userId,
        title: "Code expiré",
        message: "Votre code a expiré",
        type: "CODE",
        code,
        codeStatus: "EXPIRED",
        orderId: order._id,
      });
      
      await notification.save();
      
      return res.status(400).json({
        message: "Code expired",
      });
    }
    
    // Update order status
    order.codeStatus = "USED";
    order.status = "COMPLETED";
    order.vendingMachineId = vendingMachineId;
    order.dispensedAt = new Date();
    await order.save();
    
    // Create usage notification
    const notification = new NotificationModel({
      userId: order.userId,
      title: "Code utilisé",
      message: "Votre code a été utilisé avec succès",
      type: "CODE",
      code,
      codeStatus: "USED",
      vendingMachineId,
      orderId: order._id,
    });
    
    await notification.save();
    
    res.status(200).json({
      message: "Code validated successfully",
      products: order.products,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};