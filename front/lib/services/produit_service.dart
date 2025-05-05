import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produit.dart';
import 'dart:developer' as developer;

class ProduitService {
  // Utiliser la même URL de base que celle définie dans main.dart
  final String baseUrl;

  ProduitService({required this.baseUrl});

  Future<List<Produit>> getProducts() async {
    try {
      // Correction du chemin d'API pour correspondre aux routes du backend
      final response = await http.get(Uri.parse('$baseUrl/product'));

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = json.decode(response.body);

        // Afficher les données JSON brutes pour le débogage
        developer.log('Données de produits reçues: ${response.body}',
            name: 'ProduitService');

        // Afficher également le premier produit s'il existe
        if (productsJson.isNotEmpty) {
          developer.log('Premier produit: ${productsJson[0]}',
              name: 'ProduitService');
        }

        return productsJson.map((json) => Produit.fromJson(json)).toList();
      } else {
        throw Exception(
            'Erreur lors de la récupération des produits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
