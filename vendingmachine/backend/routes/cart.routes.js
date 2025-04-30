const express = require('express');
const cartController = require('../controllers/cart.controllers');

// filepath: c:\Users\Khobz\Documents\Projects\PFE\vendingmachine\backend\routes\cart.routes.js
const router = express.Router();

// Create a new cart
router.post('/', cartController.createCart);

// Get cart by ID
router.get('/:id', cartController.getCartById);

// Update cart
router.put('/:id', cartController.updateCart);

// Delete cart
router.delete('/:id', cartController.deleteCart);

module.exports = router;