const User = require('../models/user.model');
const bcrypt = require('bcrypt');

module.exports.setRegister = async (req, res) => {
    if (!req.body.name || !req.body.email || !req.body.password) {
        return res.status(400).json({ message: 'All fields are required' });
    } else {
        try {
            const { name, email, password, role } = req.body;

            // Check if user already exists
            const existingUser = await User.findOne({ email });
            if (existingUser) {
                return res.status(400).json({ message: 'User already exists' });
            }

            // Hash password
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);

            // Create new user with hashed password and role
            const newUser = new User({
                name,
                email,
                password: hashedPassword,
                role: role || 'client',
                credit: 0, // Initialize credit to 0
            });

            await newUser.save();
            res.status(201).json({
                message: 'User created successfully',
                user: {
                    _id: newUser._id,
                    name: newUser.name,
                    email: newUser.email,
                    role: newUser.role, // Include role in the response
                },
            });
        } catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server error' });
        }
    }
};

module.exports.getUsers = async (req, res) => {
    try {
        const users = await User.find();
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
        const user = await User.findOne({ email });
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
                email: user.email,
                role: user.role, // Include role in the response
            },
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
        const user = await User.findById(userId);
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
    = await User.findByIdAndDelete(userId);
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
        const updatedUser = await User
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

// Get all clients (users with role="client")
const getClients = async (req, res) => {
    try {
        const clients = await User.find({ role: 'client' }); // Changed type→role, Client→client
        res.status(200).json(clients);
    } catch (error) {
        console.error('Error fetching clients:', error);
        res.status(500).json({ message: 'Failed to fetch clients', error: error.message });
    }
};

// Recharge a client's balance
const rechargeClientBalance = async (req, res) => {
    try {
        const { id } = req.params;
        const { amount } = req.body;
        
        if (!amount || isNaN(amount) || amount <= 0) {
            return res.status(400).json({ message: 'Valid amount is required' });
        }
        
        // Find client and update their credit
        const client = await User.findById(id);
        
        if (!client) {
            return res.status(404).json({ message: 'Client not found' });
        }
        
        if (client.role !== 'client') { // Changed type→role, Client→client
            return res.status(400).json({ message: 'User is not a client' });
        }
        
        // Add amount to current credit
        client.credit = (client.credit || 0) + parseFloat(amount);
        await client.save();
        
        res.status(200).json(client);
    } catch (error) {
        console.error('Error recharging client balance:', error);
        res.status(500).json({ message: 'Failed to recharge balance', error: error.message });
    }
};

// Mettre à jour le mot de passe
const updatePassword = async (req, res) => {
  try {
    const userId = req.params.id;
    const { currentPassword, newPassword } = req.body;
    
    // Vérifier que les deux mots de passe sont fournis
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Les mots de passe actuel et nouveau sont requis' });
    }
    
    // Vérifier que le nouveau mot de passe a au moins 6 caractères
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Le nouveau mot de passe doit contenir au moins 6 caractères' });
    }
    
    // Trouver l'utilisateur
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }
    
    // Vérifier que le mot de passe actuel est correct
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Mot de passe actuel incorrect' });
    }
    
    // Hacher le nouveau mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);
    
    // Mettre à jour le mot de passe
    user.password = hashedPassword;
    await user.save();
    
    res.status(200).json({ message: 'Mot de passe mis à jour avec succès' });
  } catch (error) {
    console.error('Erreur lors de la mise à jour du mot de passe:', error);
    res.status(500).json({ message: 'Erreur serveur lors de la mise à jour du mot de passe' });
  }
};

// Export all functions together at the end
module.exports = {
    setRegister: module.exports.setRegister,
    getUsers: module.exports.getUsers,
    login: module.exports.login,
    getUserById: module.exports.getUserById,
    deleteUserById: module.exports.deleteUserById,
    updateUserById: module.exports.updateUserById,
    getClients,
    rechargeClientBalance,
    updatePassword
};