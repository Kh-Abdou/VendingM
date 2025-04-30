const EWallet = require('../models/ewallet.model');

// Get e-wallet balance
module.exports.getBalance = async (req, res) => {
    try {
        const { clientId } = req.params;
        const wallet = await EWallet.findOne({ clientId });
        
        if (!wallet) {
            return res.status(404).json({ message: 'E-wallet not found for this client' });
        }
        
        res.status(200).json({ balance: wallet.balance });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Add funds to e-wallet
module.exports.addFunds = async (req, res) => {
    try {
        const { clientId, amount } = req.body;
        const WALLET_LIMIT = 5000; // Set the wallet limit to 5000 DA
        
        if (!clientId || !amount || Number(amount) <= 0) {
            return res.status(400).json({ message: 'Client ID and a positive amount are required' });
        }
        
        let wallet = await EWallet.findOne({ clientId });
        
        if (!wallet) {
            // Create new wallet if it doesn't exist
            // Check if initial amount exceeds the limit
            if (Number(amount) > WALLET_LIMIT) {
                return res.status(400).json({ 
                    message: `Amount exceeds wallet limit of ${WALLET_LIMIT} DA` 
                });
            }
            
            wallet = new EWallet({
                clientId,
                balance: Number(amount)
            });
        } else {
            // Calculate new balance
            const newBalance = Number(wallet.balance) + Number(amount);
            
            // Check if new balance would exceed the limit
            if (newBalance > WALLET_LIMIT) {
                return res.status(400).json({ 
                    message: `Transaction declined. Balance would exceed the ${WALLET_LIMIT} DA limit`,
                    currentBalance: wallet.balance,
                    remainingCapacity: WALLET_LIMIT - wallet.balance
                });
            }
            
            // Update existing wallet
            wallet.balance = newBalance;
        }
        
        await wallet.save();
        res.status(200).json({ 
            message: 'Funds added successfully', 
            balance: wallet.balance,
            limit: WALLET_LIMIT
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Pay with e-wallet
module.exports.payWithWallet = async (req, res) => {
    try {
        const { clientId, amount } = req.body;
        
        if (!clientId || !amount || amount <= 0) {
            return res.status(400).json({ message: 'Client ID and a positive amount are required' });
        }
        
        const wallet = await EWallet.findOne({ clientId });
        
        if (!wallet) {
            return res.status(404).json({ message: 'E-wallet not found for this client' });
        }
        
        if (wallet.balance < amount) {
            return res.status(400).json({ message: 'Insufficient funds' });
        }
        
        wallet.balance -= amount;
        await wallet.save();
        
        res.status(200).json({ 
            message: 'Payment successful', 
            remainingBalance: wallet.balance 
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};