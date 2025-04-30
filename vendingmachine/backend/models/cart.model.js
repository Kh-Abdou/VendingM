const mongoose = require('mongoose');

const cartSchema = new mongoose.Schema({
    clientId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User', // Reference to the User model
        required: true,
    },
    items: [
        {
            productId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Product', // Reference to the Product model
                required: true,
            },
            quantity: {
                type: Number,
                required: true,
                min: 1,
            },
            totalPrice: {
                type: Number,
                required: true,
            },
        },
    ],
    totalAmount: {
        type: Number,
        required: true,
        default: 0,
    },
    status: {
        type: String,
        enum: ['pending', 'paid', 'completed'], // Status of the cart
        default: 'pending',
    },
});

const Cart = mongoose.model('Cart', cartSchema);
module.exports = Cart;