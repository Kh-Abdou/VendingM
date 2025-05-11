import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:async';
import '../models/notification.dart' as app_notification;
import '../providers/notification_provider.dart';
import '../providers/hardware_provider.dart'; // Add hardware provider for temperature and humidity

class NotificationsPage extends StatefulWidget {
  final Color primaryColor;
  final Color buttonColor;
  final Function(int)?
      onNotificationStatusChanged; // Rendre le callback optionnel

  const NotificationsPage({
    super.key,
    required this.primaryColor,
    required this.buttonColor,
    this.onNotificationStatusChanged, // Paramètre optionnel
  });

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  // Adding a debounce mechanism to prevent multiple concurrent requests
  bool _isRefreshing = false;

  // For environment data
  bool _isLoadingEnvironment = false;
  String? _environmentError;

  // Timer for auto-refreshing environment data
  Timer? _environmentRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Forcer le chargement des notifications au démarrage
    _refreshNotifications();

    // Load environment data
    _loadEnvironmentData();

    // Set up a timer to refresh environment data every 30 seconds
    _environmentRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadEnvironmentData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _environmentRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    // Prevent multiple concurrent refresh requests
    if (_isRefreshing) {
      print('🚫 Une opération de rafraîchissement est déjà en cours');
      return;
    }

    print('🔄 Rafraîchissement des notifications depuis la page');

    if (!mounted) return; // Vérifier si le widget est toujours monté

