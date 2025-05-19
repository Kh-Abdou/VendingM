// Helper functions for notifications

// Prepare product details for notification
function prepareProductsForNotification(products) {
  return products.map(p => ({
    productId: p.productId?._id || p.productId,
    nom: p.productId?.name || p.nom,
    quantite: p.quantity,
    prix: p.price
  }));
}

module.exports = {
  prepareProductsForNotification
};
