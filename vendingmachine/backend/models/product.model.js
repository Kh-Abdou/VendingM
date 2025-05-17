const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    price: {
        type: Number,
        required: true
    },
    quantity: {
        type: Number,
        required: true,
        default: 0
    },
    description: {
        type: String,
        default: ''
    },    image: {
        type: String,
        default: 'default-product.jpg'
    },
    category: {
        type: String,
        default: 'Non classé'
    },
    isActive: {
        type: Boolean,
        default: true
    },
    chariotId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Chariot',
        default: null,
        validate: {
            validator: function(v) {
                if (!v) return true; // Allow null values
                // Check if chariot exists when value is set
                return mongoose.model('Chariot').findById(v).exec()
                    .then(chariot => !!chariot);
            },
            message: 'Invalid chariot ID specified'
        }
    }
}, {
    timestamps: true
});

const Product = mongoose.model('Product', productSchema);

module.exports = Product;
