const express = require('express');
const { setRegister, login, getUserById, deleteUserById, updateUserById } = require('../controllers/user.controllers');
const router = express.Router();

module.exports = router;


// router.post('/', (req, res) => {
    //     console.log(req.body);
    //     res.json({
        //         message: req.body.message,
        //     });
        // });
        
        
router.get('/:id', getUserById);
router.post('/', setRegister);
router.post('/login', login);



router.put('/:id', updateUserById);  

router.delete('/:id', deleteUserById);

module.exports = router;  
