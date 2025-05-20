const Chariot = require('../models/chariot.model');
const Product = require('../models/product.model');
const mongoose = require('mongoose');

// Obtenir tous les chariots
exports.getAllChariots = async (req, res) => {    try {
        const chariots = await Chariot.find()
            .populate({
                path: 'currentProducts',
                model: 'product',
                select: 'name price quantity'
            })
            .sort({ name: 1 });
        
        res.status(200).json(chariots);
    } catch (error) {
        console.error('Erreur lors de la récupération des chariots:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des chariots' });
    }
};

// Obtenir un chariot par ID
exports.getChariotById = async (req, res) => {
    const { id } = req.params;
    
    // Vérifier si l'ID est valide
    if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'ID de chariot invalide' });
    }
    
    try {
        const chariot = await Chariot.findById(id)
            .populate('currentProducts', 'name price quantity');
        
        if (!chariot) {
            return res.status(404).json({ message: 'Chariot non trouvé' });
        }
        
        res.status(200).json(chariot);
    } catch (error) {
        console.error('Erreur lors de la récupération du chariot:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération du chariot' });
    }
};

// Créer un nouveau chariot
exports.createChariot = async (req, res) => {
    const { name, capacity } = req.body;
    
    // Vérifier les données requises
    if (!name) {
        return res.status(400).json({ message: 'Le nom du chariot est requis' });
    }
    
    try {
        // Vérifier si un chariot avec ce nom existe déjà
        const existingChariot = await Chariot.findOne({ name: name.trim() });
        if (existingChariot) {
            return res.status(400).json({ 
                message: 'Un chariot avec ce nom existe déjà',
                existingChariotId: existingChariot._id
            });
        }
        
        // Vérifier la capacité
        const chariotCapacity = capacity || 10;
        if (chariotCapacity < 1) {
            return res.status(400).json({ message: 'La capacité du chariot doit être d\'au moins 1' });
        }
        
        const newChariot = new Chariot({
            name: name.trim(),
            capacity: chariotCapacity,
            status: 'Disponible',
            currentProductType: null,
            currentProducts: []
        });
        
        await newChariot.save();
        res.status(201).json(newChariot);
    } catch (error) {
        console.error('Erreur lors de la création du chariot:', error);
        res.status(500).json({ message: 'Erreur lors de la création du chariot' });
    }
};

// Mettre à jour un chariot
exports.updateChariot = async (req, res) => {
    const { id } = req.params;
    const { name, capacity, status } = req.body;
    
    // Vérifier si l'ID est valide
    if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'ID de chariot invalide' });
    }
    
    try {
        // Vérifier si le chariot existe
        const chariot = await Chariot.findById(id);
        if (!chariot) {
            return res.status(404).json({ message: 'Chariot non trouvé' });
        }
        
        // Mettre à jour les champs fournis
        if (name) chariot.name = name;
        if (capacity) chariot.capacity = capacity;
        if (status && ['Disponible', 'Complet', 'Occupé'].includes(status)) {
            chariot.status = status;
        }
        
        await chariot.save();
        res.status(200).json(chariot);
    } catch (error) {
        console.error('Erreur lors de la mise à jour du chariot:', error);
        res.status(500).json({ message: 'Erreur lors de la mise à jour du chariot' });
    }
};

// Ajouter un produit à un chariot
exports.addProductToChariot = async (req, res) => {
    const { id } = req.params;
    const { productId } = req.body;
    
    // Vérifier si les IDs sont valides
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(productId)) {
        return res.status(400).json({ message: 'IDs invalides' });
    }
    
    try {
        // Vérifier d'abord si le chariot peut accueillir un produit supplémentaire
        const canAdd = await Chariot.canAddProduct(id);
        if (!canAdd) {
            return res.status(400).json({ 
                message: 'Impossible d\'ajouter le produit : la capacité maximale du chariot est atteinte',
                error: 'CAPACITY_EXCEEDED'
            });
        }
        
        // Récupérer le chariot et le produit
        const chariot = await Chariot.findById(id).populate('currentProducts', 'name');
        const product = await Product.findById(productId);
        
        if (!chariot) {
            return res.status(404).json({ message: 'Chariot non trouvé' });
        }
        
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        
        // Vérification supplémentaire de la capacité (double validation)
        if (chariot.currentProducts.length >= chariot.capacity) {
            return res.status(400).json({ 
                message: `Impossible d'ajouter le produit : la capacité maximale du chariot (${chariot.capacity}) est atteinte`,
                currentCount: chariot.currentProducts.length,
                maxCapacity: chariot.capacity,
                error: 'CAPACITY_EXCEEDED'
            });
        }
        
        // Vérifier si le produit est déjà dans le chariot
        const productExists = chariot.currentProducts.some(p => p._id.toString() === productId);
        if (productExists) {
            return res.status(400).json({ 
                message: 'Ce produit est déjà dans le chariot',
                error: 'PRODUCT_ALREADY_IN_CHARIOT'
            });
        }
        
        // Vérifier si le chariot contient déjà un autre type de produit
        if (chariot.currentProducts.length > 0 && chariot.currentProductType !== product.name) {
            return res.status(400).json({ 
                message: 'Le chariot contient déjà un type de produit différent',
                currentType: chariot.currentProductType,
                error: 'DIFFERENT_PRODUCT_TYPE'
            });
        }
        
        // Si le chariot est vide, définir le type de produit
        if (chariot.currentProducts.length === 0) {
            chariot.currentProductType = product.name;
        }
        
        // Ajouter le produit au chariot
        chariot.currentProducts.push(productId);
        
        // Mettre à jour le statut du chariot
        if (chariot.currentProducts.length >= chariot.capacity) {
            chariot.status = 'Complet';
        } else {
            chariot.status = 'Occupé';
        }
        
        try {
            await chariot.save();
        } catch (validationError) {
            return res.status(400).json({ 
                message: validationError.message || 'Erreur de validation lors de l\'ajout du produit au chariot',
                error: 'VALIDATION_ERROR'
            });
        }
        
        // Mettre à jour le chariot du produit
        product.chariotId = id;
        await product.save();
        
        res.status(200).json({
            message: 'Produit ajouté au chariot avec succès',
            chariot: {
                id: chariot._id,
                name: chariot.name,
                capacity: chariot.capacity,
                currentCount: chariot.currentProducts.length,
                status: chariot.status
            }
        });
    } catch (error) {
        console.error('Erreur lors de l\'ajout du produit au chariot:', error);
        
        // Message d'erreur détaillé pour les erreurs de validation de capacité
        if (error.message && error.message.includes('capacité du chariot')) {
            return res.status(400).json({ 
                message: error.message,
                error: 'CAPACITY_EXCEEDED'
            });
        }
        
        res.status(500).json({ 
            message: 'Erreur lors de l\'ajout du produit au chariot',
            error: 'SERVER_ERROR'
        });
    }
};

