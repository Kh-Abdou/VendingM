import 'package:flutter/material.dart';
import 'package:lessvsfull/client_page/products_page.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'Login/login_page.dart';
import 'admin_page/admin_page.dart';
import 'client_page/notification_page.dart';
import 'client_page/notification_page.dart'; // Ensure NotificationsPage is imported
import 'client_page/products_page.dart' as products_page
    show GenerateCodePage, ProductsPage, ProduitPanier;
import 'client_page/profile_page.dart';
import 'services/notification_service.dart';
import 'services/produit_service.dart';
import 'services/order_service.dart';
import 'services/user_service.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart'; // Import du nouveau provider
import 'models/produit.dart';
import 'dart:developer' as developer;

import 'technician_page/notifications_page.dart';

// Définir l'URL du backend - modifier cette URL selon votre environnement
// Pour le développement sur émulateur Android, utilisez 10.0.2.2:5000 au lieu de localhost:5000
// Pour le développement sur appareil physique, utilisez l'IP de votre machine sur le réseau local
// const String apiBaseUrl = 'http://localhost:5000'; // Fonctionne uniquement sur le web
const String apiBaseUrl = 'http://10.0.2.2:5000'; // Pour les émulateurs Android
// const String apiBaseUrl = 'http://[IP_DE_VOTRE_MACHINE]:5000'; // Pour les appareils physiques

// ID de technicien par défaut (sera remplacé par l'ID réel après la connexion)
const String defaultTechnicianId =
    '681154075cf30e38df588370'; // ID utilisé dans test-notifications.js

