import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // URL de base de l'API (adresse du serveur backend)
  static const String baseUrl =
      'http://192.168.86.32:5000'; // URL pour appareil physique

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

  // Méthode pour uploader un fichier avec des champs de formulaire
  static Future<dynamic> uploadFile(String endpoint, Map<String, String> fields,
      String filePath, String fileField) async {
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    try {
      var request = http.MultipartRequest('POST', uri);

      // Ajouter les champs de formulaire
      request.fields.addAll(fields);

      // Ajouter le fichier s'il existe
      if (filePath.isNotEmpty) {
        // Get file extension and ensure it's lowercase
        final extension = path.extension(filePath).toLowerCase();
        // Get MIME type from file
        final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';

        debugPrint('Uploading file: $filePath');
        debugPrint('File extension: $extension');
        debugPrint('Detected MIME type: $mimeType');

        // Add the file to the request
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            filePath,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      debugPrint('Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      debugPrint('Error during upload: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Méthode pour mettre à jour un fichier avec des champs de formulaire
  static Future<dynamic> updateWithFile(String endpoint,
      Map<String, String> fields, String filePath, String fileField) async {
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    try {
      var request = http.MultipartRequest('PUT', uri);

      // Ajouter les champs de formulaire
      request.fields.addAll(fields);

      // Ajouter le fichier s'il existe
      if (filePath.isNotEmpty) {
        // Get file extension and ensure it's lowercase
        final extension = path.extension(filePath).toLowerCase();
        // Get MIME type from file
        final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';

        debugPrint('Uploading file: $filePath');
        debugPrint('File extension: $extension');
        debugPrint('Detected MIME type: $mimeType');

        // Add the file to the request
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            filePath,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      debugPrint('Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      debugPrint('Error during update: $e');
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
