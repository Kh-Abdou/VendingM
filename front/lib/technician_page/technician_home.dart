import 'package:flutter/material.dart';
import 'stock_management_page.dart';
import 'machine_status_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({super.key});

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
}
