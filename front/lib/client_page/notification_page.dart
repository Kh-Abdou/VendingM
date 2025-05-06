import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart' as notification_model;
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // Forcer le rafraîchissement des notifications au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).forceRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser le provider
    final notificationProvider = Provider.of<NotificationProvider>(context);

    if (notificationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notificationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notificationProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: () => notificationProvider.forceRefresh(),
            ),
          ],
        ),
      );
    }

    if (notificationProvider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              onPressed: () => notificationProvider.forceRefresh(),
            ),
          ],
        ),
      );
    }

    // Filtrer les notifications par type
    final transactionNotifications = notificationProvider.notifications
        .where((n) => n.type == 'TRANSACTION')
        .toList();

    final codeNotifications = notificationProvider.notifications
        .where((n) => n.type == 'CODE')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black12
                : Colors.white,
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: [
                const Tab(
                  text: 'Commandes',
                  icon: Icon(Icons.shopping_cart),
                ),
                const Tab(
                  text: 'Codes',
                  icon: Icon(Icons.qr_code),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (notificationProvider.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Tout marquer comme lu'),
                    onPressed: () => notificationProvider.markAllAsRead(),
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Vue des commandes (transactions)
                _buildTransactionNotificationsList(
                    context, transactionNotifications, notificationProvider),

                // Vue des codes
                _buildCodeNotificationsList(
                    context, codeNotifications, notificationProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionNotificationsList(
      BuildContext context,
      List<notification_model.Notification> notifications,
      NotificationProvider provider) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text('Aucune notification de commande'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.forceRefresh(),
      child: AnimationLimiter(
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final metadata = notification.metadata ?? {};

            // Formatage de la date
            final dateFormatter = DateFormat('dd/MM/yyyy à HH:mm');
            final formattedDate = dateFormatter.format(notification.createdAt);

            // Récupérer les détails de la commande depuis les métadonnées
            final double montant = metadata['montant']?.toDouble() ?? 0.0;
            final List<dynamic> produitsData = metadata['produits'] ?? [];

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.isUnread
                            ? Colors.green[100]
                            : Colors.grey[200],
                        child: Icon(
                          Icons.receipt,
                          color: notification.isUnread
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(formattedDate),
                      trailing: Text(
                        '${montant.toStringAsFixed(2)} DA',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onExpansionChanged: (expanded) {
                        if (expanded && notification.isUnread) {
                          provider.markAsRead(notification.id);
                        }
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.message,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Détails de la commande:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...produitsData.map<Widget>((produit) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${produit['nom']} x${produit['quantite']}',
                                        ),
                                      ),
                                      Text(
                                        '${(produit['prix'] * produit['quantite']).toStringAsFixed(2)} DA',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${montant.toStringAsFixed(2)} DA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCodeNotificationsList(
      BuildContext context,
      List<notification_model.Notification> notifications,
      NotificationProvider provider) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text('Aucune notification de code'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.forceRefresh(),
      child: AnimationLimiter(
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final metadata = notification.metadata ?? {};

            // Formatage de la date
            final dateFormatter = DateFormat('dd/MM/yyyy à HH:mm');
            final formattedDate = dateFormatter.format(notification.createdAt);

            // Obtenir le statut du code et définir une icône appropriée
            final String codeStatus = metadata['status'] ?? 'generated';
            IconData statusIcon;
            Color statusColor;

            switch (codeStatus.toLowerCase()) {
              case 'used':
                statusIcon = Icons.check_circle;
                statusColor = Colors.green;
                break;
              case 'cancelled':
                statusIcon = Icons.cancel;
                statusColor = Colors.red;
                break;
              case 'expired':
                statusIcon = Icons.timer_off;
                statusColor = Colors.orange;
                break;
              case 'generated':
              default:
                statusIcon = Icons.qr_code;
                statusColor = Colors.blue;
            }

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.isUnread
                            ? statusColor.withOpacity(0.2)
                            : Colors.grey[200],
                        child: Icon(
                          statusIcon,
                          color:
                              notification.isUnread ? statusColor : Colors.grey,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formattedDate),
                          const SizedBox(height: 4),
                          Text(notification.message),
                          if (metadata['code'] != null)
                            Text(
                              'Code: ${metadata['code']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        if (notification.isUnread) {
                          provider.markAsRead(notification.id);
                        }
                      },
                      // Ajouter un badge pour les codes qui sont utilisés ou annulés
                      trailing: _getStatusBadge(codeStatus),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'used':
        return _buildBadge('Utilisé', Colors.green);
      case 'cancelled':
        return _buildBadge('Annulé', Colors.red);
      case 'expired':
        return _buildBadge('Expiré', Colors.orange);
      case 'generated':
        return _buildBadge('Généré', Colors.blue);
      default:
        return _buildBadge(status, Colors.grey);
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
