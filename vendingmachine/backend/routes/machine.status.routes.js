const express = require('express');
const router = express.Router();
const {
  getMachineStatus,
  updateMachineStatus,
  getMachineStatusForClient
} = require('../controllers/machine.status.controllers');

// Get current machine status (for technicians)
router.get('/', getMachineStatus);

// Update machine status (technicians only)
router.put('/', updateMachineStatus);

// Get machine status for client display
router.get('/client', getMachineStatusForClient);

module.exports = router;
