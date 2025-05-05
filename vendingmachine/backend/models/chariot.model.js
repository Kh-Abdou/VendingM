const mongoose = require('mongoose');

const chariotSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true,
        unique: true
    },
    capacity: {
        type: Number,
        required: true,
        default: 10,
        min: 1
    },
    status: {
        type: String,
        enum: ['Disponible', 'Complet', 'Occupé'],
        default: 'Disponible'
    },
    currentProductType: {
        type: String,
        default: null
    },
    currentProducts: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        validate: {
            validator: function(value) {
                // Cette validation s'exécute au niveau du tableau
                const doc = this.parent();
                if (doc && doc.currentProducts) {
                    return doc.currentProducts.length <= doc.capacity;
                }
                return true;
            },
            message: props => `La capacité maximale du chariot est atteinte. Impossible d'ajouter plus de produits.`
        }
    }]
}, {
    timestamps: true
});

// Middleware pour mettre à jour le statut en fonction du nombre de produits
chariotSchema.pre('save', function(next) {
    // Vérification stricte avant toute sauvegarde
    if (this.currentProducts.length > this.capacity) {
        const error = new Error(`La capacité du chariot (${this.capacity}) est dépassée. Impossible d'ajouter plus de produits.`);
        return next(error);
    }
    
    if (this.currentProducts.length >= this.capacity) {
        this.status = 'Complet';
    } else if (this.currentProducts.length > 0) {
        this.status = 'Occupé';
    } else {
        this.status = 'Disponible';
        this.currentProductType = null;
    }
    next();
});

// Méthode statique pour vérifier si un chariot peut accueillir un produit supplémentaire
chariotSchema.statics.canAddProduct = function(chariotId) {
    return this.findById(chariotId).then(chariot => {
        if (!chariot) return false;
        return chariot.currentProducts.length < chariot.capacity;
    });
};

const Chariot = mongoose.model('Chariot', chariotSchema);
module.exports = Chariot;