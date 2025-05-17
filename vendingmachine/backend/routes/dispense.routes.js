const express = require('express');
const router = express.Router();
const Product = require('../models/product.model');
const Order = require('../models/order.model');
const Chariot = require('../models/chariot.model');
const Hardware = require('../models/hardware.model');

// Route to get next dispensable order
router.get('/next-order', async (req, res) => {
    try {
        const order = await Order.findOne({
            status: 'PENDING',
            paymentMethod: { $in: ['EWALLET', 'CODE'] }
        }).populate('products.productId');

        if (!order) {
            return res.status(404).json({ message: 'No pending orders found' });
        }

        // Transform order for Arduino
        const dispensableProducts = [];
        
        for (const orderProduct of order.products) {
            const product = await Product.findById(orderProduct.productId)
                .populate('chariotId');
            
            if (!product || !product.chariotId) {
                continue;
            }

            // Get the chariot number from chariot name (e.g., "CHARIOT1" -> 1)
            const chariotNumber = parseInt(product.chariotId.name.replace(/\D/g, ''));
            
            if (!isNaN(chariotNumber) && chariotNumber >= 1 && chariotNumber <= 4) {
                dispensableProducts.push({
                    couloir: chariotNumber,
                    quantity: orderProduct.quantity
                });
            }
        }

        if (dispensableProducts.length === 0) {
            return res.status(400).json({ message: 'No dispensable products in order' });
        }

        res.status(200).json({
            orderId: order._id,
            products: dispensableProducts
        });
    } catch (error) {
        console.error('Error getting next order:', error);
        res.status(500).json({ message: 'Error getting next order' });
    }
});

// Route to complete an order
router.post('/complete', async (req, res) => {
    try {
        const { orderId, vendingMachineId } = req.body;

        if (!orderId) {
            return res.status(400).json({ message: 'Order ID is required' });
        }

        const order = await Order.findById(orderId);
        
        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        // Update order status
        order.status = 'COMPLETED';
        order.vendingMachineId = vendingMachineId;
        order.dispensedAt = new Date();
        
        await order.save();

        res.status(200).json({
            message: 'Order completed successfully',
            orderId: order._id
        });
    } catch (error) {
        console.error('Error completing order:', error);
        res.status(500).json({ message: 'Error completing order' });
    }
});

// Route to fail an order with enhanced error details
router.post('/fail', async (req, res) => {
    try {
        const { orderId, reason, details, vendingMachineId } = req.body;

        if (!orderId) {
            return res.status(400).json({ message: 'Order ID is required' });
        }

        console.log(`Received order failure request for order ${orderId} with reason: ${reason}`);
        if (details) {
            console.log('Failure details:', JSON.stringify(details, null, 2));
        }

        const order = await Order.findById(orderId);
        
        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        // Update order status with detailed failure information
        order.status = 'FAILED';
        order.failureReason = reason || 'Unknown error';
        order.failedAt = new Date();
        
        // Store hardware failure details if available
        if (details) {
            if (!order.hardwareDetails) {
                order.hardwareDetails = {};
            }
            order.hardwareDetails.failure = details;
            order.hardwareDetails.failureTimestamp = details.timestamp || Date.now();
            order.hardwareDetails.totalExpected = details.totalExpected;
            order.hardwareDetails.totalDispensed = details.totalDispensed;
            order.hardwareDetails.completionPercentage = details.completionPercentage;
        }
        
        await order.save();

        // Update machine status
        if (vendingMachineId) {
            await Hardware.findByIdAndUpdate(vendingMachineId, {
                status: 'AVAILABLE',  // Reset to available even after failure
                currentOrder: null,
                lastFailedOrderId: order._id,
                lastFailedOrderTimestamp: new Date()
            });
        }

        // Send notification about order failure
        if (order.userId) {
            await NotificationModel.create({
                userId: order.userId,
                title: "Problème avec votre commande",
                message: `Il y a eu un problème avec votre commande: ${reason}`,
                type: "ORDER_FAILED",
                orderId: order._id,
                hardwareDetails: details || undefined
            });
        }

        res.status(200).json({
            message: 'Order marked as failed',
            orderId: order._id,
            status: order.status,
            failureReason: order.failureReason
        });
    } catch (error) {
        console.error('Error failing order:', error);
        res.status(500).json({ message: 'Error failing order' });
    }
});

module.exports = router;
