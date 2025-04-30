import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../implementation/notification-imp.dart';

enum NotificationType {
  transaction,
  code,
}

class NotificationItem {
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;
  final double? montant;

  NotificationItem({
    required this.message,
    required this.date,
    required this.type,
    this.montant,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? message,
    DateTime? date,
    NotificationType? type,
    double? montant,
    bool? isRead,
  }) {
    return NotificationItem(
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      montant: montant ?? this.montant,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    // Use the provider
    final notificationProvider = Provider.of<NotificationProvider>(context);

    if (notificationProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (notificationProvider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Commandes'),
              Tab(text: 'Codes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Vue des commandes (transactions)
                ListView.separated(
                  itemCount:
                      notificationProvider.transactionNotifications.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final notification =
                        notificationProvider.transactionNotifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          Icons.euro_symbol,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${notification.date.day}/${notification.date.month}/${notification.date.year} ${notification.date.hour}:${notification.date.minute}',
                      ),
                      trailing: notification.montant != null
                          ? Text(
                              '${notification.montant! >= 0 ? '+' : ''}${notification.montant!.toStringAsFixed(2)} DA',
                              style: TextStyle(
                                color: notification.montant! >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                      onTap: () {
                        notificationProvider.markAsRead(notification);
                      },
                    );
                  },
                ),

                // Vue des codes
                ListView.separated(
                  itemCount: notificationProvider.codeNotifications.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final notification =
                        notificationProvider.codeNotifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.qr_code,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${notification.date.day}/${notification.date.month}/${notification.date.year} ${notification.date.hour}:${notification.date.minute}',
                      ),
                      onTap: () {
                        notificationProvider.markAsRead(notification);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
