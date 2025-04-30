const express = require("express");
const router = express.Router();
const {
  getBalance,
  addFunds,
  processPayment,
  getTransactionHistory
} = require("../controllers/ewallet.controllers"); // Note the "s" at the end

// Define your routes
router.get("/:userId", getBalance);
router.post("/add-funds", addFunds);
router.post("/payment", processPayment);
router.get("/transactions/:userId", getTransactionHistory);

module.exports = router;