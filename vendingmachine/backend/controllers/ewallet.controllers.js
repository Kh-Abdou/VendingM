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
      await wallet.save();    // Create order 
    const order = new OrderModel({
      userId,
      products,
      totalAmount: amount,
      paymentMethod: "EWALLET",
      status: "PENDING", // Changed from COMPLETED to PENDING for dispenser to pick up
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

module.exports.processCardPayment = async (req, res) => {
  try {
    const { userId, amount, products, paymentMethod } = req.body;
    
    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({
        message: "User ID et montant positif sont requis",
      });    }    // Créer une commande en attente de distribution
    const order = new OrderModel({
      userId,
      products,
      totalAmount: amount,
      paymentMethod: "CARD",
      status: "PENDING", // Changed from COMPLETED to PENDING for dispenser to pick up
    });
    
    await order.save();
    
    // Créer une notification pour informer l'utilisateur du paiement
    const userNotification = new NotificationModel({
      userId,
      title: "Paiement par carte effectué",
      message: `Votre paiement par carte de ${amount.toFixed(2)} DA a été effectué avec succès`,
      type: "TRANSACTION",
      amount: -amount,
      orderId: order._id,
      products,
      priority: "HIGH", // Haute priorité pour les paiements
      status: "UNREAD",
    });
    
    await userNotification.save();
    
    // Créer une notification pour le technicien
    // Trouver les techniciens dans le système
    const technicians = await UserModel.find({ role: "technician" });
    
    // Si des techniciens existent, envoyez-leur des notifications
    if (technicians.length > 0) {
      const promises = technicians.map(async tech => {
        const techNotification = new NotificationModel({
          userId: tech._id,
          title: "Nouvelle commande reçue",
          message: `Un client a effectué une commande de ${amount.toFixed(2)} DA payée par carte`,
          type: "ORDER",
          amount,
          orderId: order._id,
          priority: "MEDIUM",
          status: "UNREAD",
        });
        
        return techNotification.save();
      });
      
      await Promise.all(promises);
    }
    
    res.status(200).json({
      message: "Paiement par carte traité avec succès",
      orderId: order._id,
    });
  } catch (err) {
    console.error("Erreur lors du traitement du paiement par carte:", err);
    res.status(500).json({ message: err.message });
  }
};

module.exports.getTransactionHistory = async (req, res) => {
  // Implementation...
};

// Export all functions
module.exports = {
  getBalance: module.exports.getBalance,
  addFunds: module.exports.addFunds,
  processPayment: module.exports.processPayment,
  getTransactionHistory: module.exports.getTransactionHistory,
  processCardPayment: module.exports.processCardPayment
};