// ID client par défaut (à remplacer par l'ID réel après connexion)
const String defaultClientId =
    '68120db1321b2ae6e7d61ab2'; // Exemple d'ID client

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
        ChangeNotifierProvider(
          create: (context) => UserProvider(), // Ajout du provider utilisateur
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Distributeur Automatique',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: const Color(0xFF6B2FEB),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6B2FEB),
          secondary: Color(0xFF9C27B0),
          surface: Color(0xFFF8F9FA),
          onPrimary: Colors.white,
        ),
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
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
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: const Color(0xFF6B2FEB),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6B2FEB),
          secondary: Color(0xFF9C27B0),
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
        ),
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
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
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isInMaintenance = false;
  List<products_page.ProduitPanier> panier = [];

  // Initialisation du service de commande
  late final OrderService _orderService;
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService(baseUrl: apiBaseUrl);
    _userService = UserService(baseUrl: apiBaseUrl);

    // Récupérer le solde de l'utilisateur au démarrage
    _fetchUserData();

    // Mettre à jour l'ID utilisateur dans le NotificationProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNotificationProviderUserId();
    });
  }

  // Récupérer les données utilisateur
  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.userId.isEmpty) {
      // Si l'ID utilisateur n'est pas défini, c'est un problème de connexion
      developer.log('Erreur: ID utilisateur non défini', name: 'HomePage');
      return;
    }

    try {
      // Récupérer le solde e-wallet
      final balance =
          await _orderService.getEWalletBalance(userProvider.userId);

      // Mettre à jour le provider
      userProvider.updateBalance(balance);
    } catch (e) {
      developer.log('Erreur lors de la récupération des données: $e',
          name: 'HomePage');
    }
  }

  // Méthode pour récupérer le nombre de notifications non lues
  int get unreadNotificationsCount {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    return notificationProvider.unreadCount;
  }

  String _getTitle() {
    final userProvider = Provider.of<UserProvider>(context);

    switch (_selectedIndex) {
      case 0:
      case 1:
        return '${userProvider.userBalance.toStringAsFixed(2)} DA'; // Affiche le solde pour les pages produits et notifications
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
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showPanier(),
              ),
              if (panier.isNotEmpty)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${panier.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadNotificationsCount',
                        style: const TextStyle(
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    final userProvider = Provider.of<UserProvider>(context);

    switch (_selectedIndex) {
      case 0:
        return ProductsPage(
          panier: panier,
          soldeUtilisateur: userProvider.userBalance,
          onAjouterAuPanier: _ajouterAuPanier,
          onShowPanier: _showPanier,
          isInMaintenance: isInMaintenance,
          baseUrl: apiBaseUrl,
        );
      case 1:
        // Vérifier si l'utilisateur est un technicien ou un client
        if (userProvider.userRole.toLowerCase() == 'technician') {
          // Utiliser la page des notifications pour techniciens
          return NotificationsPage(
            primaryColor: Theme.of(context).primaryColor,
            buttonColor: Theme.of(context).colorScheme.secondary,
            onNotificationStatusChanged: (count) {
              // Cette fonction est appelée lorsque le statut des notifications change
            },
          );
        } else {
          // Utiliser la page des notifications pour clients
          return NotificationPage();
        }
      case 2:
        return ProfilePage(
          userId: Provider.of<UserProvider>(context, listen: false).userId,
          baseUrl: apiBaseUrl,
          userName: userProvider.userName,
          userEmail: userProvider.userEmail,
          soldeUtilisateur: userProvider.userBalance,
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
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white, // Ensuring text is visible
          onPressed: () {
            _showPanier();
          },
        ),
        behavior:
            SnackBarBehavior.floating, // Makes SnackBar float and more visible
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showPanier() {
    if (panier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
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
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Votre Panier',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${panier.length} article${panier.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: panier.length,
                      itemBuilder: (context, index) {
                        final item = panier[index];
                        final produit = item.produit;
                        final subtotal = produit.prix * item.quantite;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        produit.nom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.red[400]),
                                      onPressed: () {
                                        setState(() {
                                          panier.removeAt(index);
                                          // Update parent state too
                                          this.setState(() {});
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Prix unitaire: ${produit.prix.toStringAsFixed(2)} DA',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Sous-total: ${subtotal.toStringAsFixed(2)} DA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 18),
                                            onPressed: () {
                                              setState(() {
                                                if (item.quantite > 1) {
                                                  item.quantite--;
                                                } else {
                                                  panier.removeAt(index);
                                                }
                                                // Update parent state too
                                                this.setState(() {});
                                              });
                                            },
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Text(
                                              '${item.quantite}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 18),
                                            onPressed: () {
                                              setState(() {
                                                item.quantite++;
                                                // Update parent state too
                                                this.setState(() {});
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(thickness: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
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
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Vider le panier'),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Commander'),
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
    // Récupérer le solde à jour avant d'afficher les options
    _fetchUserData().then((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choisir une option'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.wallet, color: Colors.green),
                  title: const Text('Payer avec E-wallet'),
                  subtitle: Text(
                      'Utiliser votre solde (${Provider.of<UserProvider>(context, listen: false).userBalance.toStringAsFixed(2)} DA)'),
                  onTap: () {
                    Navigator.pop(context);
                    final userProvider =
                        Provider.of<UserProvider>(context, listen: false);
                    if (userProvider.userBalance < _calculateTotal()) {
                      _showSoldeInsuffisant();
                    } else {
                      _confirmerPaiementEwallet();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.qr_code,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Générer un code'),
                  subtitle: const Text('Pour payer directement au distributeur'),
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
    });
  }

  void _confirmerPaiementEwallet() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer le paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Payer avec votre e-wallet'),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '${Provider.of<UserProvider>(context, listen: false).userBalance.toStringAsFixed(2)} DA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'Montant à débiter: ${_calculateTotal().toStringAsFixed(2)} DA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Confirmer'),
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
    // Ouvrir la page de génération de code avec les données du panier
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenerateCodePage(
          panier: panier,
          userId: Provider.of<UserProvider>(context, listen: false).userId,
          baseUrl: apiBaseUrl,
        ),
      ),
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
          title: const Text('Solde insuffisant'),
          content:
              const Text('Votre solde est insuffisant pour effectuer cet achat.'),
          actions: [
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _processPaiement() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final double totalAmount = _calculateTotal();

    // Créer une copie du panier pour l'utiliser après le processus de paiement
    final List<products_page.ProduitPanier> panierCopy = List.from(panier);

    final List<Map<String, dynamic>> productsData = panier
        .map((item) => {
              'productId': item.produit.id,
              'quantity': item.quantite,
              'price': item.produit.prix,
            })
        .toList();

    // Afficher l'indicateur de progression
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
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

    try {
      // Appel au service pour effectuer le paiement
      final result = await _orderService.processPayment(
        userId: userProvider.userId,
        amount: totalAmount,
        products: productsData,
      );

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Récupérer et convertir le solde, en gérant les types int et double
      double newBalance;
      if (result['balance'] != null) {
        // Convertir en double si c'est un int
        newBalance = result['balance'] is int
            ? (result['balance'] as int).toDouble()
            : result['balance'];
      } else {
        // Fallback si balance n'est pas présent
        newBalance = userProvider.userBalance - totalAmount;
      }

      // Mettre à jour le solde utilisateur
      userProvider.updateBalance(newBalance);

      // Vider le panier après traitement
      setState(() {
        panier.clear();
      });

      // Afficher confirmation de paiement réussi avec les détails des produits
      _showPaiementReussi(userProvider.userBalance, totalAmount, panierCopy);

      // Rafraîchir les notifications (pour afficher la nouvelle notification de transaction)
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.forceRefresh();
    } catch (e) {
      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Afficher l'erreur à l'utilisateur
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erreur de paiement'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    }
  }

  void _showPaiementReussi(double soldeActuel, double montantTotal,
      List<products_page.ProduitPanier> produits) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Paiement accepté'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text('Votre commande a été validée !'),
                const SizedBox(height: 15),

                // Détails de la commande
                const Text(
                  'Détails de la commande:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                // Liste des produits
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Column(
                      children: produits.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantite}x ${item.produit.nom}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(item.produit.prix * item.quantite).toStringAsFixed(2)} DA',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const Divider(thickness: 1),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${montantTotal.toStringAsFixed(2)} DA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Nouveau solde
                Text(
                  'Nouveau solde: ${soldeActuel.toStringAsFixed(2)} DA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('OK'),
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
          title: const Text('Statut du Distributeur'),
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
                  const SizedBox(width: 10),
                  Text(
                    isInMaintenance ? 'En maintenance' : 'Disponible',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text('ID Distributeur: DIS-42501'),
              const Text('Dernière mise à jour: 16/03/2025'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Après avoir effectué un paiement, mettre à jour l'ID utilisateur dans le NotificationProvider
  void _updateNotificationProviderUserId() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // Vérifier si l'ID utilisateur dans le NotificationProvider est différent de celui dans UserProvider
    if (notificationProvider.userId != userProvider.userId &&
        userProvider.userId.isNotEmpty) {
      // Technique pour mettre à jour l'ID utilisateur du NotificationProvider
      // Créer un nouveau NotificationProvider avec le bon ID et remplacer l'ancien
      final service = NotificationService(baseUrl: apiBaseUrl);

      // Utiliser le même service mais avec le nouvel ID utilisateur
      Provider.of<NotificationProvider>(context, listen: false)
          .updateUserId(userProvider.userId);
    }
  }
}
