import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'implementation/notification-imp.dart';
import 'Login/login_page.dart';
import 'admin_page/admin_page.dart'; // Updated import
import 'client_page/notification_page.dart';

void main() {
  // Create service and repository
  final notificationService = NotificationService(baseUrl: 'https://your-api-url.com/api');
  final notificationRepository = NotificationRepository(notificationService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            repository: notificationRepository,
            userId: 'current_user_id', // Get the current user ID
          ),
        ),
        // Add other providers if needed
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Distributeur Automatique',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Color(0xFF6B2FEB),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF6B2FEB),
          secondary: Color(0xFF9C27B0),
          surface: Color(0xFFF8F9FA),
          background: Color(0xFFF8F9FA),
          onPrimary: Colors.white,
        ),
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF6B2FEB),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Color(0xFF6B2FEB),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6B2FEB),
          secondary: Color(0xFF9C27B0),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          onPrimary: Colors.white,
        ),
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1E1E1E),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: LoginPage(),
      routes: {
        '/admin_home': (context) => const AdminHomePage(),
      },
    );
  }
}

// MODEL CLASSES
// ============================================================

class Produit {
  final int id;
  final String nom;
  final double prix;
  final String image;
  final bool disponible;

  Produit({
    required this.id,
    required this.nom,
    required this.prix,
    required this.image,
    required this.disponible,
  });
}

class ProduitPanier {
  final Produit produit;
  int quantite;

  ProduitPanier({
    required this.produit,
    required this.quantite,
  });
}

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

