const Stock = require('../models/stock.model');
const Product = require('../models/product.model');
const mongoose = require('mongoose');

// Obtenir tous les stocks
exports.getAllStocks = async (req, res) => {
  try {
    const stocks = await Stock.find()
      .populate('product', 'name price image category')
      .sort({ createdAt: -1 });
    
    res.status(200).json(stocks);
  } catch (error) {
    console.error('Error fetching stocks:', error);
    res.status(500).json({ message: 'Erreur lors de la récupération des stocks' });
  }
};

// Obtenir les stocks par emplacement
exports.getStocksByLocation = async (req, res) => {
  const { location } = req.params;
  
  try {
    const stocks = await Stock.find({ location })
      .populate('product', 'name price image category')
      .sort({ createdAt: -1 });
    
    res.status(200).json(stocks);
  } catch (error) {
    console.error('Error fetching stocks by location:', error);
    res.status(500).json({ message: 'Erreur lors de la récupération des stocks par emplacement' });
  }
};

// Obtenir un stock par ID
exports.getStockById = async (req, res) => {
  const { id } = req.params;
  
  // Vérifier si l'ID est valide
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ message: 'ID de stock invalide' });
  }
  
  try {
    const stock = await Stock.findById(id).populate('product', 'name price image category');
    
    if (!stock) {
      return res.status(404).json({ message: 'Stock non trouvé' });
    }
    
    res.status(200).json(stock);
  } catch (error) {
    console.error('Error fetching stock:', error);
    res.status(500).json({ message: 'Erreur lors de la récupération du stock' });
  }
};

// Ajouter un nouveau stock
exports.createStock = async (req, res) => {
  const { product, quantity, location, threshold } = req.body;
  
  // Vérifier les données requises
  if (!product || quantity === undefined || !location) {
    return res.status(400).json({ message: 'Veuillez fournir toutes les informations requises (produit, quantité, emplacement)' });
  }
  
  // Vérifier si l'ID du produit est valide
  if (!mongoose.Types.ObjectId.isValid(product)) {
    return res.status(400).json({ message: 'ID de produit invalide' });
  }
  
  try {
    // Vérifier si le produit existe
    const productExists = await Product.findById(product);
    if (!productExists) {
      return res.status(404).json({ message: 'Produit non trouvé' });
    }
    
    // Vérifier si un stock existe déjà pour ce produit et cet emplacement
    const existingStock = await Stock.findOne({ product, location });
    
    if (existingStock) {
      return res.status(400).json({ 
        message: 'Un stock existe déjà pour ce produit à cet emplacement',
        existingStockId: existingStock._id
      });
    }
    
    // Créer un nouveau stock
    const newStock = new Stock({
      product,
      quantity,
      location,
      threshold: threshold || 5, // Valeur par défaut si non fournie
      isLowStock: quantity <= (threshold || 5)
    });
    
    await newStock.save();
    
    // Récupérer le stock avec les informations produit pour la réponse
    const populatedStock = await Stock.findById(newStock._id).populate('product', 'name price image category');
    
    res.status(201).json(populatedStock);
  } catch (error) {
    console.error('Error creating stock:', error);
    res.status(500).json({ message: 'Erreur lors de la création du stock' });
  }
};

// Mettre à jour un stock
exports.updateStock = async (req, res) => {
  const { id } = req.params;
  const { quantity, location, threshold } = req.body;
  
  // Vérifier si l'ID est valide
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ message: 'ID de stock invalide' });
  }
  
  try {
    // Vérifier si le stock existe
    const stock = await Stock.findById(id);
    
    if (!stock) {
      return res.status(404).json({ message: 'Stock non trouvé' });
    }
    
    const updatedFields = {};
    
    // Mettre à jour seulement les champs fournis
    if (quantity !== undefined) updatedFields.quantity = quantity;
    if (location) updatedFields.location = location;
    if (threshold !== undefined) updatedFields.threshold = threshold;
    
    // Mettre à jour lastUpdated et isLowStock
    updatedFields.lastUpdated = Date.now();
    const newThreshold = threshold !== undefined ? threshold : stock.threshold;
    const newQuantity = quantity !== undefined ? quantity : stock.quantity;
    const isLowStock = newQuantity <= newThreshold;
    updatedFields.isLowStock = isLowStock;
    
    const updatedStock = await Stock.findByIdAndUpdate(
      id,
      updatedFields,
      { new: true, runValidators: true }
    ).populate('product', 'name price image category');
    
    // Vérifier si le stock est bas et envoyer une notification si nécessaire
    if (isLowStock) {
      try {
        // Créer une notification pour les techniciens
        const axios = require('axios');
        
        let title, message, priority;
        
        if (newQuantity <= 2) {
          title = 'Stock critique';
          message = `Le produit ${updatedStock.product.name} est critique (${newQuantity} unités) à l'emplacement ${updatedStock.location}`;
          priority = 5; // Critique
        } else if (newQuantity <= 4) {
          title = 'Stock bas';
          message = `Le produit ${updatedStock.product.name} est bas (${newQuantity} unités) à l'emplacement ${updatedStock.location}`;
          priority = 3; // Normal
        } else {
          // Si on arrive ici, c'est que la quantité est supérieure à 4 mais inférieure au seuil
          // Dans ce cas, on n'envoie pas de notification
          console.log('Stock bas mais pas assez pour notification');
          // Ne pas retourner ici, continuer l'exécution
        }
        
        // Envoyer la notification seulement si un titre a été défini
        if (title) {
          await axios.post('http://localhost:5000/notification/stock', {
            title,
            message,
            stockId: updatedStock._id,
            productName: updatedStock.product.name,
            quantity: newQuantity,
            priority,
            location: updatedStock.location
          });
          
          console.log('Notification de stock envoyée avec succès');
        }
      } catch (notificationError) {
        console.error('Erreur lors de l\'envoi de la notification de stock:', notificationError);
        // Ne pas échouer toute l'opération à cause d'une erreur de notification
      }
    }
    
    // Toujours envoyer la réponse, même après notification
    res.status(200).json(updatedStock);
  } catch (error) {
    console.error('Error updating stock:', error);
    res.status(500).json({ message: 'Erreur lors de la mise à jour du stock' });
  }
};

