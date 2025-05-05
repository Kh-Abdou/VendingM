import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart' as app_notification;
import '../providers/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  final Color primaryColor;
  final Color buttonColor;
  final Function(int)?
      onNotificationStatusChanged; // Rendre le callback optionnel

  const NotificationsPage({
    Key? key,
    required this.primaryColor,
    required this.buttonColor,
    this.onNotificationStatusChanged, // Paramètre optionnel
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Forcer le chargement des notifications au démarrage
    _refreshNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    print(
        '🔄 Rafraîchissement des notifications depuis la page'); // Log pour débogage
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Forcer le rechargement via le provider
      await Provider.of<NotificationProvider>(context, listen: false)
          .forceRefresh();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      print('❌ Erreur lors du rafraîchissement: $e'); // Log pour débogage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        // Mettre à jour le compteur de notifications seulement si le callback est fourni
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.onNotificationStatusChanged != null) {
            widget
                .onNotificationStatusChanged!(notificationProvider.unreadCount);
          }
        });

        print(
            '📊 Nombre de notifications: ${notificationProvider.notifications.length}'); // Log pour débogage
        print(
            '🔔 Notifications non lues: ${notificationProvider.unreadCount}'); // Log pour débogage

        // Vérifier si nous sommes en chargement ou s'il y a une erreur
        if (_isLoading) {
          return Center(
              child: CircularProgressIndicator(color: widget.primaryColor));
        }

        if (_error != null) {
          return _buildErrorView(_error!);
        }

        // Vérifier s'il n'y a pas de notifications
        if (notificationProvider.notifications.isEmpty) {
          return _buildEmptyView();
        }

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: widget.primaryColor,
                labelColor: widget.primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(
                      text:
                          'Stock (${notificationProvider.stockNotifications.length})'),
                  Tab(
                      text:
                          'Maintenance (${notificationProvider.technicalNotifications.length})'),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Stock
                    _buildNotificationsList(
                        notificationProvider.stockNotifications, 'stock'),

                    // Tab Maintenance
                    _buildNotificationsList(
                        notificationProvider.technicalNotifications,
                        'maintenance'),
                  ],
                ),
              ),
            ),
            // Afficher les informations de débogage pour aider au diagnostic
            // A supprimer en production
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Infos de débogage',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('API: ${notificationProvider.getApiUrl()}',
                      style: TextStyle(fontSize: 10)),
                  Text('ID Technicien: ${notificationProvider.userId}',
                      style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsList(
      List<app_notification.Notification> notifications, String type) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'stock' ? Icons.inventory : Icons.build,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Aucune notification ${type == 'stock' ? 'de stock' : 'de maintenance'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(app_notification.Notification notification) {
    // Déterminer les couleurs et icônes en fonction de la priorité et du type
    Color priorityColor;
    IconData iconData;

    switch (notification.priority) {
      case 5: // Critique
        priorityColor = Colors.red;
        break;
      case 4: // Élevée
        priorityColor = Colors.orange;
        break;
      case 3: // Moyenne/Avertissement
        priorityColor = Colors.amber;
        break;
      case 2: // Informative
        priorityColor = Colors.blue;
        break;
      case 1: // Basse
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.amber;
    }

    if (notification.isStockNotification) {
      iconData = Icons.inventory;
    } else {
      iconData = Icons.build;
    }

    // Formatage de la date
    final dateStr =
        '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year} ${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: notification.isUnread ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isUnread
            ? BorderSide(color: priorityColor, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (notification.isUnread) {
            // Marquer comme lu
            Provider.of<NotificationProvider>(context, listen: false)
                .markAsRead(notification.id);
          }

          // Afficher les détails
          _showNotificationDetails(notification);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: priorityColor.withOpacity(0.2),
                    child: Icon(iconData, color: priorityColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notification.isUnread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: priorityColor,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                notification.message,
                style: TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.getPriorityString().toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    notification.isUnread ? 'Non lu' : 'Lu',
                    style: TextStyle(
                      color: notification.isUnread ? Colors.red : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(app_notification.Notification notification) {
    Map<String, dynamic> metadata = notification.metadata ?? {};

    // Préparer les détails spécifiques selon le type de notification
    Widget detailsWidget;

    if (notification.isStockNotification) {
      // Détails pour notification de stock
      final productName = metadata['productName'] ?? 'Produit';
      final currentStock = metadata['currentStock']?.toString() ?? 'N/A';

      detailsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Produit:', productName),
          _buildDetailRow('Stock actuel:', '$currentStock unités'),
        ],
      );
    } else {
      // Détails pour notification de maintenance
      final machineId = metadata['machineId'] ?? 'N/A';
      final location = metadata['location'] ?? 'N/A';
      final reason = metadata['reason'] ?? 'Raison non spécifiée';

      detailsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('ID Machine:', machineId),
          _buildDetailRow('Emplacement:', location),
          _buildDetailRow('Raison:', reason),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Reçu le ${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year} à ${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  notification.message,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                detailsWidget,
                SizedBox(height: 30),
                if (notification.isUnread)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<NotificationProvider>(context,
                                listen: false)
                            .markAsRead(notification.id);
                      },
                      child: Text('Marquer comme lu'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Rafraîchir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
    );
  }
}
