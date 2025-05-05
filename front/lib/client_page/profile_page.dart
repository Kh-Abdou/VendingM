import 'package:flutter/material.dart';
import '../Login/login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final double soldeUtilisateur;
  final bool isInMaintenance;

  const ProfilePage({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.soldeUtilisateur,
    required this.isInMaintenance,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with avatar
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
                  widget.userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Account details section
          Text(
            'Informations du compte',
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Solde row
                  ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text('Solde'),
                    trailing: Text(
                      '${widget.soldeUtilisateur.toStringAsFixed(2)} DA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Divider(),

                  // Email row
                  ListTile(
                    leading: Icon(
                      Icons.email,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text('Email'),
                    subtitle: Text(widget.userEmail),
                  ),
                  Divider(),

                  // Password row (masked)
                  ListTile(
                    leading: Icon(
                      Icons.lock,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text('Mot de passe'),
                    subtitle: Text('••••••••'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        // Implement password change functionality
                        _showChangePasswordDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          // Actions section
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Support button
                  ListTile(
                    leading: Icon(
                      Icons.support_agent,
                      color: Colors.blue,
                    ),
                    title: Text('Support'),
                    subtitle: Text('Besoin d\'aide ? Contactez-nous'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      _showSupportDialog();
                    },
                  ),
                  Divider(),

                  // Status of the distributor
                  ListTile(
                    leading: Icon(
                      widget.isInMaintenance
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color:
                          widget.isInMaintenance ? Colors.amber : Colors.green,
                    ),
                    title: Text('Statut du distributeur'),
                    subtitle: Text(
                      widget.isInMaintenance ? 'En maintenance' : 'Disponible',
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      _showStatusDialog();
                    },
                  ),
                  Divider(),

                  // Logout button
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: Text('Se déconnecter'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      _confirmLogout();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    // Password fields controllers
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changer le mot de passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Enregistrer'),
              onPressed: () {
                // Implement password change logic here

                // Show confirmation
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mot de passe modifié avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Se déconnecter'),
          content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Déconnecter'),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login page
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              SizedBox(width: 10),
              Text('Assistance'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pour toute question ou problème avec le distributeur, veuillez contacter:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Phone number section
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.green),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Téléphone',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('+213 123 456 789'),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 15),

              // Email section
              Row(
                children: [
                  Icon(Icons.email, color: Colors.blue),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('support@distributeur.com'),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),
              Text(
                'Horaires du support: 8h-18h, 7j/7',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Statut du Distributeur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isInMaintenance ? Icons.warning : Icons.check_circle,
                    color: widget.isInMaintenance ? Colors.amber : Colors.green,
                  ),
                  SizedBox(width: 10),
                  Text(
                    widget.isInMaintenance ? 'En maintenance' : 'Disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text('ID Distributeur: DIS-42501'),
              Text('Dernière mise à jour: 16/03/2025'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
