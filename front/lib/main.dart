import 'package:flutter/material.dart';
import 'package:lessvsfull/client_page/products_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;
import 'theme/app_design_system.dart'; // Import our design system
import 'theme/app_theme.dart'; // Import our theme
import 'Login/login_page.dart';
import 'admin_page/admin_page.dart';
import 'client_page/notification_page.dart';
import 'client_page/products_page.dart' as products_page show ProduitPanier;
import 'client_page/profile_page.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/hardware_service.dart'; // Import for hardware service
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart'; // Import du nouveau provider
import 'providers/hardware_provider.dart'; // Import for hardware provider
import 'models/produit.dart';
import 'dart:developer' as developer;

import 'technician_page/notifications_page.dart';
import 'components/machine_status_upbar.dart';

// Définir l'URL du backend - modifier cette URL selon votre environnement
// Pour le développement sur émulateur Android, utilisez 10.0.2.2:5000
// Pour le développement sur appareil physique, utilisez l'IP de votre machine sur le réseau local
// const String apiBaseUrl = 'http://localhost:5000'; // Fonctionne uniquement sur le web
// const String apiBaseUrl = 'http://10.0.2.2:5000'; // Pour les émulateurs Android
const String apiBaseUrl =
    'http://192.168.1.8:5000'; // Pour votre téléphone physique
// const String apiBaseUrl = 'http://[IP_DE_VOTRE_MACHINE]:5000'; // Pour les appareils physiques

// ID de technicien par défaut (sera remplacé par l'ID réel après la connexion)
const String defaultTechnicianId =
    '681154075cf30e38df588370'; // ID utilisé dans test-notifications.js

