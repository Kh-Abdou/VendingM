const mongoose = require('mongoose');

const codeSchema = new mongoose.Schema({
    clientId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User', // Reference to the User model
        required: true,
    },
    code: {
        type: String,
        required: true,
        unique: true,
    },
    amount: {
        type: Number,
        required: true,
    },
    isUsed: {
        type: Boolean,
        default: false,
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 86400 // Expires after 24 hours (in seconds)
    }
});

const Code = mongoose.model('Code', codeSchema);
module.exports = Code;