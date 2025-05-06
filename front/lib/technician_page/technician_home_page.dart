import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'notifications_page.dart';

class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({super.key});

  @override
  _TechnicianHomePageState createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage> {
  int _currentIndex = 0;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    // Chargement initial des notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).forceRefresh();
    });
    print('🔧 Page d\'accueil technicien initialisée');
  }

  // Méthode pour mettre à jour le compteur de notifications
  void _updateNotificationCount(int count) {
    setState(() {
      _unreadNotificationsCount = count;
    });
    print('🔔 Notifications non lues: $_unreadNotificationsCount');
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final buttonColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Technicien'),
        actions: [
          // Affichage des infos de connexion au backend (pour débogage)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showDebugInfo(context);
            },
          ),
        ],
      ),
      body: _getPage(primaryColor, buttonColor),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stocks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.handyman),
            label: 'Maintenance',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _getPage(Color primaryColor, Color buttonColor) {
    switch (_currentIndex) {
      case 0:
        return NotificationsPage(
          primaryColor: primaryColor,
          buttonColor: buttonColor,
          onNotificationStatusChanged: _updateNotificationCount,
        );
      case 1:
        return _buildPlaceholderPage(
          'Gestion des Stocks',
          Icons.inventory,
          'La gestion des stocks sera bientôt disponible',
        );
      case 2:
        return _buildPlaceholderPage(
          'Maintenance',
          Icons.build,
          'La gestion de la maintenance sera bientôt disponible',
        );
      case 3:
        return _buildProfilePage();
      default:
        return NotificationsPage(
          primaryColor: primaryColor,
          buttonColor: buttonColor,
          onNotificationStatusChanged: _updateNotificationCount,
        );
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Technicien',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${provider.userId.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading:
                      Icon(Icons.badge, color: Theme.of(context).primaryColor),
                  title: const Text('Rôle'),
                  subtitle: const Text('Technicien de maintenance'),
                ),
                const Divider(),
                ListTile(
                  leading:
                      Icon(Icons.email, color: Theme.of(context).primaryColor),
                  title: const Text('Email'),
                  subtitle: const Text('technicien@example.com'),
                ),
                const Divider(),
                ListTile(
                  leading:
                      Icon(Icons.phone, color: Theme.of(context).primaryColor),
                  title: const Text('Téléphone'),
                  subtitle: const Text('+213 123 456 789'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.blue),
                  title: const Text('Rafraîchir les notifications'),
                  onTap: () {
                    Provider.of<NotificationProvider>(context, listen: false)
                        .forceRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications rafraîchies')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Déconnexion'),
                  onTap: () {
                    _showLogoutConfirmation();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de débogage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API URL: ${provider.getApiUrl()}'),
            const SizedBox(height: 8),
            Text('ID Technicien: ${provider.userId}'),
            const SizedBox(height: 8),
            Text('Notifications non lues: $_unreadNotificationsCount'),
            const SizedBox(height: 8),
            Text('Total notifications: ${provider.notifications.length}'),
            const SizedBox(height: 16),
            const Text('⚠️ Ces informations sont destinées au débogage uniquement.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.forceRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications rafraîchies')),
              );
            },
            child: const Text('Rafraîchir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
