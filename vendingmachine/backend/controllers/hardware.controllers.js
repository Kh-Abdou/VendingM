const Hardware = require('../models/hardware.model');
const Product = require('../models/product.model');
const NotificationModel = require('../models/notification.model');
const UserModel = require('../models/user.model');
const mongoose = require('mongoose');

// Get all vending machines
exports.getAllMachines = async (req, res) => {
  try {
    // Since we only have one machine, just return it
    const machine = await Hardware.findOne()
      .populate('productMapping.productId', 'name price image')
      .populate('maintainer', 'name email');
    
    // If no machine exists yet, create one with default values
    if (!machine) {
      const newMachine = new Hardware({ vendingMachineId: 'VM001' });
      await newMachine.save();
      return res.status(200).json([newMachine]); // Return as array to maintain API compatibility
    }
    
    res.status(200).json([machine]); // Return as array to maintain API compatibility
  } catch (error) {
    console.error('Error fetching vending machines:', error);
    res.status(500).json({ message: 'Error fetching vending machines' });
  }
};

// Get a specific vending machine by ID
exports.getMachineById = async (req, res) => {
  try {
    // We only have one machine, so we'll always return it regardless of the ID
    // This maintains backward compatibility with existing API calls
    const machine = await Hardware.findOne()
      .populate('productMapping.productId', 'name price image')
      .populate('maintainer', 'name email');
    
    if (!machine) {
      // If no machine exists yet, create one with default values
      const newMachine = new Hardware({ vendingMachineId: 'VM001' });
      await newMachine.save();
      return res.status(200).json(newMachine);
    }
    
    res.status(200).json(machine);
  } catch (error) {
    console.error('Error fetching vending machine:', error);
    res.status(500).json({ message: 'Error fetching vending machine details' });
  }
};

// Register a new vending machine
exports.registerMachine = async (req, res) => {
  try {
    const { name, location } = req.body;
    
    // Check if a machine already exists
    const existingMachine = await Hardware.findOne();
    
    if (existingMachine) {
      // If a machine already exists, just update its properties
      if (name) existingMachine.name = name;
      if (location) existingMachine.location = location;
      
      await existingMachine.save();
      return res.status(200).json(existingMachine);
    }
    
    // Create new machine
    const newMachine = new Hardware({
      vendingMachineId: 'VM001', // Always use default ID
      name: name || 'Vending Machine',
      location: location || 'Main Building'
    });
    
    await newMachine.save();
    
    // Notify technicians about new machine registration
    const technicians = await UserModel.find({ role: 'technician' });
    
    if (technicians.length > 0) {
      const notifications = technicians.map(technician => {
        return new NotificationModel({
          userId: technician._id,
          title: 'New Vending Machine',
          message: `A new vending machine "${name || 'Vending Machine'}" has been registered`,
          type: 'MAINTENANCE',
          vendingMachineId: 'VM001',
          priority: 3
        });
      });
      
      await NotificationModel.insertMany(notifications);
    }
    
    res.status(201).json(newMachine);
  } catch (error) {
    console.error('Error registering vending machine:', error);
    res.status(500).json({ message: 'Error registering vending machine' });
  }
};

// Update machine status
exports.updateMachineStatus = async (req, res) => {
  try {
    const { status, temperature, humidity } = req.body;
    
    // Find the single machine
    let machine = await Hardware.findOne();
    
    // If no machine exists yet, create one with default values
    if (!machine) {
      machine = new Hardware({ vendingMachineId: 'VM001' });
    }
    
    // Update fields if provided
    if (status) machine.status = status;
    if (temperature !== undefined) machine.temperature = temperature;
    if (humidity !== undefined) machine.humidity = humidity;
    
    machine.lastCommunication = new Date();
    await machine.save();
    
    res.status(200).json(machine);
  } catch (error) {
    console.error('Error updating machine status:', error);
    res.status(500).json({ message: 'Error updating machine status' });
  }
};

