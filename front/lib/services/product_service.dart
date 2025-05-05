import 'package:flutter/material.dart';
import 'api_service.dart';

class Product {
  final String? id;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? chariotId;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.chariotId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price'] is int
          ? (json['price'] as int).toDouble()
          : json['price'],
      quantity: json['quantity'],
      imageUrl: json['imageUrl'],
      chariotId: json['chariotId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (chariotId != null) 'chariotId': chariotId,
    };
  }
}

class ProductService {
  // Récupérer tous les produits
  static Future<List<Product>> getProducts() async {
    try {
      final response = await ApiService.get('/product');

      // Si la réponse est une liste, on la traite directement
      if (response is List) {
        return response.map((product) => Product.fromJson(product)).toList();
      }
      // Si la réponse est un objet avec une propriété 'products' qui est une liste
      else if (response is Map && response.containsKey('products')) {
        final products = response['products'] as List;
        return products.map((product) => Product.fromJson(product)).toList();
      }
      // Si la réponse est un autre format, on retourne une liste vide
      else {
        return [];
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des produits: $e');
      rethrow;
    }
  }

  // Récupérer un produit par son ID
  static Future<Product> getProductById(String id) async {
    try {
      final response = await ApiService.get('/product/$id');
      return Product.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du produit: $e');
      rethrow;
    }
  }

  // Ajouter un nouveau produit
  static Future<Product> addProduct(Product product) async {
    try {
      final response = await ApiService.post('/product', product.toJson());
      return Product.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du produit: $e');
      rethrow;
    }
  }

  // Mettre à jour un produit existant
  static Future<Product> updateProduct(Product product) async {
    try {
      if (product.id == null) {
        throw Exception('L\'ID du produit est requis pour la mise à jour');
      }

      final response =
          await ApiService.put('/product/${product.id}', product.toJson());
      return Product.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du produit: $e');
      rethrow;
    }
  }

  // Supprimer un produit
  static Future<bool> deleteProduct(String id) async {
    try {
      // Ajouter un timeout pour éviter le chargement infini
      final response = await ApiService.delete('/product/$id').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Si timeout, on considère que l'opération peut avoir réussi
          debugPrint(
              'Timeout lors de la suppression du produit, l\'opération pourrait quand même avoir réussi');
          return {'success': true, 'timeout': true};
        },
      );
      // Considère la suppression comme réussie même si la réponse ne contient pas de propriété 'success'
      // L'absence d'exception signifie que la requête s'est exécutée correctement
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du produit: $e');
      return false;
    }
  }
}
