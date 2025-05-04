import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  final Color primaryColor;
  final Color buttonColor;
  final Function(int notificationCount) onNotificationStatusChanged;

  const NotificationsPage({
    Key? key,
    required this.primaryColor,
    required this.buttonColor,
    required this.onNotificationStatusChanged,
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Données simulées des notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Niveau de stock bas',
      'message': 'Le produit Cola est presque épuisé (5 restants)',
      'date': '2023-12-01',
      'isRead': false,
      'type': 'stock',
      'priority': 'warning', // warning, critical, info
    },
    {
      'id': 2,
      'title': 'Problème technique',
      'message': 'Le distributeur signale une erreur de paiement',
      'date': '2023-12-02',
      'isRead': false,
      'type': 'technical',
      'priority': 'critical',
    },
    {
      'id': 3,
      'title': 'Maintenance prévue',
      'message': 'Maintenance planifiée pour le distributeur le 10/12',
      'date': '2023-12-03',
      'isRead': true,
      'type': 'technical',
      'priority': 'info',
    },
    {
      'id': 4,
      'title': 'Stock critique',
      'message': 'Le produit Chocolat est presque épuisé (2 restants)',
      'date': '2023-12-04',
      'isRead': false,
      'type': 'stock',
      'priority': 'critical',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Utiliser Future.microtask pour retarder l'appel après le build
    Future.microtask(() {
      if (mounted) {
        _updateNotificationCount();
      }
    });
  }

  void _updateNotificationCount() {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    widget.onNotificationStatusChanged(unreadCount);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: widget.primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications (${_notifications.where((n) => !n['isRead']).length} nouvelles)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            for (var notification in _notifications) {
                              notification['isRead'] = true;
                            }
                            _updateNotificationCount();
                          });
                        },
                        child: const Text('Tout marquer comme lu'),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: widget.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Techniques'),
                    Tab(text: 'Stock'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Problèmes techniques
                _buildNotificationsList('technical'),
                // Tab 2: Problèmes de stock
                _buildNotificationsList('stock'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String type) {
    final filteredNotifications =
        _notifications.where((n) => n['type'] == type).toList();

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'technical'
                  ? Icons.build_circle_outlined
                  : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification ${type == 'technical' ? 'technique' : 'de stock'}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];

        // Définir l'icône et la couleur selon le type et la priorité
        IconData iconData;
        Color iconColor;

        if (type == 'technical') {
          switch (notification['priority']) {
            case 'critical':
              iconData = Icons.error;
              iconColor = Colors.red;
              break;
            case 'warning':
              iconData = Icons.warning;
              iconColor = Colors.amber;
              break;
            default:
              iconData = Icons.build;
              iconColor = Colors.blue;
          }
        } else {
          // stock
          switch (notification['priority']) {
            case 'critical':
              iconData = Icons.inventory_2;
              iconColor = Colors.red;
              break;
            case 'warning':
              iconData = Icons.inventory;
              iconColor = Colors.amber;
              break;
            default:
              iconData = Icons.inventory_outlined;
              iconColor = Colors.green;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          color: notification['isRead'] ? null : Colors.blue.withOpacity(0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification['isRead']
                  ? Colors.grey.withOpacity(0.2)
                  : iconColor.withOpacity(0.2),
              child: Icon(
                iconData,
                color: notification['isRead'] ? Colors.grey : iconColor,
              ),
            ),
            title: Text(
              notification['title'],
              style: TextStyle(
                fontWeight: notification['isRead']
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification['message']),
                Text(
                  'Date: ${notification['date']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Afficher plus d'options pour cette notification
              },
            ),
            onTap: () {
              setState(() {
                notification['isRead'] = true;
                _updateNotificationCount();
              });
              // Afficher les détails de la notification
            },
          ),
        );
      },
    );
  }

  // Method to add a new notification (can be called from outside)
  void addNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.insert(0, notification);
      _updateNotificationCount();
    });
  }
}
