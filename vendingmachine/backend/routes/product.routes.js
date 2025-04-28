// filepath: c:\Users\Khobz\Documents\Projects\Flutter\vendingmachine\backend\routes\product.routes.js
const express = require('express');
const {
    addProduct,
    getProducts,
    updateProduct,
    deleteProduct,
} = require('../controllers/product.controllers');

const router = express.Router();

// Routes simplifiées sans multer
router.get('/', getProducts);
router.post('/', addProduct);
router.put('/:id', updateProduct);
router.delete('/:id', deleteProduct);

module.exports = router;
