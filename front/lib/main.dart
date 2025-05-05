import 'package:flutter/material.dart';
import 'package:lessvsfull/client_page/products_page.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'Login/login_page.dart';
import 'admin_page/admin_page.dart';
import 'client_page/notification_page.dart';
import 'client_page/products_page.dart' as products_page
    show GenerateCodePage, ProductsPage, ProduitPanier;
import 'client_page/profile_page.dart';
import 'services/notification_service.dart';
import 'services/produit_service.dart';
import 'providers/notification_provider.dart';
import 'models/produit.dart';

// Définir l'URL du backend - modifier cette URL selon votre environnement
// Pour le développement sur émulateur Android, utilisez 10.0.2.2:5000 au lieu de localhost:5000
// Pour le développement sur appareil physique, utilisez l'IP de votre machine sur le réseau local
// const String apiBaseUrl = 'http://localhost:5000'; // Fonctionne uniquement sur le web
const String apiBaseUrl = 'http://10.0.2.2:5000'; // Pour les émulateurs Android
// const String apiBaseUrl = 'http://[IP_DE_VOTRE_MACHINE]:5000'; // Pour les appareils physiques

// ID de technicien par défaut (sera remplacé par l'ID réel après la connexion)
const String defaultTechnicianId =
    '681154075cf30e38df588370'; // ID utilisé dans test-notifications.js

void main() {
  // Initialiser le service de notification avec l'URL de base de l'API
  final notificationService = NotificationService(baseUrl: apiBaseUrl);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            service: notificationService,
            userId: defaultTechnicianId, // Utiliser un ID par défaut
          ),
        ),
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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isInMaintenance = false;
  double soldeUtilisateur = 2500; // Solde de l'utilisateur
  String userEmail = "User@example.com";
  String userName = "Username";

  List<Produit> produits = [
    Produit(
      id: '1',
      nom: 'Bouteille de jus ',
      prix: 60,
      image: 'assets/cafe.png',
      disponible: true,
    ),
    Produit(
      id: '2',
      nom: 'Chips',
      prix: 40,
      image: 'assets/latte.png',
      disponible: true,
    ),
    Produit(
      id: '3',
      nom: 'Barre chocolatée',
      prix: 70,
      image: 'assets/chocolat.png',
      disponible: true,
    ),
    Produit(
      id: '4',
      nom: 'Madelaine',
      prix: 75,
      image: 'assets/the.png',
      disponible: false,
    ),
    Produit(
      id: '5',
      nom: 'Eau Minérale',
      prix: 30,
      image: 'assets/eau.png',
      disponible: true,
    ),
    Produit(
      id: '6',
      nom: 'Soda Cola',
      prix: 100,
      image: 'assets/soda.png',
      disponible: true,
    ),
  ];

  // Utiliser ProduitPanier depuis le module products_page
  List<products_page.ProduitPanier> panier =
      []; // Ensure ProduitPanier is correctly imported

  // Méthode pour récupérer le nombre de notifications non lues
  int get unreadNotificationsCount {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    return notificationProvider.unreadCount;
  }

  get localProductsPage => null;

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
        return ProductsPage(
          panier: panier,
          soldeUtilisateur: soldeUtilisateur,
          onAjouterAuPanier: _ajouterAuPanier,
          onShowPanier: _showPanier,
          isInMaintenance: isInMaintenance,
          baseUrl: apiBaseUrl,
        );
      case 1:
        return NotificationPage();
      case 2:
        return ProfilePage(
          userName: userName,
          userEmail: userEmail,
          soldeUtilisateur: soldeUtilisateur,
          isInMaintenance: isInMaintenance,
        );
      default:
        return Container();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        panier.add(products_page.ProduitPanier(produit: produit, quantite: 1));
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
}
