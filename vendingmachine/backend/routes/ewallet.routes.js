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

// Add this route to get the transaction history
router.post('/add-funds', ewalletControllers.addFunds);
module.exports = router;