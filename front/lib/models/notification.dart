class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'STOCK', 'MAINTENANCE', 'TRANSACTION', 'CODE'
  final String status; // 'READ', 'UNREAD'
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final int priority;
  final double? amount; // Add the amount field from the backend
  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    this.metadata,
    this.priority = 3,
    this.amount,
  });
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      metadata: json['metadata'],
      priority: json['priority'] ?? 3,
      amount: json['amount'] != null ? json['amount'].toDouble() : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      'priority': priority,
      'amount': amount,
    };
  }

  // Retourne une priorité sous forme de chaîne pour l'interface utilisateur
  String getPriorityString() {
    switch (priority) {
      case 5:
        return 'critical';
      case 4:
        return 'high';
      case 3:
        return 'warning';
      case 2:
        return 'info';
      case 1:
        return 'low';
      default:
        return 'warning';
    }
  }

  // Retourne true si la notification est une notification de stock
  bool get isStockNotification => type == 'STOCK';

  // Retourne true si la notification est une notification technique/maintenance
  bool get isTechnicalNotification => type == 'MAINTENANCE';

  // Retourne true si la notification est non lue
  bool get isUnread => status == 'UNREAD';
}
