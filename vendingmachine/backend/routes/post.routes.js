const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controllers');

// Import your controller functions ONCE - choose one approach
// Either import the entire controller:
// const userController = require('../controllers/user.controllers');

// OR destructure the functions you need:
const { 
    setRegister,
    login, 
    getUserById, 
    deleteUserById, 
    updateUserById, 
    getClients, 
    rechargeClientBalance 
} = require('../controllers/user.controllers');

// Define routes - ORDER MATTERS IN EXPRESS!
// Put specific routes BEFORE parameter routes

// 1. First specific routes
router.get('/clients', getClients);
router.post('/clients/:id/recharge', rechargeClientBalance);

// 2. Then parameter routes
router.get('/:id', getUserById);
router.post('/', setRegister);
router.post('/login', login);
router.put('/:id', updateUserById);
router.delete('/:id', deleteUserById);

// Export the router ONCE at the end
module.exports = router;
