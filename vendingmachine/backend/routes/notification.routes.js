const express = require("express");
const router = express.Router();
const { 
  getUserNotifications,
  markNotificationsAsRead,
  createTransactionNotification,
  createCodeNotification,
  createMaintenanceNotification,
  updateCodeNotification,
  getUnreadCount,
  deleteOldNotifications
} = require("../controllers/notification.controllers");

// Get user notifications
router.get("/:userId", getUserNotifications);

// Get unread notifications count
router.get("/count/:userId", getUnreadCount);

// Mark notifications as read
router.put("/mark-read", markNotificationsAsRead);

// Create transaction notification
router.post("/transaction", createTransactionNotification);

// Create code notification
router.post("/code", createCodeNotification);

// Create maintenance notification
router.post("/maintenance", createMaintenanceNotification);

// Update code notification
router.put("/code", updateCodeNotification);

// Delete old notifications (admin only)
router.delete("/cleanup", deleteOldNotifications);

module.exports = router;