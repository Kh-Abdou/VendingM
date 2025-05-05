import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../client_page/notification_page.dart';
import '../services/notification_service.dart';
import '../providers/notification_provider.dart';

// API service to handle notification endpoints
class NotificationService {
  final String baseUrl;

  NotificationService({required this.baseUrl});

  // Get user notifications
  Future<Map<String, dynamic>> getUserNotifications(String userId,
      {int page = 1, int limit = 20, String? type, String? status}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/users/$userId/notifications')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load notifications: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Mark notifications as read
  Future<void> markNotificationsAsRead(String userId,
      {List<String>? notificationIds}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'notificationIds': notificationIds,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to mark notifications as read: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking notifications as read: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/notifications/unread-count'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        throw Exception('Failed to get unread count: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }
}

// NotificationRepository to handle app-level notification logic
class NotificationRepository {
  final NotificationService _service;

  NotificationRepository(this._service, {required String apiUrl});

  // Convert backend notification to app's NotificationItem
  NotificationItem _mapToNotificationItem(Map<String, dynamic> data) {
    final type = data['type'] == 'TRANSACTION'
        ? NotificationType.transaction
        : NotificationType.code;

    return NotificationItem(
      message: data['message'] ?? '',
      date: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      type: type,
      montant: data['amount'] != null
          ? double.parse(data['amount'].toString())
          : null,
      isRead: data['status'] == 'READ',
    );
  }

  // Get user notifications
  Future<List<NotificationItem>> getUserNotifications(
    String userId, {
    String? type,
  }) async {
    final response = await _service.getUserNotifications(
      userId,
      type: type,
    );

    final List<dynamic> notificationsData = response['notifications'];
    return notificationsData
        .map((data) => _mapToNotificationItem(data))
        .toList();
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _service.markNotificationsAsRead(
      userId,
      notificationIds: [notificationId],
    );
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
class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository;
  final String userId;

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  NotificationProvider({
    required NotificationRepository repository,
    required this.userId,
    required NotificationService service,
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

  // Fetch all notifications
  Future<void> fetchNotifications() async {
    try {
      _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
      print('❌ Error fetching notifications: $e');
    }
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
  Future<void> markAsRead(NotificationItem notification) async {
    try {
      // Assuming we have an ID in the backend
      // In real implementation, you need to store the ID from the backend
      await _repository.markAsRead(userId, 'notification_id_here');

      // Update locally
      final index = _notifications.indexOf(notification);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
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

// Usage example:
// 
// final service = NotificationService(baseUrl: 'https://your-api-url.com/api');
// final repository = NotificationRepository(service);
// final provider = NotificationProvider(repository: repository, userId: 'user_id_here');
//
// Then use Provider or ChangeNotifierProvider in your app:
// 
// ChangeNotifierProvider(
//   create: (context) => NotificationProvider(
//     repository: repository,
//     userId: 'user_id_here',
//   ),
//   child: NotificationPage(),
// ),