const express = require('express');
const ewalletController = require('../controllers/ewallet.controllers');

const router = express.Router();

// Get e-wallet balance
router.get('/:clientId', ewalletController.getBalance);

// Add funds to e-wallet
router.post('/add-funds', ewalletController.addFunds);

// Pay with e-wallet
router.post('/pay', ewalletController.payWithWallet);

module.exports = router;