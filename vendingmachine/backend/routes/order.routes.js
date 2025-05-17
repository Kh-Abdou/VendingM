const express = require('express');
const router = express.Router();
const {
    processOrder,
    completeOrder,
    getPendingOrders
} = require('../controllers/order.controllers');
const { getOrderStatus } = require('../controllers/order.status.controllers');
const { handleOrderFailure } = require('../controllers/order.failure.controllers');

// Process a new order
router.post('/', processOrder);

// Get pending orders for a vending machine
router.get('/pending', getPendingOrders);

// Complete an order (called by hardware when items are detected)
router.post('/complete', completeOrder);

// Get order status including product detection status
router.get('/status/:orderId', getOrderStatus);

// Handle order failure from ESP32
router.post('/fail', handleOrderFailure);

module.exports = router;
