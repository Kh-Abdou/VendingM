import 'package:flutter/material.dart';
import 'api_service.dart';

class Chariot {
  final String? id;
  final String name;
  final int capacity;
  final String status;
  final String? currentProductType;
  final List<String> currentProducts;

  Chariot({
    this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.currentProductType,
    required this.currentProducts,
  });

  factory Chariot.fromJson(Map<String, dynamic> json) {
    List<String> productsIds = [];
    if (json['currentProducts'] != null) {
      productsIds = (json['currentProducts'] as List)
          .map((item) => item is String
              ? item
              : item is Map
                  ? item['_id'] ?? item['id']
                  : item.toString())
          .cast<String>()
          .toList();
    }

    return Chariot(
      id: json['_id'],
      name: json['name'],
      capacity: json['capacity'],
      status: json['status'],
      currentProductType: json['currentProductType'],
      currentProducts: productsIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'capacity': capacity,
      'status': status,
      if (currentProductType != null) 'currentProductType': currentProductType,
      'currentProducts': currentProducts,
    };
  }
}

class ChariotService {
  // Récupérer tous les chariots
  static Future<List<Chariot>> getAllChariots() async {
    try {
      final response = await ApiService.get('/chariot');

      if (response is List) {
        return response.map((chariot) => Chariot.fromJson(chariot)).toList();
      } else if (response is Map && response.containsKey('chariots')) {
        final chariots = response['chariots'] as List;
        return chariots.map((chariot) => Chariot.fromJson(chariot)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des chariots: $e');
      rethrow;
    }
  }

  // Récupérer un chariot par son ID
  static Future<Chariot> getChariotById(String id) async {
    try {
      final response = await ApiService.get('/chariot/$id');
      return Chariot.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du chariot: $e');
      rethrow;
    }
  }

  // Récupérer les chariots par type de produit
  static Future<List<Chariot>> getChariotsByProductType(
      String productType) async {
    try {
      final response =
          await ApiService.get('/chariot/by-product-type/$productType');

      if (response is List) {
        return response.map((chariot) => Chariot.fromJson(chariot)).toList();
      } else if (response is Map && response.containsKey('chariots')) {
        final chariots = response['chariots'] as List;
        return chariots.map((chariot) => Chariot.fromJson(chariot)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des chariots par type de produit: $e');
      rethrow;
    }
  }

  // Créer un nouveau chariot
  static Future<Chariot> createChariot(Chariot chariot) async {
    try {
      final response = await ApiService.post('/chariot', chariot.toJson());

      // Vérifier si la réponse contient une erreur concernant un nom en double
      if (response is Map &&
          response.containsKey('message') &&
          response['message']
              .toString()
              .contains('Un chariot avec ce nom existe déjà')) {
        throw Exception(response['message']);
      }

      return Chariot.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de la création du chariot: $e');
      rethrow;
    }
  }

  // Mettre à jour un chariot
  static Future<Chariot> updateChariot(Chariot chariot) async {
    try {
      if (chariot.id == null) {
        throw Exception('L\'ID du chariot est requis pour la mise à jour');
      }

      final response =
          await ApiService.put('/chariot/${chariot.id}', chariot.toJson());
      return Chariot.fromJson(response);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du chariot: $e');
      rethrow;
    }
  }

  // Ajouter un produit à un chariot
  static Future<Map<String, dynamic>> addProductToChariot(
      String chariotId, String productId) async {
    try {
      final response = await ApiService.post(
          '/chariot/$chariotId/products', {'productId': productId});

      return {
        'success': true,
        'message':
            response['message'] ?? 'Produit ajouté au chariot avec succès',
        'data': response
      };
    } catch (e) {
      // Extraire le message et le code d'erreur de la réponse API
      String errorMessage = 'Erreur lors de l\'ajout du produit au chariot';
      String errorCode = 'UNKNOWN_ERROR';

      if (e is Map && e.containsKey('error')) {
        errorCode = e['error'] ?? 'UNKNOWN_ERROR';
      }

      if (e is Map && e.containsKey('message')) {
        errorMessage = e['message'];
      } else if (e.toString().contains('capacité maximale')) {
        errorMessage = 'La capacité maximale du chariot est atteinte';
        errorCode = 'CAPACITY_EXCEEDED';
      } else if (e.toString().contains('type de produit différent')) {
        errorMessage = 'Le chariot contient déjà un type de produit différent';
        errorCode = 'DIFFERENT_PRODUCT_TYPE';
      } else if (e.toString().contains('déjà dans le chariot')) {
        errorMessage = 'Ce produit est déjà dans le chariot';
        errorCode = 'PRODUCT_ALREADY_IN_CHARIOT';
      }

      debugPrint('Erreur lors de l\'ajout du produit au chariot: $e');
      return {
        'success': false,
        'message': errorMessage,
        'error': errorCode,
        'details': e.toString()
      };
    }
  }

  // Retirer un produit d'un chariot avec un délai maximum
  static Future<Map<String, dynamic>> removeProductFromChariot(
      String chariotId, String productId) async {
    try {
      // Ajouter un timeout pour éviter le chargement infini
      final response =
          await ApiService.delete('/chariot/$chariotId/products/$productId')
              .timeout(
        const Duration(seconds: 5),
        onTimeout: () => {
          'message':
              'La requête a pris trop de temps, mais l\'opération pourrait avoir réussi',
          'timeout': true
        },
      );

      return {
        'success': response['message'] != null || response['timeout'] == true,
        'timeout': response['timeout'] == true,
        'message':
            response['message'] ?? 'Produit retiré du chariot avec succès',
      };
    } catch (e) {
      debugPrint('Erreur lors du retrait du produit du chariot: $e');
      return {
        'success': false,
        'message': 'Erreur lors du retrait du produit du chariot',
        'error': e.toString()
      };
    }
  }

  // Vider un chariot
  static Future<bool> emptyChariot(String chariotId) async {
    try {
      final response = await ApiService.post('/chariot/$chariotId/empty', {});
      return response['message'] != null;
    } catch (e) {
      debugPrint('Erreur lors de la vidange du chariot: $e');
      return false;
    }
  }

  // Supprimer un chariot
  static Future<bool> deleteChariot(String chariotId) async {
    try {
      final response = await ApiService.delete('/chariot/$chariotId');
      return response['message'] != null;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du chariot: $e');
      return false;
    }
  }

  // Récupérer les chariots disponibles pour un type de produit spécifique
  static Future<List<Chariot>> getAvailableChariotsForProduct(
      String productName) async {
    try {
      // Récupérer tous les chariots
      final allChariots = await getAllChariots();

      // Filtrer les chariots disponibles ou avec le même type de produit
      return allChariots.where((chariot) {
        return chariot.status == 'Disponible' ||
            (chariot.currentProductType == productName &&
                chariot.status != 'Complet');
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des chariots disponibles: $e');
      rethrow;
    }
  }
}
