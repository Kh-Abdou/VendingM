import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'dart:io';
import '../Login/login_page.dart'; // Import login page for navigation

class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({Key? key}) : super(key: key);

  @override
  _TechnicianHomePageState createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage> {
  int _currentIndex = 0;
  bool _isRefreshing = false;

  // Updated theme colors with better contrast for buttons
  final Color primaryColor = const Color(0xFF6B2FEB); // App's primary purple
  final Color buttonColor =
      const Color(0xFF5026B9); // Deeper purple for buttons
  final Color buttonTextColor =
      Colors.white; // White text for better visibility

  // Données simulées des notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Niveau de stock bas',
      'message': 'Le produit Cola est presque épuisé (5 restants)',
      'date': '2023-12-01',
      'isRead': false,
      'type': 'stock',
      'priority': 'warning', // warning, critical, info
    },
    {
      'id': 2,
      'title': 'Problème technique',
      'message': 'Le distributeur signale une erreur de paiement',
      'date': '2023-12-02',
      'isRead': false,
      'type': 'technical',
      'priority': 'critical',
    },
    {
      'id': 3,
      'title': 'Maintenance prévue',
      'message': 'Maintenance planifiée pour le distributeur le 10/12',
      'date': '2023-12-03',
      'isRead': true,
      'type': 'technical',
      'priority': 'info',
    },
    {
      'id': 4,
      'title': 'Stock critique',
      'message': 'Le produit Chocolat est presque épuisé (2 restants)',
      'date': '2023-12-04',
      'isRead': false,
      'type': 'stock',
      'priority': 'critical',
    },
  ];

  // Mettre à jour la liste des produits
  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'Cola',
      'price': 120.0,
      'quantity': 15,
      'imageUrl': 'assets/cola.png',
      'chariotId': 3,
    },
    {
      'id': 2,
      'name': 'Eau minérale',
      'price': 70.0,
      'quantity': 25,
      'imageUrl': 'assets/water.png',
      'chariotId': 3,
    },
    {
      'id': 3,
      'name': 'Chocolat',
      'price': 100.0,
      'quantity': 8,
      'imageUrl': 'assets/chocolate.png',
      'chariotId': 4,
    },
  ];

  // Données simulées du distributeur
  final Map<String, dynamic> _machine = {
    'id': 1,
    'location': 'Université - Bloc A',
    'status': 'Opérationnel',
    'lastMaintenance': '2023-11-20',
  };

  // Liste des statuts de distributeur possibles
  final List<String> _machineStatuses = [
    'Opérationnel',
    'En maintenance',
    'En panne',
    'Hors service',
    'Nécessite réapprovisionnement'
  ];

  // Ajouter cette liste de chariots dans la classe _TechnicianHomePageState
  final List<Map<String, dynamic>> _chariots = [
    {
      'id': 1,
      'name': 'Chariot 1',
      'capacity': 10,
      'currentProducts': 10, // Complet
      'status': 'Complet',
    },
    {
      'id': 2,
      'name': 'Chariot 2',
      'capacity': 10,
      'currentProducts': 10, // Complet
      'status': 'Complet',
    },
    {
      'id': 3,
      'name': 'Chariot 3',
      'capacity': 10,
      'currentProducts': 5, // À moitié plein
      'status': 'Disponible',
    },
    {
      'id': 4,
      'name': 'Chariot 4',
      'capacity': 10,
      'currentProducts': 0, // Vide
      'status': 'Disponible',
    },
  ];

  // Add these profile variables to the class
  String _technicianName = 'Technicien';
  String _technicianEmail = 'Technician@gmail.com';
  String _technicianPhone = '+213 555 123 456';
  String _technicianZone = 'Université - Campus';

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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Distributeur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
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

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildStockManagementPage();
      case 1:
        return _buildMachineStatusPage();
      case 2:
        return _buildNotificationsPage();
      case 3:
        return _buildProfilePage();
      default:
        return _buildStockManagementPage();
    }
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: primaryColor.withOpacity(0.2), // Updated color
            child: Icon(
              Icons.person,
              size: 60,
              color: primaryColor, // Updated color
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
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
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

  Widget _buildNotificationsPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: primaryColor.withOpacity(0.1), // Updated color
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications (${_notifications.where((n) => !n['isRead']).length} nouvelles)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            for (var notification in _notifications) {
                              notification['isRead'] = true;
                            }
                          });
                        },
                        child: const Text('Tout marquer comme lu'),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: primaryColor, // Updated color
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Techniques'),
                    Tab(text: 'Stock'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Problèmes techniques
                _buildNotificationsList('technical'),
                // Tab 2: Problèmes de stock
                _buildNotificationsList('stock'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String type) {
    final filteredNotifications =
        _notifications.where((n) => n['type'] == type).toList();

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'technical'
                  ? Icons.build_circle_outlined
                  : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification ${type == 'technical' ? 'technique' : 'de stock'}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];

        // Définir l'icône et la couleur selon le type et la priorité
        IconData iconData;
        Color iconColor;

        if (type == 'technical') {
          switch (notification['priority']) {
            case 'critical':
              iconData = Icons.error;
              iconColor = Colors.red;
              break;
            case 'warning':
              iconData = Icons.warning;
              iconColor = Colors.amber;
              break;
            default:
              iconData = Icons.build;
              iconColor = Colors.blue;
          }
        } else {
          // stock
          switch (notification['priority']) {
            case 'critical':
              iconData = Icons.inventory_2;
              iconColor = Colors.red;
              break;
            case 'warning':
              iconData = Icons.inventory;
              iconColor = Colors.amber;
              break;
            default:
              iconData = Icons.inventory_outlined;
              iconColor = Colors.green;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          color: notification['isRead'] ? null : Colors.blue.withOpacity(0.05),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification['isRead']
                  ? Colors.grey.withOpacity(0.2)
                  : iconColor.withOpacity(0.2),
              child: Icon(
                iconData,
                color: notification['isRead'] ? Colors.grey : iconColor,
              ),
            ),
            title: Text(
              notification['title'],
              style: TextStyle(
                fontWeight: notification['isRead']
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification['message']),
                Text(
                  'Date: ${notification['date']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Afficher plus d'options pour cette notification
              },
            ),
            onTap: () {
              setState(() {
                notification['isRead'] = true;
              });
              // Afficher les détails de la notification
            },
          ),
        );
      },
    );
  }

  Widget _buildStockManagementPage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestion des stocks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddProductDialog();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Ajouter un produit',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? const Center(child: Text('Aucun produit disponible'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: product['imageUrl'] != null &&
                                  product['imageUrl'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    product['imageUrl'],
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.fastfood, size: 30),
                        ),
                        title: Text(product['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Prix: ${product['price']} DA • Stock: ${product['quantity']}'),
                            if (product['chariotId'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.shopping_cart,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _chariots.firstWhere((c) =>
                                        c['id'] ==
                                        product['chariotId'])['name'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditProductDialog(product);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteProductConfirmation(product);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMachineStatusPage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'État du distributeur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isRefreshing ? null : _refreshMachineStatus,
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  _isRefreshing ? 'Actualisation...' : 'Actualiser',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  disabledBackgroundColor: buttonColor.withOpacity(0.6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Machine status card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            getMachineStatusIcon(_machine['status']),
                            const SizedBox(width: 10),
                            Text(
                              _machine['status'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    getMachineStatusColor(_machine['status']),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Emplacement'),
                          subtitle: Text(_machine['location']),
                          leading: const Icon(Icons.location_on),
                        ),
                        ListTile(
                          title: const Text('Dernière maintenance'),
                          subtitle: Text(_machine['lastMaintenance']),
                          leading: const Icon(Icons.calendar_today),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              'Mettre à jour le statut',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _showEditMachineStatusDialog(_machine);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: buttonTextColor,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent activities section
                const Text(
                  'Activités récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      ListTile(
                        leading: Icon(Icons.build, color: Colors.blue),
                        title: Text('Maintenance effectuée'),
                        subtitle: Text('20/11/2023 - Remplacement des filtres'),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.warning, color: Colors.amber),
                        title: Text('Problème technique résolu'),
                        subtitle: Text(
                            '15/11/2023 - Calibrage du système de paiement'),
                      ),
                      Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.inventory_2, color: Colors.green),
                        title: Text('Réapprovisionnement'),
                        subtitle: Text('10/11/2023 - Stock complété'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add a refresh function for the machine status
  void _refreshMachineStatus() {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate a network request with a delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        // Update with "new" data
        _machine['lastMaintenance'] =
            DateTime.now().toString().substring(0, 10);

        // Randomly change the status to simulate real updates
        final random = DateTime.now().millisecond % 3;
        if (random == 0 && _machine['status'] != 'Opérationnel') {
          _machine['status'] = 'Opérationnel';
          _machine.remove('issue');
        } else if (random == 1 && _machine['status'] != 'En maintenance') {
          _machine['status'] = 'En maintenance';
          _machine['issue'] = 'Maintenance programmée';
        }

        // Add a new notification about the refresh
        _notifications.insert(0, {
          'id': _notifications.length + 1,
          'title': 'Actualisation terminée',
          'message': 'Les données du distributeur ont été mises à jour',
          'date': DateTime.now().toString().substring(0, 10),
          'isRead': false,
          'type': 'technical',
          'priority': 'info',
        });

        _isRefreshing = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Données actualisées avec succès'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  Color getMachineStatusColor(String status) {
    switch (status) {
      case 'Opérationnel':
        return Colors.green;
      case 'En maintenance':
        return Colors.blue;
      case 'En panne':
        return Colors.red;
      case 'Hors service':
        return Colors.grey;
      case 'Nécessite réapprovisionnement':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget getMachineStatusIcon(String status) {
    IconData iconData;
    Color iconColor = getMachineStatusColor(status);

    switch (status) {
      case 'Opérationnel':
        iconData = Icons.check_circle;
        break;
      case 'En maintenance':
        iconData = Icons.build_circle;
        break;
      case 'En panne':
        iconData = Icons.error;
        break;
      case 'Hors service':
        iconData = Icons.cancel;
        break;
      case 'Nécessite réapprovisionnement':
        iconData = Icons.inventory;
        break;
      default:
        iconData = Icons.help;
    }

    return Icon(iconData, color: iconColor, size: 30);
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    // Valeur par défaut pour le chariot (premier chariot disponible)
    int? selectedChariotId = _chariots
        .where((c) => c['status'] == 'Disponible')
        .map((c) => c['id'])
        .firstOrNull;

    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter un produit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du produit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix (DA)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sélectionner un chariot:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedChariotId,
                          hint: const Text('Sélectionner un chariot'),
                          items: _chariots.map((chariot) {
                            final bool isAvailable =
                                chariot['status'] == 'Disponible';
                            return DropdownMenuItem<int>(
                              value: chariot['id'],
                              enabled: isAvailable,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    chariot['name'],
                                    style: TextStyle(
                                      color: isAvailable ? null : Colors.grey,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAvailable
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      chariot['status'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (int? value) {
                            setState(() {
                              selectedChariotId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Image du produit:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: selectedImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      selectedImagePath!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Choisir une image'),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setState(() {
                                  selectedImagePath = pickedFile.path;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
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
                    // Validation des champs
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        quantityController.text.isEmpty ||
                        selectedChariotId == null) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Veuillez remplir tous les champs et sélectionner un chariot'),
                        ),
                      );
                      return;
                    }

                    // Parsing des valeurs numériques
                    final price = double.tryParse(priceController.text);
                    final quantity = int.tryParse(quantityController.text);

                    if (price == null || quantity == null) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Veuillez entrer des valeurs numériques valides'),
                        ),
                      );
                      return;
                    }

                    // Ajouter le produit et mettre à jour l'état du chariot
                    setState(() {
                      // Ajouter le nouveau produit
                      _products.add({
                        'id': _products.length + 1,
                        'name': nameController.text,
                        'price': price,
                        'quantity': quantity,
                        'imageUrl':
                            selectedImagePath ?? 'assets/default_product.png',
                        'chariotId': selectedChariotId,
                      });

                      // Mettre à jour le nombre de produits dans le chariot sélectionné
                      final chariotIndex = _chariots
                          .indexWhere((c) => c['id'] == selectedChariotId);
                      if (chariotIndex != -1) {
                        _chariots[chariotIndex]['currentProducts'] =
                            (_chariots[chariotIndex]['currentProducts']
                                    as int) +
                                1;

                        // Mettre à jour le statut si le chariot est maintenant plein
                        if (_chariots[chariotIndex]['currentProducts'] >=
                            _chariots[chariotIndex]['capacity']) {
                          _chariots[chariotIndex]['status'] = 'Complet';
                        }
                      }
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Produit ajouté avec succès au ${_chariots.firstWhere((c) => c['id'] == selectedChariotId)['name']}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ajouter',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']);
    final priceController =
        TextEditingController(text: product['price'].toString());
    final quantityController =
        TextEditingController(text: product['quantity'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier un produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du produit',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Prix (DA)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation des champs
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez remplir tous les champs')),
                  );
                  return;
                }

                // Parsing des valeurs numériques
                final price = double.tryParse(priceController.text);
                final quantity = int.tryParse(quantityController.text);

                if (price == null || quantity == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Veuillez entrer des valeurs numériques valides')),
                  );
                  return;
                }

                setState(() {
                  final index =
                      _products.indexWhere((p) => p['id'] == product['id']);
                  if (index != -1) {
                    _products[index] = {
                      'id': product['id'],
                      'name': nameController.text,
                      'price': price,
                      'quantity': quantity,
                      'imageUrl': product['imageUrl'],
                    };
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produit modifié avec succès')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Mettre à jour',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteProductConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer ${product['name']} du stock?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _products.removeWhere((p) => p['id'] == product['id']);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produit supprimé avec succès')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditMachineStatusDialog(Map<String, dynamic> machine) {
    String currentStatus = machine['status'];
    String? issue = machine['issue'];
    final issueController = TextEditingController(text: issue);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Mettre à jour le statut du distributeur'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('État actuel:'),
                  DropdownButton<String>(
                    value: currentStatus,
                    isExpanded: true,
                    items: _machineStatuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          currentStatus = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Description du problème (si applicable):'),
                  TextField(
                    controller: issueController,
                    decoration: const InputDecoration(
                      hintText: 'Décrivez le problème...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _machine['status'] = currentStatus;

                      // Ajouter ou supprimer le champ 'issue' en fonction de l'état
                      if (currentStatus == 'Opérationnel') {
                        _machine.remove('issue');
                      } else if (issueController.text.isNotEmpty) {
                        _machine['issue'] = issueController.text;
                      }
                    });

                    Navigator.pop(context);
                    // Hide any existing SnackBar before showing a new one
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('État du distributeur mis à jour avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Mettre à jour',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profil Technicien'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Technicien',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Technician@gmail.com'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.call),
                title: const Text('Téléphone'),
                subtitle: const Text('+213 555 123 456'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers une page de modification du profil
                Navigator.pop(context);
              },
              child: const Text('Modifier le profil'),
            ),
          ],
        );
      },
    );
  }

  // Updated logout confirmation dialog with proper navigation
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
              Icon(Icons.edit, color: primaryColor),
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
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
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
}