// Update environment data (temperature, humidity)
exports.updateEnvironment = async (req, res) => {
  try {
    const { temperature, humidity } = req.body;
    // We don't need vendingMachineId since we only have one machine
    
    // Find the single machine - we'll use findOne() with no criteria to get the first (and only) machine
    let machine = await Hardware.findOne();
    
    // If no machine exists yet, create one with default values
    if (!machine) {
      machine = new Hardware({ vendingMachineId: 'VM001' });
    }
    
    // Update temperature and humidity
    if (temperature !== undefined) machine.temperature = temperature;
    if (humidity !== undefined) machine.humidity = humidity;
    
    machine.lastCommunication = new Date();
    await machine.save();
    
    // Check if temperature or humidity is outside normal range
    const isTemperatureAlert = temperature > 30 || temperature < 10;
    const isHumidityAlert = humidity > 70 || humidity < 20;
    
    // Send notifications to technicians if values are outside normal range
    if (isTemperatureAlert || isHumidityAlert) {
      const technicians = await UserModel.find({ role: 'technician' });
      
      if (technicians.length > 0) {
        let alertMessage = 'Environmental alert:';
        let alertTitle = 'Environment Alert';
        let priority = 2;
        
        if (isTemperatureAlert) {
          alertMessage += ` Temperature ${temperature}°C is ${temperature > 30 ? 'too high' : 'too low'}.`;
          priority = temperature > 35 || temperature < 5 ? 1 : 2;
        }
        
        if (isHumidityAlert) {
          alertMessage += ` Humidity ${humidity}% is ${humidity > 70 ? 'too high' : 'too low'}.`;
          if (humidity > 85 || humidity < 10) priority = 1;
        }
          const notifications = technicians.map(technician => {
          return new NotificationModel({
            userId: technician._id,
            title: alertTitle,
            message: alertMessage,
            type: 'MAINTENANCE',
            vendingMachineId: machine.vendingMachineId, // Use the machine's ID
            priority
          });
        });
        
        await NotificationModel.insertMany(notifications);
      }
    }
    
    res.status(200).json({
      message: 'Environment data updated successfully',
      temperature: machine.temperature,
      humidity: machine.humidity,
      lastCommunication: machine.lastCommunication
    });
  } catch (error) {
    console.error('Error updating environment data:', error);
    res.status(500).json({ message: 'Error updating environment data' });
  }
};

// Update product mapping
exports.updateProductMapping = async (req, res) => {
  try {
    const { productMapping } = req.body;
    
    // Find the single machine
    let machine = await Hardware.findOne();
    
    // If no machine exists yet, create one with default values
    if (!machine) {
      machine = new Hardware({ vendingMachineId: 'VM001' });
    }
    
    if (!productMapping || !Array.isArray(productMapping)) {
      return res.status(400).json({ message: 'Valid product mapping array is required' });
    }
    
    // Validate product IDs
    for (const mapping of productMapping) {
      if (!mapping.productId || !mapping.couloir) {
        return res.status(400).json({ message: 'Each mapping must include productId and couloir' });
      }
      
      const product = await Product.findById(mapping.productId);
      if (!product) {
        return res.status(404).json({ message: `Product with ID ${mapping.productId} not found` });
      }
      
      if (mapping.couloir < 1 || mapping.couloir > 4) {
        return res.status(400).json({ message: 'Couloir must be between 1 and 4' });
      }
    }
    
    // Update mapping
    machine.productMapping = productMapping;
    await machine.save();
    
    // Return updated machine with populated product details
    const updatedMachine = await Hardware.findOne()
      .populate('productMapping.productId', 'name price image')
      .populate('maintainer', 'name email');
    
    res.status(200).json(updatedMachine);
  } catch (error) {
    console.error('Error updating product mapping:', error);
    res.status(500).json({ message: 'Error updating product mapping' });
  }
};

