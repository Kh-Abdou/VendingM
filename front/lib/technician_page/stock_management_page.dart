import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:lessvsfull/services/api_service.dart';
import '../services/product_service.dart';
import '../services/chariot_service.dart';
import 'dart:io';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';

class StockManagementPage extends StatefulWidget {
  final Color primaryColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const StockManagementPage({
    super.key,
    required this.primaryColor,
    required this.buttonColor,
    required this.buttonTextColor,
  });

  @override
  _StockManagementPageState createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  List<Product> _products = [];
  List<Chariot> _chariots = [];
  bool _isLoadingProducts = true;
  bool _isLoadingChariots = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Chargement des données (produits et chariots) depuis l'API
  Future<void> _loadData() async {
    developer.log('🔄 Début du chargement des données...');
    await Future.wait([
      _loadProducts(),
      _loadChariots(),
    ]);
    developer.log('✅ Chargement des données terminé');
  }

  // Chargement des produits depuis l'API
  Future<void> _loadProducts() async {
    developer.log('📦 Chargement des produits...');
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = '';
    });

    try {
      final products = await ProductService.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
      developer.log('✅ ${products.length} produits chargés');
    } catch (e) {
      developer.log('❌ Erreur lors du chargement des produits: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des produits: $e';
          _isLoadingProducts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des produits: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Chargement des chariots depuis l'API
  Future<void> _loadChariots() async {
    developer.log('🛒 Chargement des chariots...');
    setState(() {
      _isLoadingChariots = true;
    });

    try {
      final chariots = await ChariotService.getAllChariots();
      if (mounted) {
        setState(() {
          _chariots = chariots;
          _isLoadingChariots = false;
        });
      }
      developer.log('✅ ${chariots.length} chariots chargés');
    } catch (e) {
      developer.log('❌ Erreur lors du chargement des chariots: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des chariots: $e';
          _isLoadingChariots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des chariots: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = _isLoadingProducts || _isLoadingChariots;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: widget.primaryColor.withOpacity(0.1),
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
              Row(
                children: [
                  // Bouton de rafraîchissement
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Rafraîchir la liste',
                    color: widget.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  // Bouton d'ajout de produit
                  Container(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: ElevatedButton.icon(
                      onPressed: _showAddProductDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Ajouter',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.buttonColor,
                        foregroundColor: widget.buttonTextColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Erreur: $_errorMessage',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.buttonColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  : _products.isEmpty
                      ? const Center(child: Text('Aucun produit disponible'))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: AnimationLimiter(
                            child: ListView.builder(
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: Card(
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: product.imageUrl != null &&
                                                    product.imageUrl!.isNotEmpty
                                                ? product.imageUrl!
                                                        .startsWith('http')
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Image.network(
                                                          product.imageUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context,
                                                                  error,
                                                                  stackTrace) =>
                                                              const Icon(
                                                                  Icons
                                                                      .fastfood,
                                                                  size: 30),
                                                        ),
                                                      )
                                                    : product.imageUrl!
                                                            .startsWith('/')
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            child: Image.file(
                                                              File(product
                                                                  .imageUrl!),
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context,
                                                                      error,
                                                                      stackTrace) =>
                                                                  const Icon(
                                                                      Icons
                                                                          .fastfood,
                                                                      size: 30),
                                                            ),
                                                          )
                                                        : product.imageUrl!
                                                                .startsWith(
                                                                    'uploads/')
                                                            ? ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                child: Image
                                                                    .network(
                                                                  '${ApiService.baseUrl}/${product.imageUrl!}',
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) =>
                                                                      const Icon(
                                                                          Icons
                                                                              .fastfood,
                                                                          size:
                                                                              30),
                                                                ),
                                                              )
                                                            : ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                child:
                                                                    Image.asset(
                                                                  product
                                                                      .imageUrl!,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) =>
                                                                      const Icon(
                                                                          Icons
                                                                              .fastfood,
                                                                          size:
                                                                              30),
                                                                ),
                                                              )
                                                : const Icon(Icons.fastfood,
                                                    size: 30),
                                          ),
                                          title: Text(product.name),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  'Prix: ${product.price} DA • Stock: ${product.quantity}'),
                                              if (product.chariotId != null)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.shopping_cart,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _getChariotName(
                                                          product.chariotId!),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () {
                                                  _showEditProductDialog(
                                                      product);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  _showDeleteProductConfirmation(
                                                      product);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  // Récupérer le nom du chariot à partir de son ID
  String _getChariotName(String chariotId) {
    final chariot = _chariots.firstWhere(
      (c) => c.id == chariotId,
      orElse: () => Chariot(
        name: 'Chariot inconnu',
        capacity: 0,
        status: 'Inconnu',
        currentProducts: [],
      ),
    );
    return chariot.name;
  }

  // Pour vérifier si un chariot contient déjà un produit d'un type différent
  bool _isChariotOccupiedWithDifferentProduct(
      String chariotId, String productName) {
    // Trouver le chariot par ID
    final chariot = _chariots.firstWhere(
      (c) => c.id == chariotId,
      orElse: () => Chariot(
        name: 'Chariot inconnu',
        capacity: 0,
        status: 'Inconnu',
        currentProducts: [],
      ),
    );

    // Si le chariot est disponible, ou s'il contient déjà le même type de produit, c'est OK
    return chariot.status != 'Disponible' &&
        chariot.currentProductType != null &&
        chariot.currentProductType != productName;
  }

  // Mettre à jour la liste des chariots disponibles pour un produit spécifique
  Future<List<Map<String, dynamic>>> _getAvailableChariotsForProduct(
      String productName) async {
    try {
      // Récupérer les chariots disponibles pour ce produit
      final availableChariots =
          await ChariotService.getAvailableChariotsForProduct(productName);

      // Convertir en format compatible avec l'interface
      return availableChariots.map((chariot) {
        return {
          'id': chariot.id,
          'name': chariot.name,
          'capacity': chariot.capacity,
          'status': chariot.status,
          'isAvailable': chariot.status == 'Disponible' ||
              (chariot.currentProductType == productName &&
                  chariot.status != 'Complet')
        };
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des chariots disponibles: $e');
      // En cas d'erreur, utiliser les données en cache
      return _chariots.map((chariot) {
        bool isAvailable = chariot.status == 'Disponible' ||
            (chariot.currentProductType == productName &&
                chariot.status != 'Complet');
        return {
          'id': chariot.id,
          'name': chariot.name,
          'capacity': chariot.capacity,
          'status': chariot.status,
          'isAvailable': isAvailable
        };
      }).toList();
    }
  }

  void _showAddProductDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    // Valeur par défaut pour le chariot (aucun sélectionné initialement)
    String? selectedChariotId;
    // Liste des chariots disponibles (sera mise à jour quand l'utilisateur entre un nom de produit)
    List<Map<String, dynamic>> availableChariots =
        await _getAvailableChariotsForProduct('');

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
                      onChanged: (productName) async {
                        // Mettre à jour la liste des chariots disponibles quand le nom de produit change
                        final updatedChariots =
                            await _getAvailableChariotsForProduct(productName);
                        setState(() {
                          availableChariots = updatedChariots;

                          // Si le chariot sélectionné n'est plus disponible pour ce produit, réinitialiser la sélection
                          if (selectedChariotId != null) {
                            final selectedChariot =
                                availableChariots.firstWhere(
                              (c) => c['id'] == selectedChariotId,
                              orElse: () => {'isAvailable': false},
                            );
                            if (!selectedChariot['isAvailable']) {
                              selectedChariotId = null;
                            }
                          }
                        });
                      },
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
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedChariotId,
                          hint: const Text('Sélectionner un chariot'),
                          items: availableChariots.map((chariot) {
                            final bool isAvailable =
                                chariot['isAvailable'] ?? false;
                            return DropdownMenuItem<String>(
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
                          onChanged: (String? value) {
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
                                    child: Image.file(
                                      File(selectedImagePath!),
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
                              backgroundColor: widget.primaryColor,
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
                  onPressed: () async {
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

                    // Création d'un nouveau produit
                    final newProduct = Product(
                      name: nameController.text,
                      price: price,
                      quantity: quantity,
                      imageUrl:
                          selectedImagePath ?? 'assets/default_product.png',
                      chariotId: selectedChariotId,
                    );

                    try {
                      // Afficher un indicateur de chargement
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      // Appel API pour ajouter le produit
                      final addedProduct =
                          await ProductService.addProduct(newProduct);

                      // Si l'ajout a réussi et que le produit a un chariot, ajoutons-le au chariot aussi
                      if (addedProduct.id != null &&
                          addedProduct.chariotId != null) {
                        final result = await ChariotService.addProductToChariot(
                            addedProduct.chariotId!, addedProduct.id!);

                        // Vérifier si l'ajout au chariot a échoué
                        if (!result['success']) {
                          // Si l'ajout du produit au chariot a échoué, supprimer le produit
                          if (addedProduct.id != null) {
                            await ProductService.deleteProduct(
                                addedProduct.id!);
                          }

                          // Fermer le dialogue de chargement
                          Navigator.pop(context);

                          // Afficher un message d'erreur
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: ${result['message']}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      }

                      // Recharger les données pour obtenir l'état le plus récent
                      await _loadData();

                      // Fermer le dialogue de chargement
                      Navigator.pop(context);

                      // Fermer le dialogue d'ajout
                      Navigator.pop(context);

                      // Afficher un message de succès
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Produit "${addedProduct.name}" ajouté avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      // Fermer le dialogue de chargement
                      Navigator.pop(context);

                      // Afficher un message d'erreur
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de l\'ajout: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.buttonColor,
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

  void _showEditProductDialog(Product product) async {
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toString());
    final quantityController =
        TextEditingController(text: product.quantity.toString());

    String? selectedChariotId = product.chariotId;
    String? selectedImagePath;

    // Liste des chariots disponibles pour ce produit
    List<Map<String, dynamic>> availableChariots =
        await _getAvailableChariotsForProduct(product.name);

    // Vérifier si le chariot actuel du produit est dans la liste des chariots disponibles
    // Si non, l'ajouter pour éviter l'erreur de dropdown
    if (selectedChariotId != null) {
      bool chariotExists =
          availableChariots.any((c) => c['id'] == selectedChariotId);

      if (!chariotExists) {
        // Trouver les informations du chariot actuel
        final currentChariot = _chariots.firstWhere(
          (c) => c.id == selectedChariotId,
          orElse: () => Chariot(
            id: selectedChariotId,
            name: 'Chariot actuel',
            capacity: 0,
            status: 'Actuel',
            currentProducts: [],
          ),
        );

        // Ajouter le chariot actuel à la liste des chariots disponibles
        availableChariots.add({
          'id': currentChariot.id,
          'name': currentChariot.name,
          'capacity': currentChariot.capacity,
          'status': currentChariot.status,
          'isAvailable':
              true // Le chariot actuel est toujours disponible pour ce produit
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      onChanged: (productName) async {
                        // Mettre à jour la liste des chariots disponibles quand le nom de produit change
                        final updatedChariots =
                            await _getAvailableChariotsForProduct(productName);

                        // S'assurer que le chariot actuel est toujours inclus
                        if (product.chariotId != null) {
                          bool chariotExists = updatedChariots
                              .any((c) => c['id'] == product.chariotId);

                          if (!chariotExists) {
                            final currentChariot = _chariots.firstWhere(
                              (c) => c.id == product.chariotId,
                              orElse: () => Chariot(
                                id: product.chariotId,
                                name: 'Chariot actuel',
                                capacity: 0,
                                status: 'Actuel',
                                currentProducts: [],
                              ),
                            );

                            updatedChariots.add({
                              'id': currentChariot.id,
                              'name': currentChariot.name,
                              'capacity': currentChariot.capacity,
                              'status': currentChariot.status,
                              'isAvailable':
                                  true // Le chariot actuel est toujours disponible pour ce produit
                            });
                          }
                        }

                        setState(() {
                          availableChariots = updatedChariots;

                          // Si le chariot sélectionné n'est pas dans la liste mise à jour,
                          // revenir au chariot actuel du produit
                          if (selectedChariotId != null) {
                            bool selectedExists = availableChariots
                                .any((c) => c['id'] == selectedChariotId);
                            if (!selectedExists) {
                              selectedChariotId = product.chariotId;
                            }
                          }
                        });
                      },
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
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedChariotId,
                          hint: const Text('Sélectionner un chariot'),
                          items: availableChariots.map((chariot) {
                            // Le chariot actuel du produit est toujours disponible, les autres suivent la règle normale
                            final bool isAvailable =
                                chariot['id'] == product.chariotId ||
                                    chariot['isAvailable'] == true;

                            return DropdownMenuItem<String>(
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
                                      chariot['id'] == product.chariotId
                                          ? 'Chariot actuel'
                                          : chariot['status'],
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
                          onChanged: (String? value) {
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
                                    child: Image.file(
                                      File(selectedImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : product.imageUrl != null &&
                                        product.imageUrl!.isNotEmpty
                                    ? product.imageUrl!.startsWith('http')
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              product.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.fastfood,
                                                      size: 40),
                                            ),
                                          )
                                        : product.imageUrl!.startsWith('/')
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(product.imageUrl!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(Icons.fastfood,
                                                          size: 40),
                                                ),
                                              )
                                            : product.imageUrl!
                                                    .startsWith('uploads/')
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      '${ApiService.baseUrl}/${product.imageUrl!}',
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                              Icons.fastfood,
                                                              size: 40),
                                                    ),
                                                  )
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.asset(
                                                      product.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                              Icons.fastfood,
                                                              size: 40),
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
                              backgroundColor: widget.primaryColor,
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
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validation des champs
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        quantityController.text.isEmpty ||
                        selectedChariotId == null) {
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

                    try {
                      // Afficher un indicateur de chargement
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      // Vérifier si le chariot a changé
                      final bool chariotChanged =
                          product.chariotId != selectedChariotId;

                      // Si le chariot a changé, supprimer le produit de l'ancien chariot et l'ajouter au nouveau
                      if (chariotChanged) {
                        // Supprimer de l'ancien chariot si existant
                        if (product.chariotId != null && product.id != null) {
                          await ChariotService.removeProductFromChariot(
                              product.chariotId!, product.id!);
                        }
                      }

                      // Créer l'objet produit mis à jour
                      final updatedProduct = Product(
                        id: product.id,
                        name: nameController.text,
                        price: price,
                        quantity: quantity,
                        imageUrl: selectedImagePath ?? product.imageUrl,
                        chariotId: selectedChariotId,
                      );

                      // Appel API pour mettre à jour le produit
                      final result =
                          await ProductService.updateProduct(updatedProduct);

                      // Si le chariot a changé, ajouter le produit au nouveau chariot
                      if (chariotChanged &&
                          result.id != null &&
                          result.chariotId != null) {
                        await ChariotService.addProductToChariot(
                            result.chariotId!, result.id!);
                      }

                      // Recharger les données pour obtenir l'état le plus récent
                      await _loadData();

                      // Fermer le dialogue de chargement
                      Navigator.pop(context);

                      // Fermer le dialogue de modification
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Produit modifié avec succès')),
                      );
                    } catch (e) {
                      // Fermer le dialogue de chargement
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Erreur lors de la modification: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.buttonColor,
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

  void _showDeleteProductConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer ${product.name} du stock?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Fermer le dialogue de confirmation

                // Afficher un indicateur de chargement
                final loadingDialogContext = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Produit sans ID, message d'erreur
                  if (product.id == null) {
                    Navigator.of(loadingDialogContext)
                        .pop(); // Fermer le dialogue de chargement
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Impossible de supprimer: ID du produit manquant'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Si le produit est associé à un chariot, le retirer d'abord avec timeout
                  if (product.chariotId != null) {
                    final removeResult =
                        await ChariotService.removeProductFromChariot(
                            product.chariotId!, product.id!);

                    // Si l'opération a échoué sans timeout, afficher l'erreur et arrêter
                    if (!removeResult['success'] && !removeResult['timeout']) {
                      Navigator.of(loadingDialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${removeResult['message']}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Si timeout mais qu'on continue quand même, informer l'utilisateur
                    if (removeResult['timeout']) {
                      debugPrint(
                          'Timeout lors de la suppression du produit du chariot, on continue...');
                    }
                  }

                  // Appel API pour supprimer le produit avec timeout
                  final success =
                      await ProductService.deleteProduct(product.id!);

                  // Recharger les données
                  await _loadData();

                  // Fermer le dialogue de chargement (s'il est encore ouvert)
                  if (Navigator.canPop(loadingDialogContext)) {
                    Navigator.of(loadingDialogContext).pop();
                  }

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} supprimé avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Erreur lors de la suppression du produit'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // Fermer le dialogue de chargement (s'il est encore ouvert)
                  if (Navigator.canPop(loadingDialogContext)) {
                    Navigator.of(loadingDialogContext).pop();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
}