// ID client par défaut (à remplacer par l'ID réel après connexion)
const String defaultClientId =
    '68120db1321b2ae6e7d61ab2'; // Exemple d'ID client

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the design system and preload fonts
  await AppDesignSystem.initialize();
  // Initialize notification service
  final notificationService = NotificationService(baseUrl: apiBaseUrl);

  // Initialize hardware service
  final hardwareService = HardwareService(baseUrl: apiBaseUrl);

  // Start the app
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
        ChangeNotifierProvider(
          create: (context) => HardwareProvider(
            hardwareService: hardwareService,
          ),
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
    // Initialize ScreenUtil with a design size
    return ScreenUtilInit(
      // Design size is based on standard mobile app dimensions
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Distributeur Automatique',
          // Use our design system themes
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode: ThemeMode.system,
          home: LoginPage(),
          routes: {
            '/admin_home': (context) => const AdminHomePage(),
          },
        );
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
  @override
  void initState() {
    super.initState();
    _orderService = OrderService(baseUrl: apiBaseUrl);

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
        actions: [
          // Machine status upbar
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: MachineStatusUpbar(
              primaryColor: Theme.of(context).primaryColor,
            ),
          ),
          // Cart icon with animated badge
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -10, end: -8),
              badgeContent: Text(
                panier.length.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              showBadge: panier.length > 0,
              badgeStyle: badges.BadgeStyle(
                badgeColor: Theme.of(context).colorScheme.secondary,
                padding: EdgeInsets.all(8.r),
                elevation: 3,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: Icon(Icons.shopping_cart, size: 28.sp),
                onPressed: () => _showPanier(),
              ),
            ),
          ),
          SizedBox(width: 8.w),
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
            icon: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -8, end: -10),
              badgeContent: Text(
                unreadNotificationsCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              showBadge: unreadNotificationsCount > 0,
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(6.r),
                elevation: 3,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.notifications, size: 28.sp),
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
    // Trigger the badge animation by updating the cart
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

    // Show a snackbar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produit.nom} ajouté au panier'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Voir panier',
          onPressed: _showPanier,
        ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double total = 0;
            for (var item in panier) {
              total += item.produit.prix * item.quantite;
            }

            return Container(
              padding: EdgeInsets.all(20.r),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Votre Panier',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${panier.length} article${panier.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: panier.length,
                      itemBuilder: (context, index) {
                        final item = panier[index];
                        final produit = item.produit;
                        final subtotal = produit.prix * item.quantite;

                        return Card(
                          margin: EdgeInsets.only(bottom: 10.h),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12.r),
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
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
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Prix unitaire: ${produit.prix.toStringAsFixed(2)} DA',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    Text(
                                      'Sous-total: ${subtotal.toStringAsFixed(2)} DA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon:
                                                Icon(Icons.remove, size: 18.sp),
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
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10.w),
                                            child: Text(
                                              '${item.quantite}',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add, size: 18.sp),
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
                  Divider(thickness: 1),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(2)} DA',
                                style: TextStyle(
                                  fontSize: 18.sp,
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
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                          ),
                          child: Text('Vider le panier',
                              style: TextStyle(fontSize: 16.sp)),
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
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                          ),
                          child: Text('Commander',
                              style: TextStyle(fontSize: 16.sp)),
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
                  subtitle:
                      const Text('Pour payer directement au distributeur'),
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
          title: Text('Confirmer la commande',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Payer avec votre e-wallet',
                  style: TextStyle(fontSize: 16.sp)),
              SizedBox(height: 15.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: Colors.green, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '${Provider.of<UserProvider>(context, listen: false).userBalance.toStringAsFixed(2)} DA',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Text(
                'Montant à débiter: ${_calculateTotal().toStringAsFixed(2)} DA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Annuler', style: TextStyle(fontSize: 16.sp)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Confirmer', style: TextStyle(fontSize: 16.sp)),
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
          content: const Text(
              'Votre solde est insuffisant pour effectuer cet achat.'),
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
        .toList(); // Afficher l'indicateur de progression
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

    try {
      // Appel au service pour effectuer le paiement
      final result = await _orderService.processPayment(
        userId: userProvider.userId,
        amount: totalAmount,
        products: productsData,
      );

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      if (!result.containsKey('orderId')) {
        throw Exception("La réponse du serveur est invalide ou incomplète");
      } // Afficher le dialogue d'attente pour les produits
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Distribution en cours'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Veuillez patienter que les produits tombent...'),
                SizedBox(height: 10),
                Text(
                  'Le capteur VL53L0X détecte vos produits',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ); // Polling pour vérifier l'état de la commande
      bool orderProcessed = false;
      bool orderSuccessful = false;
      String failureReason = "";
      Map<String, dynamic>?
          lastOrderStatus; // Store the last order status for detailed error display
      int attempts = 0;

      // Calculate dynamic timeout based on order size: 30s base + 5s per product (max 2 minutes)
      int totalProducts = panier.fold(0, (sum, item) => sum + item.quantite);
      int calculatedMaxAttempts =
          (30 + (totalProducts * 5)).clamp(30, 120); // 30s to 2min
      developer.log(
          'Dynamic timeout: $calculatedMaxAttempts seconds for $totalProducts products',
          name: 'OrderPolling');

      const pollInterval =
          1; // Polling chaque seconde pour une meilleure réactivité

      while (!orderProcessed && attempts < calculatedMaxAttempts) {
        attempts++;
        await Future.delayed(Duration(seconds: pollInterval));
        try {
          final orderStatus =
              await _orderService.getOrderStatus(result['orderId']);

          // Store the latest order status for potential use in error dialog
          lastOrderStatus = orderStatus;
          developer.log(
              'Polling attempt $attempts/$calculatedMaxAttempts - Status: ${orderStatus['status']}',
              name:
                  'OrderPolling'); // DETAILED DEBUGGING: Log all response fields
          developer.log('Order Status Details:', name: 'OrderPolling');
          developer.log('- orderId: ${orderStatus['orderId']}',
              name: 'OrderPolling');
          developer.log('- status: ${orderStatus['status']}',
              name: 'OrderPolling');
          developer.log(
              '- success: ${orderStatus['success']} (type: ${orderStatus['success'].runtimeType})',
              name: 'OrderPolling');
          developer.log(
              '- dispensingStatus: ${orderStatus['dispensingStatus']}',
              name: 'OrderPolling');
          developer.log(
              '- isPartialDispensing: ${orderStatus['isPartialDispensing']}',
              name: 'OrderPolling');
          developer.log('- hardwareDetails: ${orderStatus['hardwareDetails']}',
              name: 'OrderPolling');
          developer.log(
              '- dispensingDetails: ${orderStatus['dispensingDetails']}',
              name: 'OrderPolling');
          if (orderStatus['dispensingStatus'] != null) {
            developer.log(
                '- allProductsDetected: ${orderStatus['dispensingStatus']['allProductsDetected']}',
                name: 'OrderPolling');
            developer.log(
                '- dispensedAt: ${orderStatus['dispensingStatus']['dispensedAt']}',
                name: 'OrderPolling');
            developer.log(
                '- isDispensingInProgress: ${orderStatus['dispensingStatus']['isDispensingInProgress']}',
                name: 'OrderPolling');
          }
          if (orderStatus.containsKey('status')) {
            String currentStatus = orderStatus['status'];

            // Check for completed order (success)
            if (currentStatus == 'COMPLETED') {
              orderProcessed = true;

              // Check for partial dispensing
              bool isPartialDispensing =
                  orderStatus['isPartialDispensing'] ?? false;
              if (isPartialDispensing) {
                orderSuccessful =
                    false; // Treat partial as failure for UI dialog
                int totalDispensed =
                    orderStatus['dispensingStatus']?['totalDispensed'] ?? 0;
                int totalExpected =
                    orderStatus['dispensingStatus']?['totalExpected'] ?? 0;
                failureReason =
                    "Distribution partielle: $totalDispensed/$totalExpected produits distribués";
                developer.log('Order partially completed: $failureReason',
                    name: 'OrderPolling');

                // Clear cart for partial dispensing since products were partially delivered
                setState(() {
                  panier.clear();
                });
                developer.log('Cart cleared after partial dispensing',
                    name: 'OrderProcessing');
              } else {
                orderSuccessful = true;
                developer.log('Order completed successfully: status=COMPLETED',
                    name: 'OrderPolling');
              }
              break;
            }

            // Check for failed order
            if (currentStatus == 'FAILED') {
              orderProcessed = true;
              orderSuccessful = false;
              failureReason = orderStatus['failureReason'] ??
                  orderStatus['message'] ??
                  "Erreur lors de la distribution";
              developer.log('Order failed: $failureReason',
                  name: 'OrderPolling');
              break;
            }

            // For PENDING status, continue polling (don't break)
            if (currentStatus == 'PENDING') {
              developer.log('Order still pending, continuing to poll...',
                  name: 'OrderPolling');
              // Continue the loop - don't break or set orderProcessed = true
            }
          }
        } catch (e) {
          developer.log('Erreur lors de la vérification du statut: $e',
              name: 'OrderPolling');
        }
      }

      // Si les produits n'ont pas été traités après le nombre maximum de tentatives
      if (!orderProcessed) {
        developer.log('Temps d\'attente dépassé pour la détection des produits',
            name: 'OrderPolling');
        // Considérer comme un échec après le timeout
        orderSuccessful = false;
        failureReason =
            "Délai d'attente dépassé pour la détection des produits";
      } // Fermer le dialogue d'attente
      Navigator.of(context)
          .pop(); // Gérer le résultat en fonction du succès/échec de la commande
      if (orderSuccessful) {
        // Refresh balance from server to ensure accuracy
        developer.log('Order successful, refreshing balance from server',
            name: 'OrderProcessing');

        // Make multiple attempts to fetch fresh balance if needed
        double freshBalance = 0;
        bool balanceRefreshed = false;

        for (int i = 0; i < 3; i++) {
          // Make up to 3 attempts
          try {
            // Wait briefly before retry to allow backend to complete transaction
            if (i > 0) {
              await Future.delayed(Duration(milliseconds: 500));
            }

            freshBalance =
                await _orderService.getEWalletBalance(userProvider.userId);
            developer.log(
                'Fresh balance retrieved (attempt ${i + 1}): $freshBalance',
                name: 'OrderProcessing');

            balanceRefreshed = true;
            break; // Exit the retry loop if successful
          } catch (e) {
            developer.log('Error refreshing balance (attempt ${i + 1}): $e',
                name: 'OrderProcessing');
          }
        }

        if (balanceRefreshed) {
          // Update user balance with fresh data from server
          userProvider.updateBalance(freshBalance);
        } else {
          // Fallback: use balance from order response if available
          developer.log('Using fallback balance calculation',
              name: 'OrderProcessing');
          double fallbackBalance;
          if (result['balance'] != null) {
            fallbackBalance = result['balance'] is int
                ? (result['balance'] as int).toDouble()
                : result['balance'];
            developer.log('Using balance from response: $fallbackBalance',
                name: 'OrderProcessing');
          } else {
            // Final fallback: calculate manually
            fallbackBalance = userProvider.userBalance - totalAmount;
            developer.log('Using calculated balance: $fallbackBalance',
                name: 'OrderProcessing');
          }

          userProvider.updateBalance(fallbackBalance);
        }

        // Clear cart after successful order
        setState(() {
          panier.clear();
        });

        // Show success dialog with proper balance
        _showPaiementReussi(userProvider.userBalance, totalAmount, panierCopy);
      } else {
        // Si la commande a échoué, ne pas déduire le montant
        // Afficher un message d'échec avec la raison
        _showCommandeEchouee(
            failureReason, result['orderId'], panierCopy, lastOrderStatus);

        // Pas besoin de vider le panier en cas d'échec
      } // Rafraîchir les notifications après un délai pour permettre au backend de traiter
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          final notificationProvider =
              Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.forceRefresh();
        }
      });
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
          title: Text('Commande Complétée',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60.sp,
                ),
                SizedBox(height: 20.h),
                Text('Votre commande a été validée !',
                    style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 15.h),

                // Détails de la commande
                Text(
                  'Détails de la commande:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 10.h),

                // Liste des produits
                Container(
                  constraints: BoxConstraints(maxHeight: 150.h),
                  child: SingleChildScrollView(
                    child: Column(
                      children: produits.map((item) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantite}x ${item.produit.nom}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                              Text(
                                '${(item.produit.prix * item.quantite).toStringAsFixed(2)} DA',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Divider(thickness: 1),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      '${montantTotal.toStringAsFixed(2)} DA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 15.h),

                // Nouveau solde
                Text(
                  'Nouveau solde: ${soldeActuel.toStringAsFixed(2)} DA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text('OK', style: TextStyle(fontSize: 16.sp)),
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
          title: Text('Statut du Distributeur',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isInMaintenance ? Icons.warning : Icons.check_circle,
                    color: isInMaintenance ? Colors.amber : Colors.green,
                    size: 24.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    isInMaintenance ? 'En maintenance' : 'Disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Text('ID Distributeur: DIS-42501',
                  style: TextStyle(fontSize: 14.sp)),
              Text('Dernière mise à jour: 16/03/2025',
                  style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Fermer', style: TextStyle(fontSize: 16.sp)),
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
      // Utiliser le même service mais avec le nouvel ID utilisateur
      Provider.of<NotificationProvider>(context, listen: false)
          .updateUserId(userProvider.userId);
    }
  }

  // Méthode pour afficher une alerte lorsque la commande a échoué
  void _showCommandeEchouee(
      String raison, String orderId, List<products_page.ProduitPanier> produits,
      [Map<String, dynamic>? orderStatusData]) {
    // Check if this is a partial dispensing case
    bool isPartialDispensing = raison.contains("Distribution partielle");

    // Extract dispensing details from order status data
    Map<String, dynamic>? dispensingStatus =
        orderStatusData?['dispensingStatus'];
    int totalDispensed = dispensingStatus?['totalDispensed'] ?? 0;
    int totalExpected = dispensingStatus?['totalExpected'] ??
        produits.fold(
            0,
            (sum, item) =>
                sum +
                item.quantite); // Get detailed per-couloir dispensing information if available
    List<dynamic>? dispensingDetails = orderStatusData?['hardwareDetails']
            ?['completion']?['details'] ??
        orderStatusData?['dispensingDetails']?['details'];

    // Debug: Log what dispensing details we received
    if (dispensingDetails != null) {
      developer.log('Detailed dispensing data received: $dispensingDetails',
          name: 'DispensingDetails');
    } else {
      developer.log('No detailed dispensing data available',
          name: 'DispensingDetails');
      developer.log(
          'Available order status data keys: ${orderStatusData?.keys.toList()}',
          name: 'DispensingDetails');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              isPartialDispensing
                  ? 'Distribution partielle'
                  : 'Commande non complétée',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isPartialDispensing ? Colors.orange : Colors.red)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPartialDispensing
                        ? Icons.warning_amber
                        : Icons.error_outline,
                    color: isPartialDispensing ? Colors.orange : Colors.red,
                    size: 60.sp,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                      isPartialDispensing
                          ? 'Certains produits n\'ont pas pu être distribués.'
                          : 'La distribution des produits a échoué.',
                      style: TextStyle(fontSize: 16.sp)),

                  if (isPartialDispensing &&
                      totalDispensed > 0 &&
                      totalExpected > 0) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Produits distribués: $totalDispensed sur $totalExpected',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 15.h),
                  Text('ID de commande: $orderId',
                      style:
                          TextStyle(fontSize: 14.sp, color: Colors.grey[700])),
                  SizedBox(height: 15.h),

                  // Enhanced product details with dispensing status
                  Text(
                    isPartialDispensing
                        ? 'État de distribution par produit:'
                        : 'Produits commandés:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Enhanced product list with individual status
                  Container(
                    constraints: BoxConstraints(maxHeight: 200.h),
                    child: SingleChildScrollView(
                      child: Column(
                        children: produits.asMap().entries.map((entry) {
                          int index = entry.key;
                          products_page.ProduitPanier item = entry.value;

                          // Calculate dispensed quantity for this product
                          int dispensedForProduct =
                              item.quantite; // Default: assume all dispensed

                          // Always show dispensing data when we have partial or failed dispensing
                          bool hasDispensingData = isPartialDispensing ||
                              (!isPartialDispensing && totalDispensed == 0);

                          // Calculate actual dispensed amount based on scenario
                          if (isPartialDispensing && totalExpected > 0) {
                            // Try to use detailed hardware data first
                            if (dispensingDetails != null &&
                                dispensingDetails.isNotEmpty) {
                              // Look for matching couloir data from Arduino
                              // Since we don't have direct product-to-couloir mapping here,
                              // we'll use the order index to match with dispensing details
                              if (index < dispensingDetails.length) {
                                var detailItem = dispensingDetails[index];
                                int expectedFromArduino =
                                    detailItem['expected'] ?? item.quantite;
                                int detectedFromArduino =
                                    detailItem['detectedCount'] ?? 0;

                                // Use the Arduino's actual detection count
                                dispensedForProduct = detectedFromArduino;

                                // Validate that the expected quantity matches what we ordered
                                if (expectedFromArduino != item.quantite) {
                                  developer.log(
                                      'Warning: Arduino expected $expectedFromArduino but order has ${item.quantite} for product ${item.produit.nom}',
                                      name: 'DispensingDetails');
                                }
                              } else {
                                // Fallback to proportional calculation if no detailed data for this index
                                dispensedForProduct =
                                    ((totalDispensed * item.quantite) /
                                            totalExpected)
                                        .round();
                                dispensedForProduct =
                                    dispensedForProduct.clamp(0, item.quantite);
                              }
                            } else {
                              // Fallback to proportional calculation
                              dispensedForProduct =
                                  ((totalDispensed * item.quantite) /
                                          totalExpected)
                                      .round();
                              dispensedForProduct =
                                  dispensedForProduct.clamp(0, item.quantite);
                            }
                          } else if (!isPartialDispensing &&
                              totalDispensed == 0) {
                            // Complete failure - nothing was dispensed
                            dispensedForProduct = 0;
                          } else if (!isPartialDispensing &&
                              totalDispensed > 0) {
                            // Complete success - everything was dispensed
                            dispensedForProduct = item.quantite;
                          } // Determine dispensing status for color coding
                          bool wasFullyDispensed =
                              dispensedForProduct >= item.quantite;
                          bool wasPartiallyDispensed =
                              dispensedForProduct > 0 &&
                                  dispensedForProduct < item.quantite;

                          // Color scheme: Green = fully dispensed, Grey = partially dispensed, Red = not dispensed
                          Color backgroundColor;
                          Color borderColor;
                          Color iconColor;
                          IconData iconData;

                          if (wasFullyDispensed) {
                            backgroundColor = Colors.green.withOpacity(0.1);
                            borderColor = Colors.green.withOpacity(0.3);
                            iconColor = Colors.green;
                            iconData = Icons.check_circle_outline;
                          } else if (wasPartiallyDispensed) {
                            backgroundColor = Colors.grey.withOpacity(0.1);
                            borderColor = Colors.grey.withOpacity(0.3);
                            iconColor = Colors.grey[600]!;
                            iconData = Icons.warning_amber_outlined;
                          } else {
                            // Not dispensed
                            backgroundColor = Colors.red.withOpacity(0.1);
                            borderColor = Colors.red.withOpacity(0.3);
                            iconColor = Colors.red;
                            iconData = Icons.cancel_outlined;
                          }

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.produit.nom,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (hasDispensingData) ...[
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Distribué: $dispensedForProduct/${item.quantite}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: wasFullyDispensed
                                                ? Colors.green[700]
                                                : wasPartiallyDispensed
                                                    ? Colors.grey[700]
                                                    : Colors.red[700],
                                          ),
                                        ),
                                      ] else ...[
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Quantité: ${item.quantite}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '${(item.produit.prix * item.quantite).toStringAsFixed(2)} DA',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    decoration: (!isPartialDispensing ||
                                            wasFullyDispensed)
                                        ? null
                                        : TextDecoration.lineThrough,
                                    color: (!isPartialDispensing ||
                                            wasFullyDispensed)
                                        ? null
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isPartialDispensing
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isPartialDispensing
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPartialDispensing ? Icons.payment : Icons.money_off,
                          color: isPartialDispensing
                              ? Colors.orange
                              : Colors.green,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isPartialDispensing
                                ? 'Vous avez été facturé uniquement pour les produits distribués.'
                                : 'Aucun montant n\'a été débité de votre compte.',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: isPartialDispensing
                                  ? Colors.orange[800]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isPartialDispensing) ...[
                    SizedBox(height: 15.h),
                    Text(
                      'Si vous avez des questions, veuillez contacter notre support client avec l\'ID de commande ci-dessus.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPartialDispensing ? Colors.orange : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Compris', style: TextStyle(fontSize: 16.sp)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