// Adjust stock levels
exports.adjustStockLevels = async (req, res) => {
  try {
    const { adjustments } = req.body;
    
    if (!adjustments || !Array.isArray(adjustments)) {
      return res.status(400).json({ message: 'Adjustments array is required' });
    }
    
    // Find the single machine
    let machine = await Hardware.findOne();
    
    // If no machine exists yet, create one with default values
    if (!machine) {
      machine = new Hardware({ vendingMachineId: 'VM001' });
      await machine.save();
    }
    
    // Apply adjustments
    for (const adjustment of adjustments) {
      const { couloir, amount } = adjustment;
      
      if (couloir === undefined || amount === undefined) {
        return res.status(400).json({ message: 'Each adjustment must include couloir and amount' });
      }
      
      const mappingIndex = machine.productMapping.findIndex(m => m.couloir === couloir);
      
      if (mappingIndex === -1) {
        return res.status(404).json({ message: `No product mapped to couloir ${couloir}` });
      }
      
      // Update stock level
      machine.productMapping[mappingIndex].stockLevel += amount;
      
      // Ensure stock level doesn't go below 0
      if (machine.productMapping[mappingIndex].stockLevel < 0) {
        machine.productMapping[mappingIndex].stockLevel = 0;
      }
      
      // Check if stock is low and send notification if needed
      if (machine.productMapping[mappingIndex].stockLevel <= 5) {
        const product = await Product.findById(machine.productMapping[mappingIndex].productId);
        const technicians = await UserModel.find({ role: 'technician' });
        
        if (technicians.length > 0 && product) {
          const notifications = technicians.map(technician => {
            return new NotificationModel({
              userId: technician._id,
              title: 'Low Stock Alert',
              message: `Product "${product.name}" is running low (${machine.productMapping[mappingIndex].stockLevel} left)`,
              type: 'STOCK',
              vendingMachineId: machine.vendingMachineId,
              priority: machine.productMapping[mappingIndex].stockLevel === 0 ? 1 : 2
            });
          });
          
          await NotificationModel.insertMany(notifications);
        }
      }
    }
      await machine.save();
    
    // Return updated machine with populated product details
    const updatedMachine = await Hardware.findOne()
      .populate('productMapping.productId', 'name price image');
    
    res.status(200).json(updatedMachine);
  } catch (error) {
    console.error('Error adjusting stock levels:', error);
    res.status(500).json({ message: 'Error adjusting stock levels' });
  }
};

// Authenticate user via RFID
exports.authenticateRfid = async (req, res) => {
  try {
    const { rfidUID } = req.body;
    
    if (!rfidUID) {
      return res.status(400).json({ message: 'RFID UID is required' });
    }
    
    // Find user by RFID UID (assuming there's an rfidUID field in your user model)
    // Note: You might need to adjust this query based on your actual user model structure
    const user = await UserModel.findOne({ rfidUID });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found for this RFID card' });
    }
    
    res.status(200).json({
      isAuthenticated: true,
      userId: user._id,
      name: user.name,
      email: user.email,
      role: user.role
    });
  } catch (error) {
    console.error('Error authenticating RFID:', error);
    res.status(500).json({ message: 'Error authenticating RFID' });
  }
};

// Get environment data
exports.getEnvironmentData = async (req, res) => {
  try {
    const machines = await Hardware.find().select('vendingMachineId name location temperature humidity lastCommunication status operationalSince');
    
    // Format the response with additional data
    const formattedMachines = machines.map(machine => {
      // Determine if temperature or humidity is outside normal range
      const isTemperatureAlert = machine.temperature > 30 || machine.temperature < 10;
      const isHumidityAlert = machine.humidity > 70 || machine.humidity < 20;
      
      return {
        vendingMachineId: machine.vendingMachineId,
        name: machine.name,
        location: machine.location,
        temperature: machine.temperature,
        humidity: machine.humidity,
        lastCommunication: machine.lastCommunication,
        status: machine.status || 'UNKNOWN',
        operationalSince: machine.operationalSince,
        alerts: {
          temperature: isTemperatureAlert,
          humidity: isHumidityAlert
        }
      };
    });
    
    res.status(200).json(formattedMachines);
  } catch (error) {
    console.error('Error fetching environment data:', error);
    res.status(500).json({ message: 'Error fetching environment data' });
  }
};