// Supprimer un stock
exports.deleteStock = async (req, res) => {
  const { id } = req.params;
  
  // Vérifier si l'ID est valide
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ message: 'ID de stock invalide' });
  }
  
  try {
    const stock = await Stock.findByIdAndDelete(id);
    
    if (!stock) {
      return res.status(404).json({ message: 'Stock non trouvé' });
    }
    
    res.status(200).json({ message: 'Stock supprimé avec succès', id });
  } catch (error) {
    console.error('Error deleting stock:', error);
    res.status(500).json({ message: 'Erreur lors de la suppression du stock' });
  }
};

// Obtenir les stocks à niveau bas
exports.getLowStocks = async (req, res) => {
  try {
    const lowStocks = await Stock.find({ isLowStock: true })
      .populate('product', 'name price image category')
      .sort({ quantity: 1 });
    
    res.status(200).json(lowStocks);
  } catch (error) {
    console.error('Error fetching low stocks:', error);
    res.status(500).json({ message: 'Erreur lors de la récupération des stocks à niveau bas' });
  }
};

// Ajuster la quantité de stock (augmenter ou diminuer)
exports.adjustStock = async (req, res) => {
  const { id } = req.params;
  const { adjustment, reason } = req.body;
  
  // Vérifier si l'ID est valide
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ message: 'ID de stock invalide' });
  }
  
  // Vérifier si l'ajustement est fourni
  if (adjustment === undefined) {
    return res.status(400).json({ message: 'Veuillez fournir une valeur d\'ajustement' });
  }
  
  try {
    const stock = await Stock.findById(id);
    
    if (!stock) {
      return res.status(404).json({ message: 'Stock non trouvé' });
    }
    
    // Calculer la nouvelle quantité
    const newQuantity = stock.quantity + adjustment;
    
    // Vérifier que la nouvelle quantité n'est pas négative
    if (newQuantity < 0) {
      return res.status(400).json({ 
        message: 'La quantité de stock ne peut pas être négative',
        currentQuantity: stock.quantity,
        requestedAdjustment: adjustment
      });
    }
    
    // Récupérer les infos du produit avant mise à jour
    const stockWithProduct = await Stock.findById(id).populate('product', 'name price image category');
    
    // Mettre à jour le stock
    stock.quantity = newQuantity;
    stock.lastUpdated = Date.now();
    const isLowStock = newQuantity <= stock.threshold;
    stock.isLowStock = isLowStock;
    
    await stock.save();
    
    const updatedStock = await Stock.findById(id).populate('product', 'name price image category');
    
    // Vérifier si le stock est bas et envoyer une notification si nécessaire
    if (isLowStock) {
      try {
        // Créer une notification pour les techniciens
        const axios = require('axios');
        
        let title, message, priority;
        
        if (newQuantity === 0) {
          title = 'Stock épuisé';
          message = `Le produit ${stockWithProduct.product.name} est totalement épuisé à l'emplacement ${stockWithProduct.location}`;
          priority = 5; // Critique
        } else if (newQuantity <= 2) {
          title = 'Stock critique';
          message = `Le produit ${stockWithProduct.product.name} est critique (${newQuantity} unités) à l'emplacement ${stockWithProduct.location}`;
          priority = 5; // Critique
        } else if (newQuantity <= 4) {
          title = 'Stock bas';
          message = `Le produit ${stockWithProduct.product.name} est bas (${newQuantity} unités) à l'emplacement ${stockWithProduct.location}`;
          priority = 3; // Normal
        } else {
          // Si on arrive ici, c'est que la quantité est supérieure à 4 mais inférieure au seuil
          // Dans ce cas, on n'envoie pas de notification
          console.log('Stock bas mais pas assez pour notification');
          return res.status(200).json({
            message: `Stock ${adjustment > 0 ? 'augmenté' : 'diminué'} avec succès`,
            previousQuantity: stock.quantity - adjustment,
            adjustment,
            currentQuantity: stock.quantity,
            reason: reason || 'Non spécifié',
            stock: updatedStock
          });
        }
        
        await axios.post('http://localhost:5000/notification/stock', {
          title,
          message,
          stockId: updatedStock._id,
          productName: stockWithProduct.product.name,
          quantity: newQuantity,
          priority,
          location: stock.location
        });
        
        console.log('Notification de stock envoyée avec succès');
      } catch (notificationError) {
        console.error('Erreur lors de l\'envoi de la notification de stock:', notificationError);
        // Ne pas échouer toute l'opération à cause d'une erreur de notification
      }
    }
    
    res.status(200).json({
      message: `Stock ${adjustment > 0 ? 'augmenté' : 'diminué'} avec succès`,
      previousQuantity: stock.quantity - adjustment,
      adjustment,
      currentQuantity: stock.quantity,
      reason: reason || 'Non spécifié',
      stock: updatedStock
    });
  } catch (error) {
    console.error('Error adjusting stock:', error);
    res.status(500).json({ message: 'Erreur lors de l\'ajustement du stock' });
  }
};