const Code = require('../models/code.model');
const EWallet = require('../models/ewallet.model');
const crypto = require('crypto');

// Generate a payment code
module.exports.generateCode = async (req, res) => {
    try {
        const { clientId, amount } = req.body;
        
        if (!clientId || !amount || amount <= 0) {
            return res.status(400).json({ message: 'Client ID and a positive amount are required' });
        }
        
        // Generate a random 6-digit code
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Create a new code record
        const newCode = new Code({
            clientId,
            code,
            amount,
            isUsed: false
        });
        
        await newCode.save();
        
        res.status(201).json({ 
            message: 'Code generated successfully', 
            code,
            amount 
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Use a payment code
module.exports.useCode = async (req, res) => {
    try {
        const { code } = req.body;
        
        if (!code) {
            return res.status(400).json({ message: 'Code is required' });
        }
        
        const codeRecord = await Code.findOne({ code, isUsed: false });
        
        if (!codeRecord) {
            return res.status(404).json({ message: 'Invalid or already used code' });
        }
        
        // Mark the code as used
        codeRecord.isUsed = true;
        await codeRecord.save();
        
        res.status(200).json({ 
            message: 'Code used successfully', 
            amount: codeRecord.amount 
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};