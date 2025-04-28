const Usermodel = require('../models/user.model');
const bcrypt = require('bcrypt');

module.exports.setRegister = async (req, res) => {
    if (!req.body.name || !req.body.email || !req.body.password) {
        return res.status(400).json({ message: 'All fields are required' });
    }
    else { 
        try {
            const { name, email, password } = req.body;
            // Check if user already exists
            const existingUser = await Usermodel.findOne({ email });
            if (existingUser) {
                return res.status(400).json({ message: 'User already exists' });
            }
            
            // Hash password
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            
            // Create new user with hashed password
            const newUser = new Usermodel({ 
                name, 
                email, 
                password: hashedPassword 
            });
            
            await newUser.save();
            res.status(201).json({ 
                message: 'User created successfully', 
                user: {
                    _id: newUser._id,
                    name: newUser.name,
                    email: newUser.email
                    // Exclude password from response
                }
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server error' });
        }
    }
}

module.exports.getUsers = async (req, res) => {
    try {
        const users = await Usermodel.find();
        res.status(200).json(users);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};

//login

module.exports.login = async (req, res) => {
    try {
        // Check if email and password are provided
        if (!req.body.email || !req.body.password) {
            return res.status(400).json({ message: 'Email and password are required' });
        }
        
        const { email, password } = req.body;
        
        // Check if user exists
        const user = await Usermodel.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Verify password
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }
        
        // Password is valid, send user data (excluding password)
        res.status(200).json({
            message: 'Login successful',
            user: {
                _id: user._id,
                name: user.name,
                email: user.email
                // Exclude password from response
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
};



//get user by id
module.exports.getUserById = async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await Usermodel.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json(user);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
}

//delete user by id
module.exports.deleteUserById = async (req, res) => {
    try {
        const userId = req.params.id;
        const user
    = await Usermodel.findByIdAndDelete(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ message: 'User deleted successfully' });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
}

//update user by id
module.exports.updateUserById = async (req, res) => {
    try {
        const userId = req.params.id;
        const updatedUser = await Usermodel
.findByIdAndUpdate(userId, req.body, { new: true });
        if (!updatedUser) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json(updatedUser);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
}
