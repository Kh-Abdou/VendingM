import 'package:flutter/material.dart';
import '../Login/login_page.dart';

class ProfilePage extends StatefulWidget {
  final Color primaryColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const ProfilePage({
    super.key,
    required this.primaryColor,
    required this.buttonColor,
    required this.buttonTextColor,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Profile data
  String _technicianName = 'Technicien';
  String _technicianEmail = 'Technician@gmail.com';
  String _technicianPhone = '+213 555 123 456';
  String _technicianZone = 'Université - Campus';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: widget.primaryColor.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 60,
              color: widget.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _technicianName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(_technicianEmail),
          const SizedBox(height: 30),
          Card(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.call),
                  title: const Text('Téléphone'),
                  subtitle: Text(_technicianPhone),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Zone de service'),
                  subtitle: Text(_technicianZone),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Modifier le profil',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            onPressed: () {
              _showEditProfileDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.buttonColor,
              foregroundColor: widget.buttonTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Déconnexion',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            onPressed: () {
              _showLogoutConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _technicianName);
    final emailController = TextEditingController(text: _technicianEmail);
    final phoneController = TextEditingController(text: _technicianPhone);
    final zoneController = TextEditingController(text: _technicianZone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: widget.primaryColor),
              const SizedBox(width: 10),
              const Text('Modifier le profil'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: zoneController,
                  decoration: const InputDecoration(
                    labelText: 'Zone de service',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
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
                // Validation - Basic email format check
                if (!emailController.text.contains('@') ||
                    !emailController.text.contains('.')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer une adresse email valide'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Update profile information
                setState(() {
                  _technicianName = nameController.text;
                  _technicianEmail = emailController.text;
                  _technicianPhone = phoneController.text;
                  _technicianZone = zoneController.text;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Profil mis à jour avec succès'),
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
                backgroundColor: widget.buttonColor,
                foregroundColor: widget.buttonTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sauvegarder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
