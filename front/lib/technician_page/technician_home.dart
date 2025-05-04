import 'package:flutter/material.dart';
import '../Login/login_page.dart';
import 'stock_management_page.dart';
import 'machine_status_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({Key? key}) : super(key: key);

  @override
  _TechnicianHomePageState createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage> {
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;

  // Updated theme colors with better contrast for buttons
  final Color primaryColor = const Color(0xFF6B2FEB); // App's primary purple
  final Color buttonColor =
      const Color(0xFF5026B9); // Deeper purple for buttons
  final Color buttonTextColor =
      Colors.white; // White text for better visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau Technicien'),
        backgroundColor: primaryColor,
        actions: [
          // Updated logout button in AppBar
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white, size: 18),
              label: const Text(
                'Déconnecter',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _showLogoutConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: _getPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Distributeur',
          ),
          BottomNavigationBarItem(
            icon: _unreadNotificationCount > 0
                ? Badge(
                    label: Text('$_unreadNotificationCount'),
                    child: const Icon(Icons.notifications),
                  )
                : const Icon(Icons.notifications),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return StockManagementPage(
          primaryColor: primaryColor,
          buttonColor: buttonColor,
          buttonTextColor: buttonTextColor,
        );
      case 1:
        return MachineStatusPage(
          primaryColor: primaryColor,
          buttonColor: buttonColor,
          buttonTextColor: buttonTextColor,
        );
      case 2:
        return NotificationsPage(
          primaryColor: primaryColor,
          buttonColor: buttonColor,
          onNotificationStatusChanged: (count) {
            setState(() {
              _unreadNotificationCount = count;
            });
          },
        );
      case 3:
        return ProfilePage(
          primaryColor: primaryColor,
          buttonColor: buttonColor,
          buttonTextColor: buttonTextColor,
        );
      default:
        return StockManagementPage(
          primaryColor: primaryColor,
          buttonColor: buttonColor,
          buttonTextColor: buttonTextColor,
        );
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[700]),
              const SizedBox(width: 10),
              const Text('Déconnexion'),
            ],
          ),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[800],
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the dialog first
                Navigator.pop(context);

                // Navigate to login page and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );

                // The logout confirmation will be shown in the login page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Déconnexion réussie'),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin:
                        const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Déconnexion',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