    final provider = Provider.of<NotificationProvider>(context, listen: false);
    print('🔌 URL API: ${provider.getApiUrl()}');
    print('👤 ID Utilisateur: ${provider.userId}');

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _error = null;
    });

    try {
      // Forcer le rechargement via le provider avec un timeout plus long
      await provider.forceRefresh().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Le rafraîchissement a pris trop de temps. Vérifiez votre connexion.');
        },
      );

      if (!mounted) return;

      print('✅ Notifications rafraîchies avec succès');
      print('📊 Nombre total: ${provider.notifications.length}');

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = e.toString();
      });

      // Retarder la prochaine tentative de rafraîchissement
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    }
  }

  // Load environment data from hardware provider
  Future<void> _loadEnvironmentData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingEnvironment = true;
      _environmentError = null;
    });

    try {
      print('🔄 Loading environment data...');
      final hardwareProvider =
          Provider.of<HardwareProvider>(context, listen: false);
      await hardwareProvider.loadEnvironmentData();

      if (!mounted) return;

      print('✅ Environment data loaded successfully');
      print(
          '📊 Number of machines with environment data: ${hardwareProvider.environmentData.length}');

      // Log the data for debugging
      if (hardwareProvider.environmentData.isNotEmpty) {
        for (var machine in hardwareProvider.environmentData) {
          print('🏭 Machine: ${machine['name'] ?? 'Unknown'}, '
              'Temperature: ${machine['temperature']}°C, '
              'Humidity: ${machine['humidity']}%');
        }
      }

      setState(() {
        _isLoadingEnvironment = false;
      });
    } catch (e) {
      print('❌ Error loading environment data: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingEnvironment = false;
        _environmentError = e.toString();
      });
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
                    offset: const Offset(0, 2),
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

            // Environment data card - always visible at the top
            _buildEnvironmentDataCard(),

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
            const SizedBox(height: 16),
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

    return AnimationLimiter(
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildNotificationCard(notification),
              ),
            ),
          );
        },
      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: priorityColor.withOpacity(0.2),
                    child: Icon(iconData, color: priorityColor),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
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
              const SizedBox(height: 12),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 20),
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Reçu le ${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year} à ${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                detailsWidget,
                const SizedBox(height: 30),
                if (notification.isUnread)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
                      child: const Text('Marquer comme lu'),
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
              style: const TextStyle(
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
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Rafraîchir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  // Widget to display environment data
  Widget _buildEnvironmentDataCard() {
    return Consumer<HardwareProvider>(
      builder: (context, hardwareProvider, child) {
        if (_isLoadingEnvironment) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            height: 100,
            child: Card(
              elevation: 3,
              child: Center(
                child: CircularProgressIndicator(color: widget.primaryColor),
              ),
            ),
          );
        }

        if (_environmentError != null) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Erreur de chargement des données environnementales',
                      style: TextStyle(
                          color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_environmentError!,
                        style: const TextStyle(color: Colors.red)),
                    TextButton(
                      onPressed: _loadEnvironmentData,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Display environment data from all machines
        final environmentData = hardwareProvider.environmentData;

        if (environmentData.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.thermostat, color: Colors.grey[400], size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune donnée environnementale disponible',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: _loadEnvironmentData,
                      child: Text('Rafraîchir',
                          style: TextStyle(color: widget.buttonColor)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: widget.primaryColor.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.thermostat, color: widget.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Données Environnementales',
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _loadEnvironmentData,
                        tooltip: 'Rafraîchir les données',
                        color: widget.buttonColor,
                      ),
                    ],
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: environmentData.length > 3
                        ? 3
                        : environmentData.length, // Limit to 3 machines
                    itemBuilder: (context, index) {
                      final machine = environmentData[index];
                      final temperature = machine['temperature'] ?? 0;
                      final humidity = machine['humidity'] ?? 0;
                      final name = machine['name'] ?? 'Machine ${index + 1}';
                      final location =
                          machine['location'] ?? 'Emplacement non spécifié';
                      final lastUpdate = machine['lastCommunication'] != null
                          ? DateTime.parse(machine['lastCommunication'])
                          : DateTime.now();

                      // Use the alert info from the backend if available, otherwise calculate locally
                      final bool tempAlert = machine['alerts'] != null
                          ? machine['alerts']['temperature'] ?? false
                          : (temperature > 30 || temperature < 10);
                      final bool humidityAlert = machine['alerts'] != null
                          ? machine['alerts']['humidity'] ?? false
                          : (humidity > 70 || humidity < 20);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Connection status indicator
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        _getConnectionStatusColor(lastUpdate),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                            Text(
                              location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildEnvironmentValue(
                                  'Température',
                                  '$temperature°C',
                                  icon: Icons.thermostat,
                                  isAlert: tempAlert,
                                ),
                                _buildEnvironmentValue(
                                  'Humidité',
                                  '$humidity%',
                                  icon: Icons.water_drop,
                                  isAlert: humidityAlert,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mise à jour: ${_formatDate(lastUpdate)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (tempAlert || humidityAlert)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red),
                                    ),
                                    child: Text(
                                      'Alerte',
                                      style: TextStyle(
                                        color: Colors.red[900],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (index < environmentData.length - 1 && index < 2)
                              const Divider(),
                          ],
                        ),
                      );
                    },
                  ),
                  if (environmentData.length > 3)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          // Show all machines in a dialog
                          _showAllEnvironmentData(environmentData);
                        },
                        child: Text(
                          'Voir toutes les machines (${environmentData.length})',
                          style: TextStyle(color: widget.buttonColor),
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _loadEnvironmentData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Rafraîchir les données'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for environment values
  Widget _buildEnvironmentValue(String label, String value,
      {required IconData icon, bool isAlert = false}) {
    final Color valueColor = isAlert ? Colors.red : Colors.black87;

    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isAlert ? Colors.red : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to determine connection status color based on last update time
  Color _getConnectionStatusColor(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 5) {
      return Colors.green; // Online - recently updated
    } else if (difference.inHours < 1) {
      return Colors.orange; // Stale - updated within the last hour
    } else {
      return Colors.red; // Offline - no update for over an hour
    }
  }

  // Show all environment data in a dialog
  void _showAllEnvironmentData(List<dynamic> environmentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.thermostat, color: widget.primaryColor),
            const SizedBox(width: 8),
            const Text('Toutes les machines'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: environmentData.length,
            itemBuilder: (context, index) {
              final machine = environmentData[index];
              final temperature = machine['temperature'] ?? 0;
              final humidity = machine['humidity'] ?? 0;
              final name = machine['name'] ?? 'Machine ${index + 1}';
              final location =
                  machine['location'] ?? 'Emplacement non spécifié';
              final status = machine['status'] ?? 'UNKNOWN';
              final lastUpdate = machine['lastCommunication'] != null
                  ? DateTime.parse(machine['lastCommunication'])
                  : DateTime.now();

              // Use the alert info from the backend if available, otherwise calculate locally
              final bool tempAlert = machine['alerts'] != null
                  ? machine['alerts']['temperature'] ?? false
                  : (temperature > 30 || temperature < 10);
              final bool humidityAlert = machine['alerts'] != null
                  ? machine['alerts']['humidity'] ?? false
                  : (humidity > 70 || humidity < 20);

              // Determine color based on status
              Color statusColor;
              switch (status) {
                case 'OPERATIONAL':
                  statusColor = Colors.green;
                  break;
                case 'MAINTENANCE':
                  statusColor = Colors.orange;
                  break;
                case 'ERROR':
                  statusColor = Colors.red;
                  break;
                case 'OFFLINE':
                  statusColor = Colors.grey;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              // Determine connection status text
              final connectionStatus = _getConnectionStatusText(lastUpdate);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: (tempAlert || humidityAlert)
                        ? Colors.red.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.2),
                    width: (tempAlert || humidityAlert) ? 1.5 : 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        location,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Connection: $connectionStatus',
                            style: TextStyle(
                              fontSize: 11,
                              color: _getConnectionStatusColor(lastUpdate),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Mise à jour: ${_formatDate(lastUpdate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEnvironmentValue(
                            'Température',
                            '$temperature°C',
                            icon: Icons.thermostat,
                            isAlert: tempAlert,
                          ),
                          _buildEnvironmentValue(
                            'Humidité',
                            '$humidity%',
                            icon: Icons.water_drop,
                            isAlert: humidityAlert,
                          ),
                        ],
                      ),
                      if (tempAlert || humidityAlert)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber,
                                      color: Colors.red[700], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Alerte:',
                                    style: TextStyle(
                                      color: Colors.red[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (tempAlert)
                                Text(
                                  'Température ${temperature > 30 ? 'trop élevée' : 'trop basse'} (${temperature}°C)',
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontSize: 11,
                                  ),
                                ),
                              if (humidityAlert)
                                Text(
                                  'Humidité ${humidity > 70 ? 'trop élevée' : 'trop basse'} (${humidity}%)',
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadEnvironmentData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.buttonColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }

  // Helper method to get connection status text based on last update time
  String _getConnectionStatusText(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 5) {
      return 'En ligne';
    } else if (difference.inHours < 1) {
      return 'Mis à jour il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Mis à jour il y a ${difference.inHours} h';
    } else {
      return 'Hors ligne (${difference.inDays} jours)';
    }
  }
}
