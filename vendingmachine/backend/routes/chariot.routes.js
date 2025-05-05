const express = require('express');
const router = express.Router();
const {
    getAllChariots,
    getChariotById,
    createChariot,
    updateChariot,
    deleteChariot,
    addProductToChariot,
    removeProductFromChariot,
    getChariotsByProductType,
    emptyChariot
} = require('../controllers/chariot.controllers');

// Obtenir tous les chariots
router.get('/', getAllChariots);

// Obtenir les chariots par type de produit
router.get('/by-product-type/:productType', getChariotsByProductType);

// Obtenir un chariot spécifique par ID
router.get('/:id', getChariotById);

// Créer un nouveau chariot
router.post('/', createChariot);

// Mettre à jour un chariot existant
router.put('/:id', updateChariot);

// Ajouter un produit à un chariot
router.post('/:id/products', addProductToChariot);

// Retirer un produit d'un chariot
router.delete('/:id/products/:productId', removeProductFromChariot);

// Vider un chariot (retirer tous les produits)
router.post('/:id/empty', emptyChariot);

// Supprimer un chariot
router.delete('/:id', deleteChariot);

module.exports = router;