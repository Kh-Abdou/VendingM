import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/notification.dart';

class NotificationService {
  final String baseUrl;

  // Constructeur avec l'URL de base de l'API
  NotificationService({required this.baseUrl});

  // Récupérer les notifications d'un utilisateur
  Future<List<Notification>> getUserNotifications(String userId,
      {String? type, String? status}) async {
    try {
      // Afficher plus d'informations de débogage
      print('🔍 Débogage NotificationService:');
      print('🔌 URL de base: $baseUrl');
      print('👤 ID Utilisateur: $userId');

      // Construire l'URL avec les paramètres
      String url = '$baseUrl/notification/$userId';

      // Ajouter les paramètres de requête si fournis
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      print('🔗 URL complète: $url');

      // Effectuer la requête HTTP avec un timeout
      print('🚀 Envoi de la requête...');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15), // Augmenter le timeout à 15 secondes
        onTimeout: () {
          print('⏱️ Timeout après 15 secondes');
          throw TimeoutException(
              'La connexion a pris trop de temps. Vérifiez votre serveur backend.');
        },
      );

      // Afficher le code de statut et le corps de la réponse
      print('📊 Code de statut: ${response.statusCode}');
      print(
          '📄 Corps de la réponse: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}${response.body.length > 200 ? '...' : ''}');

      if (response.statusCode == 200) {
        // Essayer de décoder la réponse JSON
        try {
          final Map<String, dynamic> data = json.decode(response.body);

          // Vérifier si la structure contient le champ 'notifications'
          if (data.containsKey('notifications')) {
            final List<dynamic> notificationsJson = data['notifications'] ?? [];
            print(
                '📱 Nombre de notifications reçues: ${notificationsJson.length}');

            // Afficher un aperçu des notifications reçues
            if (notificationsJson.isNotEmpty) {
              print('📝 Aperçu de la première notification:');
              print(json.encode(notificationsJson.first).substring(
                  0,
                  json.encode(notificationsJson.first).length > 100
                      ? 100
                      : json.encode(notificationsJson.first).length));
            }

            return notificationsJson
                .map((json) => Notification.fromJson(json))
                .toList();
          } else {
            // Si le champ 'notifications' n'existe pas, essayer d'adapter la réponse
            print('⚠️ Champ "notifications" non trouvé dans la réponse');

            // Vérifier si la réponse est directement un tableau de notifications
            if (data is List) {
              print('🔄 La réponse est un tableau direct, on l\'adapte');
              return (data as List<dynamic>)
                  .map((json) =>
                      Notification.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else if (data.containsKey('data') && data['data'] is List) {
              // Certaines API utilisent un champ 'data' pour les résultats
              print(
                  '🔄 Utilisation du champ "data" comme source de notifications');
              final List<dynamic> notificationsJson = data['data'];
              return notificationsJson
                  .map((json) => Notification.fromJson(json))
                  .toList();
            } else {
              // Dernier recours: tenter de traiter la réponse comme une seule notification
              print(
                  '🔄 Tentative de traiter la réponse comme une seule notification');
              try {
                final notification = Notification.fromJson(data);
                return [notification];
              } catch (e) {
                print('❌ Impossible d\'adapter la réponse: $e');
                throw FormatException('Format de réponse incompatible: $e');
              }
            }
          }
        } on FormatException catch (e) {
          print('❌ Erreur de décodage JSON: $e');
          print('📄 Réponse non-JSON: ${response.body}');
          throw FormatException(
              'Format de réponse invalide. La réponse n\'est pas un JSON valide: $e');
        }
      } else {
        // En cas d'erreur HTTP, afficher plus de détails
        print('❌ Échec de la requête: ${response.statusCode}');
        print('📄 Corps de l\'erreur: ${response.body}');
        throw HttpException(
            'Échec du chargement des notifications: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('🔴 Erreur de socket: $e');
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez que le serveur backend est bien démarré et accessible à l\'adresse $baseUrl');
    } on TimeoutException catch (e) {
      print('🔴 Timeout: $e');
      throw Exception(
          'La connexion au serveur a expiré. Vérifiez que le serveur backend est bien démarré et accessible.');
    } on HttpException catch (e) {
      print('🔴 Erreur HTTP: $e');
      throw Exception('$e');
    } on FormatException catch (e) {
      print('🔴 Erreur de format: $e');
      throw Exception(
          'Format de réponse invalide. Vérifiez le serveur backend.');
    } catch (e) {
      print('🔴 Erreur inattendue: $e');
      throw Exception('Erreur lors de la récupération des notifications: $e');
    }
  }

  // Récupérer le nombre de notifications non lues
  Future<int> getUnreadCount(String userId) async {
    try {
      print(
          '🔌 Tentative de connexion pour le compteur: $baseUrl/notification/count/$userId');
      final response = await http.get(
        Uri.parse('$baseUrl/notification/count/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
              'La connexion a pris trop de temps pour le compteur.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw HttpException(
            'Échec du chargement du décompte des notifications: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('🔴 Erreur de socket pour le compteur: $e');
      // En cas d'erreur de connexion, on retourne 0 pour ne pas bloquer l'interface
      return 0;
    } catch (e) {
      print(
          '🔴 Erreur lors de la récupération du décompte des notifications: $e');
      return 0; // Retourner 0 par défaut en cas d'erreur pour éviter de bloquer l'interface
    }
  }

  // Marquer les notifications comme lues
  Future<void> markNotificationsAsRead(String userId,
      [List<String>? notificationIds]) async {
    try {
      final Map<String, dynamic> body = {
        'userId': userId,
      };

      if (notificationIds != null && notificationIds.isNotEmpty) {
        body['notificationIds'] = notificationIds;
      }

      final response = await http
          .put(
        Uri.parse('$baseUrl/notification/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
              'La connexion a pris trop de temps pour marquer comme lu.');
        },
      );

      if (response.statusCode != 200) {
        throw HttpException(
            'Échec pour marquer les notifications comme lues: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('🔴 Erreur de socket pour marquer comme lu: $e');
      throw Exception(
          'Impossible de se connecter au serveur pour marquer les notifications comme lues.');
    } catch (e) {
      print('🔴 Erreur lors du marquage des notifications comme lues: $e');
      throw Exception(
          'Erreur lors du marquage des notifications comme lues: $e');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() {
    return message;
  }
}
