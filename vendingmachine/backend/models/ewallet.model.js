const mongoose = require('mongoose');

const eWalletSchema = new mongoose.Schema({
    clientId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User', // Reference to the User model
        required: true,
    },
    balance: {
        type: Number,
        required: true,
        default: 0, // Default balance
    },
}, {
    timestamps: true // Adds createdAt and updatedAt fields
});

const EWallet = mongoose.model('EWallet', eWalletSchema);
module.exports = EWallet;