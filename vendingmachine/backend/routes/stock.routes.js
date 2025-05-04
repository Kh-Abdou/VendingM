const express = require('express');
const router = express.Router();
const {
  getAllStocks,
  getStockById,
  getStocksByLocation,
  createStock,
  updateStock,
  deleteStock,
  getLowStocks,
  adjustStock
} = require('../controllers/stock.controllers');

// Obtenir tous les stocks
router.get('/', getAllStocks);

// Obtenir les stocks à niveau bas
router.get('/low-stock', getLowStocks);

// Obtenir les stocks par emplacement
router.get('/location/:location', getStocksByLocation);

// Obtenir un stock spécifique par ID
router.get('/:id', getStockById);

// Créer un nouveau stock
router.post('/', createStock);

// Mettre à jour un stock existant
router.put('/:id', updateStock);

// Ajuster la quantité de stock (augmenter ou diminuer)
router.patch('/:id/adjust', adjustStock);

// Supprimer un stock
router.delete('/:id', deleteStock);

module.exports = router;