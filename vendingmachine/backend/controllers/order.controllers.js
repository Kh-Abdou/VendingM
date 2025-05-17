const Order = require('../models/order.model');
const Product = require('../models/product.model');
const Chariot = require('../models/chariot.model');
const Hardware = require('../models/hardware.model');
const NotificationModel = require('../models/notification.model');
const EWalletModel = require('../models/ewallet.model');

// Get pending orders for a vending machine
exports.getPendingOrders = async (req, res) => {
    try {
        const { vendingMachineId } = req.query;
        if (!vendingMachineId) {
            return res.status(400).json({
                message: 'vendingMachineId query parameter is required'
            });
        }

        // Find orders in 'pending' state for this machine
        const order = await Order.findOne({
            vendingMachineId,
            status: 'pending'
        }).sort({ createdAt: 1 }); // Get oldest pending order first

        if (!order) {
            return res.status(404).json({
                message: 'No pending orders found'
            });
        }

        // Return order details including product and chariot info
        res.status(200).json({
            orderId: order._id,
            userId: order.userId,
            products: order.products.map(p => ({
                productId: p.productId,
                quantity: p.quantity,
                chariotId: p.chariotId,
                price: p.price
            }))
        });

    } catch (error) {
        console.error('Error getting pending orders:', error);
        res.status(500).json({
            message: 'Error getting pending orders',
            error: error.message
        });
    }
};

// Complete an order after hardware confirms delivery
exports.completeOrder = async (req, res) => {
    try {
        const { orderId, vendingMachineId, details } = req.body;

        if (!orderId || !vendingMachineId) {
            return res.status(400).json({
                message: 'orderId and vendingMachineId are required'
            });
        }

        // Capture enhanced hardware details for troubleshooting
        console.log('Order completion details from hardware:', details);
        
        // Find and verify order
        const order = await Order.findById(orderId).populate('products.productId').populate('userId');
        if (!order) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        if (order.status !== 'processing') {
            return res.status(400).json({
                message: `Invalid order status: ${order.status}. Expected 'processing'`
            });
        }

        // Process payment if payment method is ewallet
        if (order.paymentMethod === 'EWALLET') {
            const wallet = await EWalletModel.findOne({ userId: order.userId._id });
            if (!wallet) {
                return res.status(404).json({
                    message: 'E-wallet not found for user'
                });
            }

            // Enhanced logging for payment operations
            console.log(`Processing payment for order ${orderId}: Deducting ${order.totalAmount} from wallet of user ${order.userId._id}`);
            
            // Deduct payment
            wallet.balance -= order.totalAmount;
            wallet.transactions.push({
                type: 'PAYMENT',
                amount: -order.totalAmount,
                date: new Date(),
                reference: `Order #${orderId} completion`,
                details: details ? JSON.stringify(details) : undefined
            });
            await wallet.save();
        }        // Update order status with enhanced details
        order.status = 'completed';
        order.completedAt = new Date();
        
        // Store hardware completion details if available
        if (details) {
            if (!order.hardwareDetails) {
                order.hardwareDetails = {};
            }
            order.hardwareDetails.completion = details;
            order.hardwareDetails.completionTimestamp = details.completionTimestamp || Date.now();
            order.hardwareDetails.totalDispensed = details.totalDispensed;
        }
        
        await order.save();
        console.log(`Order ${orderId} successfully marked as completed with hardware details`);

        // Send enhanced notifications with more details
        await NotificationModel.create({
            userId: order.userId._id,
            title: "Commande terminée avec succès",
            message: `Votre commande de ${order.totalAmount.toFixed(2)} DA a été délivrée correctement`,
            type: "ORDER_COMPLETED",
            amount: order.totalAmount,
            orderId: order._id,
            products: order.products.map(p => ({
                nom: p.productId.name,
                quantite: p.quantity,
                prix: p.price
            })),
            hardwareDetails: details || undefined
        });

        // Update machine status to available with timestamp
        await Hardware.findByIdAndUpdate(vendingMachineId, {
            status: 'AVAILABLE',
            currentOrder: null,
            lastCompletedOrderId: order._id,
            lastCompletedOrderTimestamp: new Date()
        });

        res.status(200).json({
            message: 'Order completed successfully',
            orderId: order._id,
            status: order.status,
            completedAt: order.completedAt,
            paymentProcessed: order.paymentMethod === 'EWALLET',
            hardwareDetails: details || undefined
        });

    } catch (error) {
        console.error('Error completing order:', error);
        res.status(500).json({
            message: 'Error completing order',
            error: error.message
        });
    }
};

// Process a new order
exports.processOrder = async (req, res) => {
    try {
        const { userId, products, vendingMachineId, paymentMethod } = req.body;

        if (!userId || !products || !Array.isArray(products) || products.length === 0) {
            return res.status(400).json({ 
                message: 'Invalid request body. Please provide userId and products array.'
            });
        }

        // Validate vending machine exists and is available
        const machine = await Hardware.findById(vendingMachineId);
        if (!machine) {
            return res.status(404).json({
                message: 'Vending machine not found'
            });
        }
        if (machine.status !== 'AVAILABLE') {
            return res.status(400).json({
                message: 'Vending machine is not available'
            });
        }

        // Validate and get product details including chariot IDs
        let orderDetails = [];
        let totalAmount = 0;
        
        for (const item of products) {
            const product = await Product.findById(item.productId).populate('chariotId');
            if (!product) {
                return res.status(404).json({
                    message: `Product ${item.productId} not found`
                });
            }
            if (!product.chariotId) {
                return res.status(400).json({
                    message: `Product ${product.name} is not assigned to any chariot`
                });
            }
            // Validate stock
            if (product.quantity < item.quantity) {
                return res.status(400).json({
                    message: `Insufficient stock for product ${product.name}`
                });
            }

            const itemPrice = item.price || product.price;
            totalAmount += itemPrice * item.quantity;

            orderDetails.push({
                productId: item.productId,
                quantity: item.quantity,
                chariotId: product.chariotId.id, 
                price: itemPrice
            });
        }

        // Create order record
        const order = await Order.create({
            userId,
            products: orderDetails,
            status: 'pending',
            totalAmount,
            paymentMethod,
            vendingMachineId
        });

        // Reserve products by decreasing available quantity
        for (const item of orderDetails) {
            await Product.findByIdAndUpdate(item.productId, {
                $inc: { quantity: -item.quantity }
            });
        }

        // Mark as processing since hardware will handle it
        order.status = 'processing';
        await order.save();

        // Send notification to user
        await NotificationModel.create({
            userId,
            title: "Commande en cours",
            message: `Votre commande de ${totalAmount.toFixed(2)} DA est en cours de traitement`,
            type: "ORDER",
            amount: totalAmount,
            orderId: order._id,
            products: orderDetails
        });

        res.status(201).json({
            message: 'Order created successfully',
            orderId: order._id,
            status: order.status,
            vendingMachineId,
            totalAmount,
            // Return chariot IDs so frontend can animate or update UI accordingly 
            chariots: orderDetails.map(item => item.chariotId)
        });

    } catch (error) {
        console.error('Error processing order:', error);
        res.status(500).json({
            message: 'Error processing order',
            error: error.message
        });
    }
};
