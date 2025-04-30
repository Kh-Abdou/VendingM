const Product = require('../models/product.model'); // Assurez-vous d'avoir un modèle Product

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

// Mettre à jour un produit
exports.updateProduct = async (req, res) => {
    try {
        const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!product) {
            return res.status(404).json({ error: 'Produit non trouvé' });
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

        product.quantity = quantity;
        await product.save();

        res.status(200).json(product);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// Supprimer un produit
exports.deleteProduct = async (req, res) => {
    try {
        const product = await Product.findByIdAndDelete(req.params.id);
        if (!product) {
            return res.status(404).json({ error: 'Produit non trouvé' });
        }
        res.status(200).json({ message: 'Produit supprimé avec succès' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};