const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['DEPOSIT', 'PAYMENT', 'REFUND'],
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    },
    orderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'order',
        default: null
    }
});

const eWalletSchema = new mongoose.Schema({
    userId: {  // Changed from clientId to userId to match your controller
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user', // Reference to the User model
        required: true,
    },
    balance: {
        type: Number,
        required: true,
        default: 0, // Default balance
    },
    transactions: [transactionSchema]  // Added transactions array
}, {
    timestamps: true // Adds createdAt and updatedAt fields
});

const EWallet = mongoose.model('EWallet', eWalletSchema);
module.exports = EWallet;