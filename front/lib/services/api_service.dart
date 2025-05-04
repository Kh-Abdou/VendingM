import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL de base de l'API (adresse du serveur backend)
  static const String baseUrl =
      'http://10.0.2.2:5000'; // Pour l'émulateur Android
  // Si vous utilisez un appareil physique, utilisez l'IP de votre ordinateur
  // static const String baseUrl = 'http://192.168.x.x:5000';

  // Headers communs pour les requêtes
  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Méthode GET générique
  static Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParams}) async {
    final Uri uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Méthode POST générique
  static Future<dynamic> post(String endpoint, dynamic data) async {
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Méthode PUT générique
  static Future<dynamic> put(String endpoint, dynamic data) async {
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Méthode DELETE générique
  static Future<dynamic> delete(String endpoint) async {
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.delete(uri, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Traitement des réponses HTTP
  static dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        var responseJson = json.decode(response.body);
        return responseJson;
      case 400:
        throw Exception('Mauvaise requête');
      case 401:
        throw Exception('Non autorisé');
      case 403:
        throw Exception('Accès refusé');
      case 404:
        throw Exception('Ressource non trouvée');
      case 500:
      default:
        throw Exception(
            'Erreur serveur: ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}
