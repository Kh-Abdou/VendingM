const express = require('express');
const codeController = require('../controllers/code.controllers');

const router = express.Router();

// Generate a payment code
router.post('/generate', codeController.generateCode);

// Use a payment code
router.post('/use', codeController.useCode);

module.exports = router;