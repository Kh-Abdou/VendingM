const express = require('express');
const router = express.Router();
const {
  getAllMachines,
  getMachineById,
  registerMachine,
  updateMachineStatus,
  updateProductMapping,
  updateEnvironment,
  adjustStockLevels,
  authenticateRfid,
  getEnvironmentData
} = require('../controllers/hardware.controllers');

// Import the dispense controller
const { 
  getNewOrdersForDispensing,
  completeOrderDispensing 
} = require('../controllers/dispense.controllers');

// Get all vending machines
router.get('/', getAllMachines);

// Get environment data
router.get('/environment', getEnvironmentData);

// Get a specific vending machine by ID
router.get('/:id', getMachineById);

// Register a new vending machine
router.post('/register', registerMachine);

// Update machine status - simplify by removing machine ID from path
router.put('/status', updateMachineStatus);

// Update product mapping - simplify by removing machine ID from path
router.put('/mapping', updateProductMapping);

// Update environment data (temperature, humidity)
router.post('/environment', updateEnvironment);

// Adjust stock levels
router.post('/stock', adjustStockLevels);

// Authenticate user via RFID
router.post('/auth/rfid', authenticateRfid);

// NEW ROUTES for dispensing orders
router.post('/dispense/new-orders', getNewOrdersForDispensing);
router.post('/dispense/complete', completeOrderDispensing);

module.exports = router;