// SCREENS
// ============================================================

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isInMaintenance = false;
  double soldeUtilisateur = 2500; // Solde de l'utilisateur
  // Consider adding user info for the profile page
  String userEmail = "User@example.com";
  String userName = "Username";
  List<Produit> produits = [
    Produit(
      id: 1,
      nom: 'Bouteille de jus ',
      prix: 60,
      image: 'assets/cafe.png',
      disponible: true,
    ),
    Produit(
      id: 2,
      nom: 'Chips',
      prix: 40,
      image: 'assets/latte.png',
      disponible: true,
    ),
    Produit(
      id: 3,
      nom: 'Barre chocolatée',
      prix: 70,
      image: 'assets/chocolat.png',
      disponible: true,
    ),
    Produit(
      id: 4,
      nom: 'Madelaine',
      prix: 75,
      image: 'assets/the.png',
      disponible: false,
    ),
    Produit(
      id: 5,
      nom: 'Eau Minérale',
      prix: 30,
      image: 'assets/eau.png',
      disponible: true,
    ),
    Produit(
      id: 6,
      nom: 'Soda Cola',
      prix: 100,
      image: 'assets/soda.png',
      disponible: true,
    ),
  ];
  List<ProduitPanier> panier = [];

  List<NotificationItem> notifications = [
    NotificationItem(
      message: 'Votre solde a été rechargé',
      date: DateTime(2025, 3, 15, 14, 30),
      type: NotificationType.transaction,
      montant: 20.00,
    ),
    NotificationItem(
      message: 'Achat effectué',
      date: DateTime(2025, 3, 19, 10, 15),
      type: NotificationType.transaction,
      montant: -4.25,
    ),
    NotificationItem(
      message: 'Code généré pour votre commande',
      date: DateTime(2025, 3, 19, 10, 18),
      type: NotificationType.code,
    ),
    NotificationItem(
      message: 'Votre solde a été rechargé',
      date: DateTime(2025, 3, 10, 9, 45),
      type: NotificationType.transaction,
      montant: 10.00,
    ),
    NotificationItem(
      message: 'Code expiré',
      date: DateTime(2025, 3, 19, 10, 23),
      type: NotificationType.code,
    ),
  ];

  // Méthode pour récupérer le nombre de notifications non lues
  int get unreadNotificationsCount {
    return notifications.where((notif) => !notif.isRead).length;
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
      case 1:
        return '${soldeUtilisateur.toStringAsFixed(2)} DA'; // Affiche le solde pour les pages produits et notifications
      case 2:
        return 'Mon Profil'; // Titre pour la page profil
      default:
        return 'Distributeur Automatique';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: IconButton(
          icon: Icon(
            isInMaintenance
                ? Icons.warning_amber_rounded // Icon for maintenance
                : Icons.check_circle, // Icon for available
            color: isInMaintenance
                ? Colors.amber // Yellow for maintenance
                : Colors.green, // Green for available
          ),
          onPressed: () => _showStatusDialog(),
        ),
        actions: [
          // Seulement l'icône du panier
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () => _showPanier(),
              ),
              if (panier.isNotEmpty)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${panier.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.notifications),
                if (unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadNotificationsCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: produits.length,
            itemBuilder: (context, index) {
              return _buildProduitCard(produits[index]);
            });
      case 1:
        return NotificationPage();
      case 2:
        return _buildProfileView();
      default:
        return Container();
    }
  }

  Widget _buildNotificationsView() {
    if (notifications.isEmpty) {
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
                // Vue des commandes (transactions, reçus, recharges)
                ListView.separated(
                  itemCount: notifications
                      .where((n) => n.type == NotificationType.transaction)
                      .length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final transactionNotifs = notifications
                        .where((n) => n.type == NotificationType.transaction)
                        .toList();
                    final notification = transactionNotifs[index];
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
                        setState(() {
                          notifications[notifications.indexOf(notification)] =
                              notification.copyWith(isRead: true);
                        });
                      },
                    );
                  },
                ),

                // Vue des codes (statut des codes générés)
                ListView.separated(
                  itemCount: notifications
                      .where((n) => n.type == NotificationType.code)
                      .length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final codeNotifs = notifications
                        .where((n) => n.type == NotificationType.code)
                        .toList();
                    final notification = codeNotifs[index];
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
                        setState(() {
                          notifications[notifications.indexOf(notification)] =
                              notification.copyWith(isRead: true);
                        });
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

  // Add the profile view builder
  Widget _buildProfileView() {
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
                  userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
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
                      '${soldeUtilisateur.toStringAsFixed(2)} DA',
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
                    subtitle: Text(userEmail),
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
                  // Support button (replacing recharge button)
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildProduitCard(Produit produit) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: produit.disponible
            ? () {
                _showProduitDetails(produit);
              }
            : null,
        child: Container(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_cafe,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (!produit.disponible)
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'INDISPONIBLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                produit.nom,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${produit.prix.toStringAsFixed(2)} DA',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                ),
              ),
              Spacer(),
              if (produit.disponible)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('Ajouter'),
                    onPressed: () {
                      _ajouterAuPanier(produit);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProduitDetails(Produit produit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_cafe,
                      size: 80,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                produit.nom,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Prix: ${produit.prix.toStringAsFixed(2)} DA',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Un délicieux ${produit.nom.toLowerCase()} préparé avec des ingrédients de qualité.',
                style: TextStyle(fontSize: 16),
              ),
              Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Ajouter au panier',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _ajouterAuPanier(produit);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _ajouterAuPanier(Produit produit) {
    setState(() {
      bool exists = false;
      for (var item in panier) {
        if (item.produit.id == produit.id) {
          item.quantite++;
          exists = true;
          break;
        }
      }
      if (!exists) {
        panier.add(ProduitPanier(produit: produit, quantite: 1));
      }
    });

    // Hide any existing SnackBar first to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produit.nom} ajouté au panier'),
        duration: Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white, // Ensuring text is visible
          onPressed: () {
            _showPanier();
          },
        ),
        behavior:
            SnackBarBehavior.floating, // Makes SnackBar float and more visible
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _showPanier() {
    if (panier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Votre panier est vide'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double total = 0;
            for (var item in panier) {
              total += item.produit.prix * item.quantite;
            }

            return Container(
              padding: EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre Panier',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: panier.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              panier[index].produit.nom,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${panier[index].produit.prix.toStringAsFixed(2)} DA x ${panier[index].quantite}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      if (panier[index].quantite > 1) {
                                        panier[index].quantite--;
                                      } else {
                                        panier.removeAt(index);
                                      }
                                      // Update parent state too
                                      this.setState(() {});
                                    });
                                  },
                                ),
                                Text(
                                  '${panier[index].quantite}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      panier[index].quantite++;
                                      // Update parent state too
                                      this.setState(() {});
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(thickness: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)} DA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text('Vider le panier'),
                          onPressed: () {
                            setState(() {
                              panier.clear();
                              // Update parent state too
                              this.setState(() {});
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text('Commander'),
                          onPressed: () {
                            Navigator.pop(context);
                            _finaliserCommande();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _finaliserCommande() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisir une option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.wallet, color: Colors.green),
                title: Text('Payer maintenant'),
                subtitle: Text(
                    'Payer avec votre e-wallet (${soldeUtilisateur.toStringAsFixed(2)} DA)'),
                onTap: () {
                  Navigator.pop(context);
                  if (soldeUtilisateur < _calculateTotal()) {
                    _showSoldeInsuffisant();
                  } else {
                    _confirmerPaiementEwallet();
                  }
                },
              ),
              Divider(),
              ListTile(
                leading:
                    Icon(Icons.qr_code, color: Theme.of(context).primaryColor),
                title: Text('Générer un code'),
                subtitle: Text('Pour payer directement au distributeur'),
                onTap: () {
                  Navigator.pop(context);
                  _genererCode();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmerPaiementEwallet() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer le paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Payer avec votre e-wallet'),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    '${soldeUtilisateur.toStringAsFixed(2)} DA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                'Montant à débiter: ${_calculateTotal().toStringAsFixed(2)} DA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Confirmer'),
              onPressed: () {
                Navigator.pop(context);
                _processPaiement();
              },
            ),
          ],
        );
      },
    );
  }

  void _genererCode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GenerateCodePage()),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in panier) {
      total += item.produit.prix * item.quantite;
    }
    return total;
  }

  void _showSoldeInsuffisant() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Solde insuffisant'),
          content:
              Text('Votre solde est insuffisant pour effectuer cet achat.'),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _processPaiement() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Traitement du paiement...'),
            ],
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        soldeUtilisateur -= _calculateTotal();
        panier.clear();
      });

      Navigator.of(context).pop();
      _showPaiementReussi();
    });
  }

  void _showPaiementReussi() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Paiement accepté'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 20),
              Text('Votre commande a été validée !'),
              SizedBox(height: 10),
              Text(
                'Nouveau solde: ${soldeUtilisateur.toStringAsFixed(2)} DA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
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
                    isInMaintenance ? Icons.warning : Icons.check_circle,
                    color: isInMaintenance ? Colors.amber : Colors.green,
                  ),
                  SizedBox(width: 10),
                  Text(
                    isInMaintenance ? 'En maintenance' : 'Disponible',
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

  void _showRechargeDialog() {
    double montantRecharge = 10.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Recharger mon compte'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Montant à recharger:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: Text('5 DA'),
                        onPressed: () {
                          setState(() {
                            montantRecharge = 5.0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: montantRecharge == 5.0
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          foregroundColor: montantRecharge == 5.0
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        child: Text('10 DA'),
                        onPressed: () {
                          setState(() {
                            montantRecharge = 10.0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: montantRecharge == 10.0
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          foregroundColor: montantRecharge == 10.0
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        child: Text('20 DA'),
                        onPressed: () {
                          setState(() {
                            montantRecharge = 20.0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: montantRecharge == 20.0
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          foregroundColor: montantRecharge == 20.0
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Total à payer: ${montantRecharge.toStringAsFixed(2)} DA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Annuler'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Payer'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _processRecharge(montantRecharge);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processRecharge(double montant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Traitement du paiement...'),
            ],
          ),
        );
      },
    );

    // Simuler un délai de paiement
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();

      setState(() {
        soldeUtilisateur += montant;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Rechargement réussi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                SizedBox(height: 20),
                Text(
                    'Votre compte a été rechargé de ${montant.toStringAsFixed(2)} DA'),
                SizedBox(height: 10),
                Text(
                  'Nouveau solde: ${soldeUtilisateur.toStringAsFixed(2)} DA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
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
}

class GenerateCodePage extends StatefulWidget {
  @override
  _GenerateCodePageState createState() => _GenerateCodePageState();
}

class _GenerateCodePageState extends State<GenerateCodePage> {
  String generatedCode = '';

  @override
  void initState() {
    super.initState();
    _generateCode(); // Générer le code automatiquement
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Votre Code de Retrait'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Code Généré',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 30),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              generatedCode,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 20),
                            Icon(
                              Icons.qr_code_2,
                              size: 120,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Code valable pendant 5 minutes',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Présentez ce code sur l\'écran du distributeur',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateCode() {
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += (DateTime.now().millisecondsSinceEpoch % 10).toString();
    }
    setState(() {
      generatedCode = code;
    });
  }
}
