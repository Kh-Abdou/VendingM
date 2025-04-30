const express = require('express');
const { 
    setRegister, 
    login, 
    getUserById, 
    deleteUserById, 
    updateUserById,
    getClients  // Add this line to import the getClients function
} = require('../controllers/user.controllers');
const router = express.Router();

// Your existing routes
router.get('/:id', getUserById);
router.post('/', setRegister);
router.post('/login', login);

// Change this line to use the imported function directly
router.get('/clients', getClients);

router.put('/:id', updateUserById);  
router.delete('/:id', deleteUserById);

module.exports = router;
