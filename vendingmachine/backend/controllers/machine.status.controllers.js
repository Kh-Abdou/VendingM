const Hardware = require('../models/hardware.model');
const NotificationModel = require('../models/notification.model');
const UserModel = require('../models/user.model');

// Get current machine status
exports.getMachineStatus = async (req, res) => {
  try {
    const machine = await Hardware.findOne()
      .populate('statusUpdatedBy', 'name email')
      .populate('maintainer', 'name email');
    
    if (!machine) {
      return res.status(404).json({ message: 'Machine not found' });
    }
    
    res.status(200).json({
      vendingMachineId: machine.vendingMachineId,
      name: machine.name,
      location: machine.location,
      status: machine.status,
      statusMessage: machine.statusMessage,
      statusUpdatedBy: machine.statusUpdatedBy,
      statusUpdatedAt: machine.statusUpdatedAt,
      maintainer: machine.maintainer,
      temperature: machine.temperature,
      humidity: machine.humidity,
      lastCommunication: machine.lastCommunication
    });
  } catch (error) {
    console.error('Error getting machine status:', error);
    res.status(500).json({ message: 'Error getting machine status' });
  }
};

// Update machine status (technician only)
exports.updateMachineStatus = async (req, res) => {
  try {
    const { status, statusMessage, technicianId } = req.body;
    
    if (!status) {
      return res.status(400).json({ message: 'Status is required' });
    }
    
    if (!technicianId) {
      return res.status(400).json({ message: 'Technician ID is required' });
    }
    
    // Validate technician
    const technician = await UserModel.findById(technicianId);
    if (!technician || technician.role !== 'technician') {
      return res.status(403).json({ message: 'Only technicians can update machine status' });
    }
    
    // Find the machine
    let machine = await Hardware.findOne();
    
    if (!machine) {
      // Create machine if it doesn't exist
      machine = new Hardware({ vendingMachineId: 'VM001' });
    }
    
    const previousStatus = machine.status;
    
    // Update machine status
    machine.status = status;
    machine.statusMessage = statusMessage || '';
    machine.statusUpdatedBy = technicianId;
    machine.statusUpdatedAt = new Date();
    
    // Set maintainer for maintenance status
    if (status === 'MAINTENANCE') {
      machine.maintainer = technicianId;
    } else if (status === 'OPERATIONAL') {
      machine.maintainer = null;
    }
    
    await machine.save();
    
    // Create notifications for status change
    if (previousStatus !== status) {
      await createStatusChangeNotifications(machine, previousStatus, status, technician);
    }
    
    // Populate the response
    const updatedMachine = await Hardware.findOne()
      .populate('statusUpdatedBy', 'name email')
      .populate('maintainer', 'name email');
    
    res.status(200).json({
      message: 'Machine status updated successfully',
      machine: {
        vendingMachineId: updatedMachine.vendingMachineId,
        name: updatedMachine.name,
        location: updatedMachine.location,
        status: updatedMachine.status,
        statusMessage: updatedMachine.statusMessage,
        statusUpdatedBy: updatedMachine.statusUpdatedBy,
        statusUpdatedAt: updatedMachine.statusUpdatedAt,
        maintainer: updatedMachine.maintainer
      }
    });
  } catch (error) {
    console.error('Error updating machine status:', error);
    res.status(500).json({ message: 'Error updating machine status' });
  }
};

// Get machine status for client display
exports.getMachineStatusForClient = async (req, res) => {
  try {
    const machine = await Hardware.findOne();
    
    if (!machine) {
      return res.status(200).json({
        status: 'OFFLINE',
        isOperational: false,
        message: 'Machine status unknown'
      });
    }
    
    const isOperational = machine.status === 'OPERATIONAL';
    
    let clientMessage = '';
    switch (machine.status) {
      case 'OPERATIONAL':
        clientMessage = 'Machine is operational';
        break;
      case 'MAINTENANCE':
        clientMessage = 'Machine is under maintenance';
        break;
      case 'ERROR':
        clientMessage = 'Machine has an error';
        break;
      case 'OFFLINE':
        clientMessage = 'Machine is offline';
        break;
      case 'OUT_OF_SERVICE':
        clientMessage = 'Machine is out of service';
        break;
      case 'NEEDS_RESTOCKING':
        clientMessage = 'Machine needs restocking';
        break;
      default:
        clientMessage = 'Machine status unknown';
    }
    
    if (machine.statusMessage) {
      clientMessage += `: ${machine.statusMessage}`;
    }
    
    res.status(200).json({
      status: machine.status,
      isOperational,
      message: clientMessage,
      lastUpdated: machine.statusUpdatedAt
    });
  } catch (error) {
    console.error('Error getting machine status for client:', error);
    res.status(500).json({ 
      status: 'ERROR',
      isOperational: false,
      message: 'Error getting machine status'
    });
  }
};

// Helper function to create notifications for status changes
async function createStatusChangeNotifications(machine, previousStatus, newStatus, technician) {
  try {
    // Get all users except the technician who made the change
    const clients = await UserModel.find({ 
      role: 'client',
      _id: { $ne: technician._id }
    });
    
    const otherTechnicians = await UserModel.find({ 
      role: 'technician',
      _id: { $ne: technician._id }
    });
    
    // Create notification message
    let notificationTitle = 'Machine Status Updated';
    let notificationMessage = `Machine status changed from ${previousStatus} to ${newStatus}`;
    
    if (machine.statusMessage) {
      notificationMessage += `: ${machine.statusMessage}`;
    }
    
    notificationMessage += ` by ${technician.name}`;
    
    // Determine notification type and priority
    let notificationType = 'MAINTENANCE';
    let priority = 3; // Default priority
    
    if (newStatus === 'ERROR' || newStatus === 'OFFLINE') {
      priority = 1; // High priority
      notificationType = 'ERROR';
    } else if (newStatus === 'MAINTENANCE' || newStatus === 'OUT_OF_SERVICE') {
      priority = 2; // Medium priority
    }
    
    // Create notifications for clients
    const clientNotifications = clients.map(client => ({
      userId: client._id,
      title: notificationTitle,
      message: notificationMessage,
      type: notificationType,
      vendingMachineId: machine.vendingMachineId,
      priority
    }));
    
    // Create notifications for other technicians  
    const technicianNotifications = otherTechnicians.map(tech => ({
      userId: tech._id,
      title: notificationTitle,
      message: notificationMessage,
      type: notificationType,
      vendingMachineId: machine.vendingMachineId,
      priority
    }));
    
    // Insert all notifications
    if (clientNotifications.length > 0) {
      await NotificationModel.insertMany(clientNotifications);
    }
    
    if (technicianNotifications.length > 0) {
      await NotificationModel.insertMany(technicianNotifications);
    }
    
    console.log(`Created ${clientNotifications.length + technicianNotifications.length} notifications for status change`);  } catch (error) {
    console.error('Error creating status change notifications:', error);
  }
}
