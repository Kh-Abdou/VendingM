const express = require('express');
const router = express.Router();
const {
    processOrder,
    completeOrder,
    getPendingOrders
} = require('../controllers/order.controllers');

// Process a new order
router.post('/', processOrder);

// Get pending orders for a vending machine
router.get('/pending', getPendingOrders);

// Complete an order (called by hardware when items are detected)
router.post('/complete', completeOrder);

module.exports = router;