// Retirer un produit d'un chariot
exports.removeProductFromChariot = async (req, res) => {
    const { id, productId } = req.params;
    
    // Vérifier si les IDs sont valides
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(productId)) {
        return res.status(400).json({ message: 'IDs invalides' });
    }
    
    try {
        // Récupérer le chariot
        const chariot = await Chariot.findById(id);
        const product = await Product.findById(productId);
        
        if (!chariot) {
            return res.status(404).json({ message: 'Chariot non trouvé' });
        }
        
        if (!product) {
            return res.status(404).json({ message: 'Produit non trouvé' });
        }
        
        // Vérifier si le produit est dans le chariot
        const productIndex = chariot.currentProducts.findIndex(p => p.toString() === productId);
        if (productIndex === -1) {
            return res.status(400).json({ message: 'Le produit n\'est pas dans ce chariot' });
        }
        
        // Retirer le produit du chariot
        chariot.currentProducts.splice(productIndex, 1);
        
        // Si le chariot est vide, réinitialiser le type de produit
        if (chariot.currentProducts.length === 0) {
            chariot.currentProductType = null;
            chariot.status = 'Disponible';
        } else {
            // Sinon, mettre à jour le statut
            chariot.status = chariot.currentProducts.length >= chariot.capacity ? 'Complet' : 'Occupé';
        }
        
        await chariot.save();
        
        // Mettre à jour le produit
        product.chariotId = null;
        await product.save();
        
        res.status(200).json({
            message: 'Produit retiré du chariot avec succès',
            chariot
        });
    } catch (error) {
        console.error('Erreur lors du retrait du produit du chariot:', error);
        res.status(500).json({ message: 'Erreur lors du retrait du produit du chariot' });
    }
};

// Supprimer un chariot
exports.deleteChariot = async (req, res) => {
    const { id } = req.params;
    
    // Vérifier si l'ID est valide
    if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'ID de chariot invalide' });
    }
    
    try {
        // Vérifier si le chariot existe
        const chariot = await Chariot.findById(id);
        if (!chariot) {
            return res.status(404).json({ message: 'Chariot non trouvé' });
        }
        
        // Supprimer les références du chariot dans les produits
        for (const productId of chariot.currentProducts) {
            const product = await Product.findById(productId);
            if (product) {
                product.chariotId = null;
                await product.save();
            }
        }
        
        // Supprimer le chariot
        await Chariot.findByIdAndDelete(id);
        
        res.status(200).json({ message: 'Chariot supprimé avec succès', id });
    } catch (error) {
        console.error('Erreur lors de la suppression du chariot:', error);
        res.status(500).json({ message: 'Erreur lors de la suppression du chariot' });
    }
};

// Récupérer les chariots par type de produit
exports.getChariotsByProductType = async (req, res) => {
    const { productType } = req.params;
    
    try {
        let query = {};
        
        if (productType !== 'all') {
            // Si un type de produit est spécifié, filtrer par ce type
            query.currentProductType = productType;
        }
        
        const chariots = await Chariot.find(query)
            .populate('currentProducts', 'name price quantity')
            .sort({ name: 1 });
        
        res.status(200).json(chariots);
    } catch (error) {
        console.error('Erreur lors de la récupération des chariots par type de produit:', error);
        res.status(500).json({ message: 'Erreur lors de la récupération des chariots par type de produit' });
    }
};

// Vider un chariot
exports.emptyChariot = async (req, res) => {
    const { id } = req.params;
    
    // Vérifier si l'ID est valide
    if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'ID de chariot invalide' });
    }
    
    try {
        // Récupérer le chariot
        const chariot = await Chariot.findById(id);
        
        if (!chariot) {
            return res.status(404).json({ message: 'Chariot non trouvé' });
        }
        
        // Supprimer les références du chariot dans les produits
        for (const productId of chariot.currentProducts) {
            const product = await Product.findById(productId);
            if (product) {
                product.chariotId = null;
                await product.save();
            }
        }
        
        // Vider le chariot
        chariot.currentProducts = [];
        chariot.currentProductType = null;
        chariot.status = 'Disponible';
        
        await chariot.save();
        
        res.status(200).json({
            message: 'Chariot vidé avec succès',
            chariot
        });
    } catch (error) {
        console.error('Erreur lors de la vidange du chariot:', error);
        res.status(500).json({ message: 'Erreur lors de la vidange du chariot' });
    }
};