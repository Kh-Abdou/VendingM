const express = require("express");
const router = express.Router();
const {
  generateCode,
  validateCode,
  // other functions...
} = require("../controllers/code.controllers"); // Changed from code.controller to code.controllers

// Routes
router.post("/generate", generateCode);
router.post("/validate", validateCode);
// other routes...

module.exports = router;