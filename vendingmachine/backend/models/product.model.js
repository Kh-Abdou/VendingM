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
    quantity: { // Added quantity field
        type: Number,
        required: true,
        default: 0 // Default value for quantity
    }
});

const Product = mongoose.model('Product', productSchema);

module.exports = Product;
