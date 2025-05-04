import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/product_service.dart';
import 'dart:io';

class StockManagementPage extends StatefulWidget {
  final Color primaryColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const StockManagementPage({
    Key? key,
    required this.primaryColor,
    required this.buttonColor,
    required this.buttonTextColor,
  }) : super(key: key);

  @override
  _StockManagementPageState createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  List<Product> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Liste des chariots (à terme, cela devrait aussi venir d'une API)
  final List<Map<String, dynamic>> _chariots = [
    {
      'id': '1',
      'name': 'Chariot 1',
      'capacity': 10,
      'currentProducts': 10, // Complet
      'status': 'Complet',
    },
    {
      'id': '2',
      'name': 'Chariot 2',
      'capacity': 10,
      'currentProducts': 10, // Complet
      'status': 'Complet',
    },
    {
      'id': '3',
      'name': 'Chariot 3',
      'capacity': 10,
      'currentProducts': 5, // À moitié plein
      'status': 'Disponible',
    },
    {
      'id': '4',
      'name': 'Chariot 4',
      'capacity': 10,
      'currentProducts': 0, // Vide
      'status': 'Disponible',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Chargement des produits depuis l'API
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await ProductService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des produits: $e';
        _isLoading = false;
      });
      _showErrorSnackBar(
          'Impossible de charger les produits. Veuillez réessayer.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: _loadProducts,
                    tooltip: 'Rafraîchir la liste',
                    color: widget.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  // Bouton d'ajout de produit
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
                      backgroundColor: widget.buttonColor,
                      foregroundColor: widget.buttonTextColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
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
                            onPressed: _loadProducts,
                            child: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.buttonColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _products.isEmpty
                      ? const Center(child: Text('Aucun produit disponible'))
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
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
                                    child: product.imageUrl != null &&
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
                                                          size: 30),
                                                ),
                                              )
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  product.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(Icons.fastfood,
                                                          size: 30),
                                                ),
                                              )
                                        : const Icon(Icons.fastfood, size: 30),
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
                                            const Icon(Icons.shopping_cart,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getChariotName(
                                                  product.chariotId!),
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
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          _showEditProductDialog(product);
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
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  // Récupérer le nom du chariot à partir de son ID
  String _getChariotName(String chariotId) {
    final chariot = _chariots.firstWhere(
      (c) => c['id'] == chariotId,
      orElse: () => {'name': 'Chariot inconnu'},
    );
    return chariot['name'];
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    // Valeur par défaut pour le chariot (premier chariot disponible)
    String? selectedChariotId = _chariots
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
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedChariotId,
                          hint: const Text('Sélectionner un chariot'),
                          items: _chariots.map((chariot) {
                            final bool isAvailable =
                                chariot['status'] == 'Disponible';
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
                      // Pour une vraie application, vous devrez implémenter un service
                      // de téléchargement d'images et utiliser l'URL retournée
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

                      // Fermer le dialogue de chargement
                      Navigator.pop(context);

                      // Fermer le dialogue d'ajout
                      Navigator.pop(context);

                      // Mettre à jour la liste des produits
                      setState(() {
                        _products.add(addedProduct);
                      });

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

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toString());
    final quantityController =
        TextEditingController(text: product.quantity.toString());
    String? selectedChariotId = product.chariotId;

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
                          items: _chariots.map((chariot) {
                            final bool isAvailable =
                                chariot['status'] == 'Disponible' ||
                                    chariot['id'] == product.chariotId;
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

                      // Créer l'objet produit mis à jour
                      final updatedProduct = Product(
                        id: product.id,
                        name: nameController.text,
                        price: price,
                        quantity: quantity,
                        imageUrl: product.imageUrl,
                        chariotId: selectedChariotId,
                      );

                      // Appel API pour mettre à jour le produit
                      final result =
                          await ProductService.updateProduct(updatedProduct);

                      // Fermer le dialogue de chargement
                      Navigator.pop(context);

                      // Fermer le dialogue de modification
                      Navigator.pop(context);

                      // Mettre à jour la liste des produits
                      setState(() {
                        final index =
                            _products.indexWhere((p) => p.id == product.id);
                        if (index != -1) {
                          _products[index] = result;
                        }
                      });

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
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Produit sans ID, message d'erreur
                  if (product.id == null) {
                    Navigator.pop(context); // Fermer le dialogue de chargement
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Impossible de supprimer: ID du produit manquant'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Appel API pour supprimer le produit
                  final success =
                      await ProductService.deleteProduct(product.id!);

                  // Fermer le dialogue de chargement
                  Navigator.pop(context);

                  if (success) {
                    // Supprimer le produit de la liste locale
                    setState(() {
                      _products.removeWhere((p) => p.id == product.id);
                    });

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
                  // Fermer le dialogue de chargement
                  Navigator.pop(context);

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
