const Product = require('../models/product.model'); // Assurez-vous d'avoir un modèle Product
const Stock = require('../models/stock.model');
const mongoose = require('mongoose');

// Ajouter un produit
exports.addProduct = async (req, res) => {
    try {
        const product = new Product(req.body);
        await product.save();
        res.status(201).json(product);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// Consulter tous les produits
exports.getProducts = async (req, res) => {
    try {
        const products = await Product.find();
        res.status(200).json(products);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Obtenir un produit avec ses informations de stock
exports.getProductWithStock = async (req, res) => {
    try {
        const { id } = req.params;
        
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: 'ID de produit invalide' });
        }
        
        const product = await Product.findById(id);
        
        if (!product) {
            return res.status(404).json({ error: 'Produit non trouvé' });
        }
        
        // Récupérer les stocks pour ce produit
        const stocks = await Stock.find({ product: id });
        
        // Calculer la quantité totale disponible
        const totalQuantity = stocks.reduce((sum, stock) => sum + stock.quantity, 0);
        
        res.status(200).json({
            ...product.toObject(),
            totalStock: totalQuantity,
            stocks: stocks
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Mettre à jour un produit
exports.updateProduct = async (req, res) => {
    try {
        const { quantity } = req.body;
        const previousProduct = await Product.findById(req.params.id);
        
        if (!previousProduct) {
            return res.status(404).json({ error: 'Produit non trouvé' });
        }
        
        const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
        
        // Si la quantité a été modifiée, vérifier les seuils de stock
        if (quantity !== undefined && quantity !== previousProduct.quantity) {
            await checkStockThresholds(product, quantity);
        }
        
        res.status(200).json(product);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// Mettre à jour la quantité d'un produit
exports.updateProductQuantity = async (req, res) => {
    try {
        const { quantity } = req.body;
        if (quantity === undefined) {
            return res.status(400).json({ error: 'La quantité est requise' });
        }

        const product = await Product.findById(req.params.id);
        if (!product) {
            return res.status(404).json({ error: 'Produit non trouvé' });
        }

        const previousQuantity = product.quantity;
        product.quantity = quantity;
        await product.save();

        // Vérifier les seuils de stock et envoyer des notifications si nécessaire
        if (quantity !== previousQuantity) {
            await checkStockThresholds(product, quantity);
        }

        res.status(200).json(product);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// Supprimer un produit et tous les stocks associés
exports.deleteProduct = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
    
    try {
        const { id } = req.params;
        
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ error: 'ID de produit invalide' });
        }
        
        // Supprimer le produit
        const product = await Product.findByIdAndDelete(id, { session });
        
        if (!product) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({ error: 'Produit non trouvé' });
        }
        
        // Supprimer tous les stocks associés à ce produit
        await Stock.deleteMany({ product: id }, { session });
        
        await session.commitTransaction();
        session.endSession();
        
        res.status(200).json({ 
            message: 'Produit et stocks associés supprimés avec succès',
            productId: id
        });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        res.status(500).json({ error: error.message });
    }
};

// Obtenir les produits en rupture de stock (quantité totale = 0)
exports.getOutOfStockProducts = async (req, res) => {
    try {
        // Obtenir tous les produits
        const products = await Product.find({ isActive: true });
        
        // Pour chaque produit, vérifier s'il a un stock
        const outOfStockProducts = [];
        
        for (const product of products) {
            // Calculer la quantité totale du produit à travers tous les emplacements
            const stocks = await Stock.find({ product: product._id });
            const totalQuantity = stocks.reduce((sum, stock) => sum + stock.quantity, 0);
            
            if (totalQuantity === 0) {
                outOfStockProducts.push({
                    ...product.toObject(),
                    totalStock: 0
                });
            }
        }
        
        res.status(200).json(outOfStockProducts);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Obtenir les produits avec leur stock total
exports.getProductsWithStock = async (req, res) => {
    try {
        // Récupérer tous les produits
        const products = await Product.find();
        
        // Résultats à retourner
        const productsWithStock = [];
        
        // Pour chaque produit, calculer le stock total
        for (const product of products) {
            const stocks = await Stock.find({ product: product._id });
            const totalQuantity = stocks.reduce((sum, stock) => sum + stock.quantity, 0);
            
            productsWithStock.push({
                ...product.toObject(),
                totalStock: totalQuantity,
                stockLocations: stocks.map(stock => ({
                    id: stock._id,
                    location: stock.location,
                    quantity: stock.quantity,
                    isLowStock: stock.isLowStock
                }))
            });
        }
        
        res.status(200).json(productsWithStock);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Fonction pour vérifier les seuils de stock et envoyer des notifications
async function checkStockThresholds(product, quantity) {
    try {
        const axios = require('axios');
        
        let title, message, priority;
        
        if (quantity === 0) {
            title = 'Stock épuisé';
            message = `Le produit ${product.name} est épuisé (0 unité)`;
            priority = 5; // Critique
        } else if (quantity <= 2) {
            title = 'Stock critique';
            message = `Le produit ${product.name} est critique (${quantity} unité${quantity > 1 ? 's' : ''})`;
            priority = 5; // Critique
        } else if (quantity <= 4) {
            title = 'Stock faible détecté';
            message = `Le produit ${product.name} est bas (${quantity} unités)`;
            priority = 3; // Normal
        } else {
            // Pas besoin de notification
            return;
        }
        
        // Envoyer la notification
        await axios.post('http://localhost:5000/notification/stock', {
            title,
            message,
            productName: product.name,
            currentStock: quantity,
            priority
        });
        
        console.log(`Notification envoyée pour le produit ${product.name} avec quantité ${quantity}`);
    } catch (error) {
        console.error('Erreur lors de l\'envoi de la notification:', error);
        // Ne pas bloquer l'opération principale en cas d'erreur avec les notifications
    }
}