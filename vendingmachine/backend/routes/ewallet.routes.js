const express = require("express");
const router = express.Router();
const {
  getBalance,
  addFunds,
  processPayment,
  processCardPayment,
  getTransactionHistory
} = require("../controllers/ewallet.controllers");

// Define your routes
router.get("/:userId", getBalance);
router.post("/add-funds", addFunds);
router.post("/payment", processPayment);
router.post("/card-payment", processCardPayment); // Nouvelle route pour les paiements par carte
router.get("/transactions/:userId", getTransactionHistory);

module.exports = router;