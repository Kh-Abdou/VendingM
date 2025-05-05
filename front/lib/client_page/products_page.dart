import 'package:flutter/material.dart';
import '../models/produit.dart';
import '../services/produit_service.dart';
import '../services/order_service.dart'; // Ajout de l'import manquant

class ProduitPanier {
  final Produit produit;
  int quantite;

  ProduitPanier({
    required this.produit,
    required this.quantite,
  });
}

class ProductsPage extends StatefulWidget {
  final List<ProduitPanier> panier;
  final double soldeUtilisateur;
  final Function(Produit) onAjouterAuPanier;
  final Function() onShowPanier;
  final bool isInMaintenance;
  final String baseUrl;

  const ProductsPage({
    Key? key,
    required this.panier,
    required this.soldeUtilisateur,
    required this.onAjouterAuPanier,
    required this.onShowPanier,
    required this.isInMaintenance,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late ProduitService _produitService;
  List<Produit> _produits = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _produitService = ProduitService(baseUrl: widget.baseUrl);
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final products = await _produitService.getProducts();

      setState(() {
        _produits = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_produits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun produit disponible',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: Icon(Icons.refresh),
              label: Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _produits.length,
        itemBuilder: (context, index) {
          return _buildProduitCard(_produits[index]);
        },
      ),
    );
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
                    child: produit.image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              produit.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.local_cafe,
                                    size: 60,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                      widget.onAjouterAuPanier(produit);
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
                  child: produit.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            produit.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.local_cafe,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
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
                        widget.onAjouterAuPanier(produit);
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
}

class GenerateCodePage extends StatefulWidget {
  final List<ProduitPanier> panier;
  final String userId;
  final String baseUrl;

  const GenerateCodePage({
    Key? key,
    required this.panier,
    required this.userId,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _GenerateCodePageState createState() => _GenerateCodePageState();
}

class _GenerateCodePageState extends State<GenerateCodePage> {
  String generatedCode = '';
  DateTime? expiryTime;
  bool isLoading = true;
  String errorMessage = '';

  // Initialisation du service de commande
  late final OrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService(baseUrl: widget.baseUrl);
    _generateCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Votre Code de Retrait'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: isLoading
              ? _buildLoadingState()
              : errorMessage.isNotEmpty
                  ? _buildErrorState()
                  : _buildCodeDisplay(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          'Génération du code en cours...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 60,
        ),
        SizedBox(height: 20),
        Text(
          'Erreur lors de la génération du code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          errorMessage,
          style: TextStyle(
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _generateCode,
          child: Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildCodeDisplay() {
    return Column(
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
                if (expiryTime != null)
                  Text(
                    'Expire le ${_formatExpiryTime(expiryTime!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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
    );
  }

  Future<void> _generateCode() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Préparer les données pour l'API
      final double totalAmount = _calculateTotal();
      final List<Map<String, dynamic>> productsData = widget.panier
          .map((item) => {
                'productId': item.produit.id,
                'quantity': item.quantite,
                'price': item.produit.prix,
              })
          .toList();

      // Appel à l'API pour générer le code
      final result = await _orderService.generateCode(
        userId: widget.userId,
        totalAmount: totalAmount,
        products: productsData,
      );

      // Mise à jour de l'état avec le code généré
      setState(() {
        generatedCode = result['code'] ?? '';
        if (result['expiryTime'] != null) {
          expiryTime = DateTime.parse(result['expiryTime']);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in widget.panier) {
      total += item.produit.prix * item.quantite;
    }
    return total;
  }

  String _formatExpiryTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
