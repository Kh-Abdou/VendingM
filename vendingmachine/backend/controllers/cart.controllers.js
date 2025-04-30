const Cart = require('../models/cart.model');
const Product = require('../models/product.model');

// filepath: c:\Users\Khobz\Documents\Projects\PFE\vendingmachine\backend\controllers\cart.controllers.js

// Create a new cart
exports.createCart = async (req, res) => {
    try {
        const { clientId, items } = req.body;

        let totalAmount = 0;
        for (const item of items) {
            const product = await Product.findById(item.productId);
            if (!product) {
                return res.status(404).json({ message: 'Product not found' });
            }
            item.totalPrice = product.price * item.quantity;
            totalAmount += item.totalPrice;
        }

        const cart = new Cart({
            clientId,
            items,
            totalAmount,
        });

        await cart.save();
        res.status(201).json(cart);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get cart by ID
exports.getCartById = async (req, res) => {
    try {
        const cart = await Cart.findById(req.params.id).populate('items.productId');
        if (!cart) {
            return res.status(404).json({ message: 'Cart not found' });
        }
        res.status(200).json(cart);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Update cart
exports.updateCart = async (req, res) => {
    try {
        const { items } = req.body;

        const cart = await Cart.findById(req.params.id);
        if (!cart) {
            return res.status(404).json({ message: 'Cart not found' });
        }

        let totalAmount = 0;
        for (const item of items) {
            const product = await Product.findById(item.productId);
            if (!product) {
                return res.status(404).json({ message: 'Product not found' });
            }
            item.totalPrice = product.price * item.quantity;
            totalAmount += item.totalPrice;
        }

        cart.items = items;
        cart.totalAmount = totalAmount;

        await cart.save();
        res.status(200).json(cart);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Delete cart
exports.deleteCart = async (req, res) => {
    try {
        const cart = await Cart.findByIdAndDelete(req.params.id);
        if (!cart) {
            return res.status(404).json({ message: 'Cart not found' });
        }
        res.status(200).json({ message: 'Cart deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};