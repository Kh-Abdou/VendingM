import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/notification.dart' as notification_model;
import '../services/notification_service.dart' as existing_service;
import '../providers/notification_provider.dart' as existing_provider;

// API service to handle notification endpoints
class NotificationService {
  final String baseUrl;

  NotificationService({required this.baseUrl});

  // Get user notifications
  Future<List<notification_model.Notification>> getUserNotifications(
      String userId,
      {int page = 1,
      int limit = 20,
      String? type,
      String? status}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/notification/$userId')
          .replace(queryParameters: queryParams);

      print('🔗 URL complète: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Timeout après 15 secondes');
          throw TimeoutException(
              'La connexion a pris trop de temps. Vérifiez votre serveur backend.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('notifications')) {
          final List<dynamic> notificationsJson = data['notifications'] ?? [];
          return notificationsJson
              .map((json) => notification_model.Notification.fromJson(json))
              .toList();
        } else if (data is List) {
          return (data as List<dynamic>)
              .map((json) => notification_model.Notification.fromJson(
                  json as Map<String, dynamic>))
              .toList();
        } else if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> notificationsJson = data['data'];
          return notificationsJson
              .map((json) => notification_model.Notification.fromJson(json))
              .toList();
        } else {
          try {
            final notification = notification_model.Notification.fromJson(data);
            return [notification];
          } catch (e) {
            throw FormatException('Format de réponse incompatible: $e');
          }
        }
      } else {
        throw Exception(
            'Failed to load notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des notifications: $e');
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Mark notifications as read
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
        throw Exception(
            'Failed to mark notifications as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur lors du marquage des notifications comme lues: $e');
      throw Exception('Error marking notifications as read: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
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
        throw Exception(
            'Failed to get unread count: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print(
          '❌ Erreur lors de la récupération du décompte des notifications: $e');
      // En cas d'erreur de connexion, on retourne 0 pour ne pas bloquer l'interface
      return 0;
    }
  }
}

// Create a model for notifications if not using the existing one
class NotificationItem {
  final String message;
  final DateTime date;
  final NotificationType type;
  final double? montant;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String? id; // Adding ID to track notifications from backend

  NotificationItem({
    required this.message,
    required this.date,
    required this.type,
    this.montant,
    required this.isRead,
    this.metadata,
    this.id,
  });

  NotificationItem copyWith({
    String? message,
    DateTime? date,
    NotificationType? type,
    double? montant,
    bool? isRead,
    Map<String, dynamic>? metadata,
    String? id,
  }) {
    return NotificationItem(
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      montant: montant ?? this.montant,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      id: id ?? this.id,
    );
  }

  // Convert from the model in the existing system
  factory NotificationItem.fromNotificationModel(
      notification_model.Notification notification) {
    NotificationType type;
    switch (notification.type) {
      case 'TRANSACTION':
        type = NotificationType.transaction;
        break;
      case 'CODE':
        type = NotificationType.code;
        break;
      default:
        type = NotificationType.other;
    }

    return NotificationItem(
      id: notification.id,
      message: notification.message,
      date: notification.createdAt,
      type: type,
      montant: notification.metadata != null &&
              notification.metadata!.containsKey('montant')
          ? double.tryParse(notification.metadata!['montant'].toString())
          : null,
      isRead: notification.status == 'READ',
      metadata: notification.metadata,
    );
  }

  // Convert to the model in the existing system
  notification_model.Notification toNotificationModel() {
    String notificationType;
    switch (type) {
      case NotificationType.transaction:
        notificationType = 'TRANSACTION';
        break;
      case NotificationType.code:
        notificationType = 'CODE';
        break;
      default:
        notificationType = 'OTHER';
    }

    return notification_model.Notification(
      id: id ?? 'temp_id',
      userId: 'current_user', // This should be replaced with the actual user ID
      title: message.split('\n').first, // Use first line as title
      message: message,
      type: notificationType,
      status: isRead ? 'READ' : 'UNREAD',
      createdAt: date,
      metadata: metadata ?? {},
    );
  }
}

enum NotificationType {
  transaction,
  code,
  other,
}

// NotificationRepository to handle app-level notification logic
class NotificationRepository {
  final NotificationService _service;

  NotificationRepository(this._service);

  // Convert backend notification to app's NotificationItem
  NotificationItem _mapToNotificationItem(
      notification_model.Notification notification) {
    return NotificationItem.fromNotificationModel(notification);
  }

  // Get user notifications
  Future<List<NotificationItem>> getUserNotifications(
    String userId, {
    String? type,
  }) async {
    final notifications = await _service.getUserNotifications(
      userId,
      type: type,
    );

    return notifications
        .map((notification) => _mapToNotificationItem(notification))
        .toList();
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _service.markNotificationsAsRead(userId, [notificationId]);
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    await _service.markNotificationsAsRead(userId);
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    return await _service.getUnreadCount(userId);
  }
}

// NotificationProvider to manage notification state with ChangeNotifier
class ClientNotificationProvider with ChangeNotifier {
  final NotificationRepository _repository;
  final String userId;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _error;

  ClientNotificationProvider({
    required NotificationRepository repository,
    required this.userId,
  }) : _repository = repository {
    // Initialize by loading notifications
    fetchNotifications();
    fetchUnreadCount();
  }

  // Getters
  List<NotificationItem> get notifications => _notifications;
  List<NotificationItem> get transactionNotifications => _notifications
      .where((n) => n.type == NotificationType.transaction)
      .toList();
  List<NotificationItem> get codeNotifications =>
      _notifications.where((n) => n.type == NotificationType.code).toList();
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get error => _error;

  // Fetch all notifications
  Future<void> fetchNotifications() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('📱 Fetching notifications for user: $userId');

      _notifications = await _repository.getUserNotifications(userId);

      print('📱 Received ${_notifications.length} notifications from server');
      // Debug: Print first notification if available
      if (_notifications.isNotEmpty) {
        print('📱 First notification: ${_notifications.first.message}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error fetching notifications: $e');
    }
  }

  // Force refresh notifications
  Future<void> forceRefresh() async {
    await fetchNotifications();
  }

  // Fetch unread count
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(userId, notificationId);

      // Update locally
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead(userId);

      // Update locally
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
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

// Usage example:
/* 
final service = NotificationService(baseUrl: 'https://api.example.com');
final repository = NotificationRepository(service);
final provider = ClientNotificationProvider(
  repository: repository,
  userId: 'user_id_here',
);

// Then use Provider or ChangeNotifierProvider in your app:
ChangeNotifierProvider(
  create: (context) => ClientNotificationProvider(
    repository: repository,
    userId: 'user_id_here',
  ),
  child: NotificationPage(),
),
*/