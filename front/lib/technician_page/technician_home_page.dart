import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'notifications_page.dart';

class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({Key? key}) : super(key: key);

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
            icon: Icon(Icons.info_outline),
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
                Icon(Icons.notifications),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationsCount.toString(),
                        style: TextStyle(
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
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stocks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman),
            label: 'Maintenance',
          ),
          BottomNavigationBarItem(
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
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
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
      padding: EdgeInsets.all(20),
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
                SizedBox(height: 16),
                Text(
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
          SizedBox(height: 30),
          Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading:
                      Icon(Icons.badge, color: Theme.of(context).primaryColor),
                  title: Text('Rôle'),
                  subtitle: Text('Technicien de maintenance'),
                ),
                Divider(),
                ListTile(
                  leading:
                      Icon(Icons.email, color: Theme.of(context).primaryColor),
                  title: Text('Email'),
                  subtitle: Text('technicien@example.com'),
                ),
                Divider(),
                ListTile(
                  leading:
                      Icon(Icons.phone, color: Theme.of(context).primaryColor),
                  title: Text('Téléphone'),
                  subtitle: Text('+213 123 456 789'),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                ListTile(
                  leading: Icon(Icons.refresh, color: Colors.blue),
                  title: Text('Rafraîchir les notifications'),
                  onTap: () {
                    Provider.of<NotificationProvider>(context, listen: false)
                        .forceRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notifications rafraîchies')),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Déconnexion'),
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
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            child: Text('Déconnexion'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        title: Text('Informations de débogage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API URL: ${provider.getApiUrl()}'),
            SizedBox(height: 8),
            Text('ID Technicien: ${provider.userId}'),
            SizedBox(height: 8),
            Text('Notifications non lues: $_unreadNotificationsCount'),
            SizedBox(height: 8),
            Text('Total notifications: ${provider.notifications.length}'),
            SizedBox(height: 16),
            Text('⚠️ Ces informations sont destinées au débogage uniquement.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.forceRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifications rafraîchies')),
              );
            },
            child: Text('Rafraîchir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
