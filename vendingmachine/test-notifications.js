/**
 * Script de test pour envoyer des notifications au backend.
 * Permet de tester facilement le système de notifications sans avoir à utiliser Postman.
 * 
 * Usage: 
 * 1. Assurez-vous que le serveur backend est en cours d'exécution
 * 2. Exécutez ce script avec Node.js: node test-notifications.js
 */

const axios = require('axios');

// Configuration
const API_URL = 'http://192.168.86.32:5000';
const TECHNICIAN_ID = '681154075cf30e38df588370'; // ID du technicien

// Fonction pour envoyer une notification de stock
async function sendStockNotification(title, message, priority, productDetails) {
  try {
    const response = await axios.post(`${API_URL}/notification/stock`, {
      userId: TECHNICIAN_ID,
      title,
      message,
      type: 'STOCK',
      priority,
      metadata: productDetails
    });
    
    console.log('📦 Notification de stock envoyée:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ Erreur lors de l\'envoi de la notification de stock:', error.response?.data || error.message);
    throw error;
  }
}

// Fonction pour envoyer une notification de maintenance
async function sendMaintenanceNotification(title, message, priority, machineDetails) {
  try {
    const response = await axios.post(`${API_URL}/notification/maintenance`, {
      userId: TECHNICIAN_ID,
      title,
      message,
      type: 'MAINTENANCE',
      priority,
      metadata: machineDetails
    });
    
    console.log('🔧 Notification de maintenance envoyée:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ Erreur lors de l\'envoi de la notification de maintenance:', error.response?.data || error.message);
    throw error;
  }
}

// Fonction pour récupérer toutes les notifications
async function getNotifications() {
  try {
    const response = await axios.get(`${API_URL}/notification/${TECHNICIAN_ID}`);
    console.log('📬 Notifications récupérées:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ Erreur lors de la récupération des notifications:', error.response?.data || error.message);
    throw error;
  }
}

// Fonction pour marquer toutes les notifications comme lues
async function markAllAsRead() {
  try {
    const response = await axios.put(`${API_URL}/notification/mark-read`, {
      userId: TECHNICIAN_ID
    });
    console.log('✅ Toutes les notifications marquées comme lues:', response.data);
    return response.data;
  } catch (error) {
    console.error('❌ Erreur lors du marquage des notifications:', error.response?.data || error.message);
    throw error;
  }
}

// Exécute les tests de notification
async function runTests() {
  try {
    console.log('🧪 Démarrage des tests de notification...');
    
    // 1. Stock bas (niveau = 4)
    await sendStockNotification(
      'Stock bas détecté',
      'Le produit Cola est bas (4 unités)',
      3, // Priorité normale
      {
        productId: 'product123',
        productName: 'Cola',
        currentStock: 4
      }
    );
    
    // 2. Stock critique (niveau = 2)
    await sendStockNotification(
      'Stock critique !',
      'Le produit Eau minérale est critique (2 unités)',
      5, // Priorité critique
      {
        productId: 'product456',
        productName: 'Eau minérale',
        currentStock: 2
      }
    );
    
    // 3. Stock épuisé (niveau = 0)
    await sendStockNotification(
      'Stock épuisé !',
      'Le produit Chips est totalement épuisé (0 unité)',
      5, // Priorité critique
      {
        productId: 'product789',
        productName: 'Chips',
        currentStock: 0
      }
    );
    
    // 4. Notification de maintenance
    await sendMaintenanceNotification(
      'Maintenance requise',
      'Le distributeur #123 nécessite une maintenance programmée',
      3, // Normal
      {
        machineId: 'machine123',
        location: 'Bâtiment A, Étage 2',
        reason: 'Maintenance mensuelle programmée'
      }
    );
    
    // 5. Notification de panne (critique)
    await sendMaintenanceNotification(
      'Panne détectée !',
      'Le distributeur #456 est en panne et nécessite une intervention immédiate',
      5, // Critique
      {
        machineId: 'machine456',
        location: 'Bâtiment B, Étage 1',
        reason: 'Système de paiement défectueux'
      }
    );
    
    // 6. Récupérer les notifications
    const notifications = await getNotifications();
    console.log(`📊 Nombre total de notifications: ${notifications.notifications?.length || 0}`);
    
    console.log('✅ Tests terminés avec succès !');
    console.log('🔍 Vérifiez maintenant l\'application mobile pour voir si les notifications s\'affichent correctement.');
    
  } catch (error) {
    console.error('❌ Échec des tests:', error);
  }
}

// Exécuter les tests
runTests();