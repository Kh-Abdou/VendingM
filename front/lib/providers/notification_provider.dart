import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  final String userId;

  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  NotificationProvider({
    required NotificationService service,
    required this.userId,
  }) : _service = service {
    // Charger les notifications au démarrage
    loadNotifications();

    // Configurer un minuteur pour rafraîchir les notifications périodiquement (toutes les 30 secondes)
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      loadNotifications();
    });
  }

  // Getters
  List<Notification> get notifications => _notifications;
  List<Notification> get stockNotifications =>
      _notifications.where((n) => n.isStockNotification).toList();
  List<Notification> get technicalNotifications =>
      _notifications.where((n) => n.isTechnicalNotification).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  // Retourne l'URL de l'API utilisée pour le débogage
  String getApiUrl() => _service.baseUrl;

  // Charger toutes les notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notifications = await _service.getUserNotifications(userId);
      _notifications = notifications;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markNotificationsAsRead(userId, [notificationId]);

      // Mettre à jour localement
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // Créer une copie de la notification avec le statut mis à jour
        final notification = _notifications[index];
        final updatedNotification = Notification(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          status: 'READ',
          createdAt: notification.createdAt,
          metadata: notification.metadata,
          priority: notification.priority,
        );

        _notifications[index] = updatedNotification;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      await _service.markNotificationsAsRead(userId);

      // Mettre à jour localement
      _notifications = _notifications
          .map((notification) => Notification(
                id: notification.id,
                userId: notification.userId,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                status: 'READ',
                createdAt: notification.createdAt,
                metadata: notification.metadata,
                priority: notification.priority,
              ))
          .toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Forcer le rafraîchissement des notifications (utile pour le débogage)
  Future<void> forceRefresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(
          '🔄 Forçage du rafraîchissement des notifications pour l\'utilisateur $userId');
      final notifications = await _service.getUserNotifications(userId);
      _notifications = notifications;
      print('📱 ${notifications.length} notifications reçues du serveur');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement forcé: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e; // Propager l'erreur
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
