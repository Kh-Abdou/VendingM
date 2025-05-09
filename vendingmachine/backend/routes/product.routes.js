// filepath: c:\Users\Khobz\Documents\Projects\Flutter\vendingmachine\backend\routes\product.routes.js
const express = require('express');
const {
    addProduct,
    getProducts,
    getProductWithStock,
    updateProduct,
    deleteProduct,
    getOutOfStockProducts,
    getProductsWithStock
} = require('../controllers/product.controllers');
const upload = require('../middlewares/upload');

const router = express.Router();

// Obtenir tous les produits
router.get('/', getProducts);

// Obtenir tous les produits avec leur stock
router.get('/with-stock', getProductsWithStock);

// Obtenir les produits en rupture de stock
router.get('/out-of-stock', getOutOfStockProducts);

// Obtenir un produit spécifique avec ses informations de stock
router.get('/:id/stock', getProductWithStock);

// Routes de base pour les produits - Added upload.single('image') middleware
router.post('/', upload.single('image'), addProduct);
router.put('/:id', upload.single('image'), updateProduct);
router.delete('/:id', deleteProduct);

module.exports = router;
