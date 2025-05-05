const NotificationModel = require("../models/notification.model");
const UserModel = require("../models/user.model");

// Get all notifications for a user with pagination
module.exports.getUserNotifications = async (req, res) => {
  try {
    const userId = req.params.userId;
    const { page = 1, limit = 20, type, status } = req.query;
    const skip = (page - 1) * limit;

    const query = { userId };
    
    // Filter by type if provided
    if (type) {
      query.type = type;
    }
    
    // Filter by status if provided
    if (status) {
      query.status = status;
    }

    const notifications = await NotificationModel.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .exec();

    const total = await NotificationModel.countDocuments(query);

    res.status(200).json({
      notifications,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      totalItems: total,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Mark notifications as read
module.exports.markNotificationsAsRead = async (req, res) => {
  try {
    const { userId, notificationIds } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "User ID is required" });
    }

    let query = { userId };
    
    // If specific notification IDs are provided, only mark those as read
    if (notificationIds && notificationIds.length > 0) {
      query._id = { $in: notificationIds };
    }

    const result = await NotificationModel.updateMany(
      query,
      { $set: { status: "READ" } }
    );

    res.status(200).json({
      message: `${result.modifiedCount} notifications marked as read`,
      modifiedCount: result.modifiedCount,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a transaction notification
module.exports.createTransactionNotification = async (req, res) => {
  try {
    const { userId, title, message, amount, orderId, products } = req.body;

    const notification = new NotificationModel({
      userId,
      title,
      message,
      type: "TRANSACTION",
      amount,
      orderId,
      products,
    });

    await notification.save();
    res.status(201).json(notification);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a code notification
module.exports.createCodeNotification = async (req, res) => {
  try {
    const {
      userId,
      title,
      message,
      code,
      codeStatus,
      codeExpiryTime,
      vendingMachineId,
      products,
      amount,
      orderId,
    } = req.body;

    const notification = new NotificationModel({
      userId,
      title,
      message,
      type: "CODE",
      code,
      codeStatus,
      codeExpiryTime,
      vendingMachineId,
      products,
      amount,
      orderId,
    });

    await notification.save();
    res.status(201).json(notification);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a maintenance notification (for technicians)
module.exports.createMaintenanceNotification = async (req, res) => {
  try {
    const { title, message, vendingMachineId, priority, metadata } = req.body;

    // Utiliser "technician" en minuscules pour correspondre à la base de données
    const technicians = await UserModel.find({ role: "technician" });

    if (technicians.length === 0) {
      return res.status(404).json({ message: "No technicians found" });
    }

    // Si un userId spécifique est fourni, utiliser celui-là au lieu d'envoyer à tous les techniciens
    const notifications = [];
    const targetTechnicians = req.body.userId ? 
      technicians.filter(tech => tech._id.toString() === req.body.userId) : 
      technicians;

    // Créer une notification pour chaque technicien
    for (const technician of targetTechnicians) {
      const notification = new NotificationModel({
        userId: technician._id,
        title,
        message,
        type: "MAINTENANCE",
        vendingMachineId,
        priority: priority || 3, // Priorité par défaut si non fournie
        metadata,
      });

      await notification.save();
      notifications.push(notification);
    }

    res.status(201).json({
      message: `Maintenance notifications sent to ${notifications.length} technicians`,
      notifications,
    });
  } catch (err) {
    console.error("Error creating maintenance notification:", err);
    res.status(500).json({ message: err.message });
  }
};

// Create a stock notification (for low stock items)
module.exports.createStockNotification = async (req, res) => {
  try {
    const { title, message, stockId, productName, quantity, threshold, priority, location } = req.body;

    // Find technician users who should receive stock notifications
    const technicians = await UserModel.find({ role: "technician" });

    if (technicians.length === 0) {
      return res.status(404).json({ message: "No technicians found" });
    }

    const notifications = [];

    // Determine notification priority based on stock level
    let stockPriority = priority;
    if (!stockPriority) {
      if (quantity === 0) {
        stockPriority = 5; // Critical - out of stock
      } else if (quantity <= Math.ceil(threshold / 3)) {
        stockPriority = 4; // High - very low stock
      } else if (quantity <= threshold) {
        stockPriority = 3; // Medium - low stock
      } else {
        stockPriority = 2; // Low - normal stock
      }
    }

    // Create a notification for each technician
    for (const technician of technicians) {
      const notification = new NotificationModel({
        userId: technician._id,
        title: title || "Niveau de stock",
        message: message || `Le produit ${productName} est presque épuisé (${quantity} restants)`,
        type: "STOCK",
        priority: stockPriority,
        metadata: {
          stockId,
          quantity,
          threshold,
          location,
          productName
        }
      });

      await notification.save();
      notifications.push(notification);
    }

    res.status(201).json({
      message: `Stock notifications sent to ${notifications.length} technicians`,
      notifications,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update a code notification status (used, expired, etc.)
module.exports.updateCodeNotification = async (req, res) => {
  try {
    const { code, codeStatus, deviceInfo, vendingMachineId } = req.body;

    if (!code) {
      return res.status(400).json({ message: "Code is required" });
    }

    const notification = await NotificationModel.findOne({
      code,
      type: "CODE",
    });

    if (!notification) {
      return res.status(404).json({ message: "Notification not found" });
    }

    notification.codeStatus = codeStatus || notification.codeStatus;
    notification.deviceInfo = deviceInfo || notification.deviceInfo;
    notification.vendingMachineId = vendingMachineId || notification.vendingMachineId;

    if (codeStatus === "USED") {
      notification.message = "Votre code a été utilisé avec succès";
    } else if (codeStatus === "EXPIRED") {
      notification.message = "Votre code a expiré";
    }

    await notification.save();
    res.status(200).json(notification);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get unread notifications count
module.exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.params.userId;
    
    const count = await NotificationModel.countDocuments({
      userId,
      status: "UNREAD",
    });
    
    res.status(200).json({ count });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Delete old notifications (cleanup task)
module.exports.deleteOldNotifications = async (req, res) => {
  try {
    const { days = 90 } = req.query;  // Default to 90 days
    
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(days));
    
    const result = await NotificationModel.deleteMany({
      createdAt: { $lt: cutoffDate },
    });
    
    res.status(200).json({
      message: `${result.deletedCount} old notifications deleted`,
      deletedCount: result.deletedCount,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};