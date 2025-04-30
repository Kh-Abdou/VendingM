const EWalletModel = require("../models/ewallet.model");
const UserModel = require("../models/user.model");
const NotificationModel = require("../models/notification.model");
const OrderModel = require("../models/order.model"); // Add this import

// This function might be missing or not exported
module.exports.getBalance = async (req, res) => {
  try {
    const userId = req.params.userId;
    
    if (!userId) {
      return res.status(400).json({
        message: "User ID is required",
      });
    }
    
    const wallet = await EWalletModel.findOne({ userId });
    
    if (!wallet) {
      return res.status(200).json({
        balance: 0,
        transactions: []
      });
    }
    
    res.status(200).json({
      balance: wallet.balance,
      transactions: wallet.transactions.slice(0, 10) // Latest 10 transactions
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// The rest of your controller code...
module.exports.addFunds = async (req, res) => {
  try {
    const { userId, amount } = req.body;
    
    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({
        message: "User ID and positive amount are required",
      });
    }
    
    // Find or create e-wallet
    let wallet = await EWalletModel.findOne({ userId });
    
    if (!wallet) {
      wallet = new EWalletModel({
        userId,
        balance: amount,
      });
    } else {
      wallet.balance += amount;
    }
    
    // Save transaction history
    wallet.transactions.push({
      type: "DEPOSIT",
      amount,
      date: new Date(),
    });
    
    await wallet.save();
    
    // Create notification
    const notification = new NotificationModel({
      userId,
      title: "Solde rechargé",
      message: `Votre solde a été rechargé de ${amount.toFixed(2)} DA`,
      type: "TRANSACTION",
      amount,
    });
    
    await notification.save();
    
    res.status(200).json({
      message: "Funds added successfully",
      balance: wallet.balance,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports.processPayment = async (req, res) => {
  try {
    const { userId, amount, products } = req.body;
    
    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({
        message: "User ID and positive amount are required",
      });
    }
    
    // Find e-wallet
    const wallet = await EWalletModel.findOne({ userId });
    
    if (!wallet) {
      return res.status(404).json({
        message: "E-wallet not found",
      });
    }
    
    // Check balance
    if (wallet.balance < amount) {
      return res.status(400).json({
        message: "Insufficient funds",
      });
    }
    
    // Deduct amount
    wallet.balance -= amount;
    
    // Save transaction history
    wallet.transactions.push({
      type: "PAYMENT",
      amount: -amount,
      date: new Date(),
    });
    
    await wallet.save();
    
    // Create order
    const order = new OrderModel({
      userId,
      products,
      totalAmount: amount,
      paymentMethod: "EWALLET",
      status: "COMPLETED",
    });
    
    await order.save();
    
    // Create notification
    const notification = new NotificationModel({
      userId,
      title: "Paiement effectué",
      message: `Votre paiement de ${amount.toFixed(2)} DA a été effectué`,
      type: "TRANSACTION",
      amount: -amount,
      orderId: order._id,
      products,
    });
    
    await notification.save();
    
    res.status(200).json({
      message: "Payment processed successfully",
      balance: wallet.balance,
      orderId: order._id,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports.getTransactionHistory = async (req, res) => {
  // Implementation...
};