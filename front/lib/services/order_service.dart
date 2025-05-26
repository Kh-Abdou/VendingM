import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produit.dart';

class OrderService {
  final String baseUrl;

  OrderService({required this.baseUrl});

  // Traiter un paiement avec e-wallet
  Future<Map<String, dynamic>> processPayment({
    required String userId,
    required double amount,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ewallet/payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'products': products,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors du paiement');
      }
    } catch (e) {
      throw Exception('Erreur lors du traitement du paiement: $e');
    }
  }

  // Générer un code pour un paiement différé
  Future<Map<String, dynamic>> generateCode({
    required String userId,
    required double totalAmount,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/code/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'totalAmount': totalAmount,
          'products': products,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erreur lors de la génération du code');
      }
    } catch (e) {
      throw Exception('Erreur lors de la génération du code: $e');
    }
  }

  // Vérifier le solde e-wallet avec paramètre timestamp pour éviter le cache
  Future<double> getEWalletBalance(String userId) async {
    try {
      print('👤 Récupération du solde pour l\'utilisateur: $userId');

      // Add timestamp parameter to prevent caching
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await http.get(
        Uri.parse('$baseUrl/ewallet/$userId?t=$timestamp'),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      print('📡 Statut de la réponse: ${response.statusCode}');
      print('📄 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final balance = data['balance'];

        if (balance != null) {
          // Assurez-vous que le solde est converti en double
          final double balanceValue =
              balance is int ? balance.toDouble() : balance;
          print('💰 Solde récupéré: $balanceValue');
          return balanceValue;
        } else {
          print('⚠️ Solde non trouvé dans la réponse');
          return 0.0;
        }
      } else {
        print(
            '❌ Erreur lors de la récupération du solde: ${response.statusCode}');
        return 0.0; // En cas d'erreur, on suppose que le solde est 0
      }
    } catch (e) {
      print('❌ Exception lors de la récupération du solde: $e');
      return 0.0;
    }
  }

  // Préparer les données des produits pour l'API
  List<Map<String, dynamic>> prepareProductsData(List<ProduitPanier> panier) {
    return panier
        .map((item) => {
              'productId': item.produit.id,
              'quantity': item.quantite,
              'price': item.produit.prix,
            })
        .toList();
  }

  // Vérifier le statut d'une commande
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      // Set a short timeout to allow for frequent polling
      final response = await http.get(
        Uri.parse('$baseUrl/orders/status/$orderId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Timeout lors de la récupération du statut');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ??
            'Erreur lors de la récupération du statut de la commande');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du statut: $e');
    }
  }
}

// Extension pour convertir les produits du panier en format API
extension PanierConverter on List<ProduitPanier> {
  List<Map<String, dynamic>> toApiFormat() {
    return map((item) => {
          'productId': item.produit.id,
          'quantity': item.quantite,
          'price': item.produit.prix,
        }).toList();
  }
}
