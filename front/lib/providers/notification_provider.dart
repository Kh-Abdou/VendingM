import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service;
  String userId; // Modifié pour ne plus être final et pouvoir être changé

  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  bool _isRefreshing = false; // Flag to track if a refresh is in progress

  NotificationProvider({
    required NotificationService service,
    required this.userId,
  }) : _service = service {
    // Charger les notifications au démarrage
    loadNotifications();

    // Configurer un minuteur pour rafraîchir les notifications périodiquement (toutes les 60 secondes au lieu de 30)
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      // Only refresh if no refresh is currently happening
      if (!_isRefreshing) {
        loadNotifications();
      }
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

  // Méthode pour mettre à jour l'ID utilisateur
  void updateUserId(String newUserId) {
    if (userId != newUserId) {
      userId = newUserId;
      print('🔄 ID utilisateur mis à jour: $userId');
      // Rafraîchir les notifications pour le nouvel utilisateur
      loadNotifications();
    }
  }

  // Charger toutes les notifications
  Future<void> loadNotifications() async {
    // If a refresh is already in progress, don't start another one
    if (_isRefreshing) {
      print('🚫 Une opération de rafraîchissement est déjà en cours');
      return;
    }
    
    _isLoading = true;
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      final notifications = await _service.getUserNotifications(userId).timeout(
        const Duration(seconds: 20), // Increased timeout duration
        onTimeout: () {
          throw TimeoutException('La connexion a pris trop de temps. Vérifiez votre connexion réseau.');
        },
      );
      
      _notifications = notifications;
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
      
      // Log the error for debugging
      print('❌ Erreur lors du chargement des notifications: $e');
      
      // Reset refresh state after a delay to allow retrying
      Future.delayed(const Duration(seconds: 5), () {
        _isRefreshing = false;
      });
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      // Optimistically update UI first
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // Create a copy of the notification with updated status
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

      // Then update on the server
      await _service.markNotificationsAsRead(userId, [notificationId]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ Timeout lors du marquage comme lu, mais l\'UI est mise à jour');
          // We don't throw here because the UI is already updated
          return;
        },
      );
    } catch (e) {
      print('⚠️ Erreur lors du marquage de la notification comme lue: $e');
      // We don't revert the UI change to avoid confusion
      // but we log the error for debugging
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      // Optimistically update UI first
      final originalNotifications = List<Notification>.from(_notifications);
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

      // Then update on the server
      await _service.markNotificationsAsRead(userId).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ Timeout lors du marquage de tout comme lu, mais l\'UI est mise à jour');
          return;
        },
      );
    } catch (e) {
      print('⚠️ Erreur lors du marquage de toutes les notifications comme lues: $e');
      // We don't revert the UI change to avoid confusion
    }
  }

  // Forcer le rafraîchissement des notifications
  Future<void> forceRefresh() async {
    // If a refresh is already in progress, don't start another one
    if (_isRefreshing) {
      print('🚫 Une opération de rafraîchissement est déjà en cours');
      
      // Force reset the refresh flag after a delay to recover from potential deadlocks
      Future.delayed(const Duration(seconds: 3), () {
        _service.resetRequestFlag();
        _isRefreshing = false;
      });
      
      return;
    }
    
    print('🔄 Forçage du rafraîchissement des notifications pour l\'utilisateur $userId');
    
    _isLoading = true;
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel existing timer to avoid overlapping refreshes
      _refreshTimer?.cancel();

      // Récupérer les notifications fraîches du serveur
      final notifications = await _service.getUserNotifications(userId).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('La connexion a pris trop de temps. Vérifiez votre connexion réseau.');
        },
      );

      // Mettre à jour la liste locale
      _notifications = notifications;
      print('📱 ${notifications.length} notifications reçues du serveur');

      // Configurer un nouveau timer
      _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (!_isRefreshing) {
          loadNotifications();
        }
      });

      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement forcé: $e');
      _error = e.toString();
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
      
      // Reset service request flag to prevent deadlocks
      _service.resetRequestFlag();
      
      // Reset refresh state after a delay to allow retrying
      Future.delayed(const Duration(seconds: 5), () {
        _isRefreshing = false;
      });
      
      rethrow; // Propager l'erreur
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
