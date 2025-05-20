import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import flutter_screenutil
import '../models/produit.dart';
import '../services/produit_service.dart';
import '../services/order_service.dart'; // Ajout de l'import manquant
import '../theme/app_design_system.dart'; // Import our design system
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

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
    super.key,
    required this.panier,
    required this.soldeUtilisateur,
    required this.onAjouterAuPanier,
    required this.onShowPanier,
    required this.isInMaintenance,
    required this.baseUrl,
  });

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
        child: CircularProgressIndicator(
          strokeWidth: 2.w,
          color: AppColors.primary,
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 60.sp,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Erreur de chargement',
              style: AppTextStyles.h4.copyWith(color: AppColors.error),
            ),
            SizedBox(height: AppSpacing.xs),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text('Réessayer', style: AppTextStyles.buttonMedium),
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
              size: 60.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Aucun produit disponible',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text('Actualiser', style: AppTextStyles.buttonMedium),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: AppColors.primary,
      child: AnimationLimiter(
        child: GridView.builder(
          padding: EdgeInsets.all(AppSpacing.sm),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: _produits.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _buildProduitCard(_produits[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProduitCard(Produit produit) {
    return Card(
      elevation: AppSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: InkWell(
        onTap: produit.disponible ? () => _showProduitDetails(produit) : null,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: EdgeInsets.all(6.w), // Réduit le padding général
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Force la colonne à prendre le minimum d'espace
            children: [
              Stack(
                children: [
                  Container(
                    height: 120.h, // Réduit légèrement la hauteur de l'image
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors
                          .background, // Replace with an existing color property
                      borderRadius: BorderRadius.circular(AppSpacing
                          .cardRadius), // Replace with an existing property
                    ),
                    child: produit.image.isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.network(
                                _getFullImageUrl(produit.image),
                                fit: BoxFit.cover,
                                height: 100.h,
                                width: 100.w,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return Center(
                                    child: Icon(
                                      Icons.local_cafe,
                                      size: 60.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.local_cafe,
                              size: 60.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                  if (!produit.disponible)
                    Container(
                      height: 130.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.5),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.imageRadius),
                      ),
                      child: Center(
                        child: Text(
                          'INDISPONIBLE',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.surfaceLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4.h), // Réduit l'espace
              Text(
                produit.nom,
                style: AppTextStyles.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h), // Réduit l'espace
              Text(
                '${produit.prix.toStringAsFixed(2)} DA',
                style: AppTextStyles.priceText,
              ),
              SizedBox(height: 4.h), // Réduit l'espace avant le bouton
              if (produit.disponible)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h), // Réduit le padding du bouton
                      minimumSize: Size(0, 28.h), // Réduit la hauteur minimale du bouton
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    onPressed: () => widget.onAjouterAuPanier(produit),
                    child: Text(
                      'Ajouter',
                      style: AppTextStyles.buttonMedium.copyWith(fontSize: 11.sp),
                    ),
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
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(
                AppSpacing.cardRadius)), // Replaced with an existing property
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 180.h,
                  width: 180.w,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.imageRadius),
                  ),
                  child: produit.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.imageRadius),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Image.network(
                              _getFullImageUrl(produit.image),
                              height: 160.h,
                              width: 160.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading detail image: $error');
                                return Center(
                                  child: Icon(
                                    Icons.local_cafe,
                                    size: 80.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.local_cafe,
                            size: 80.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                produit.nom,
                style: AppTextStyles.h3,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Prix: ${produit.prix.toStringAsFixed(2)} DA',
                style: AppTextStyles.priceText,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                      child: Text(
                        'Ajouter au panier',
                        style: AppTextStyles.buttonLarge,
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

  // Helper method to construct full image URL
  String _getFullImageUrl(String imagePath) {
    // Already a full URL
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Handle server path that starts with 'uploads/'
    if (imagePath.startsWith('uploads/')) {
      return '${widget.baseUrl}/${imagePath}';
    }

    // Default case, just append to base URL
    return '${widget.baseUrl}/${imagePath}';
  }
}

class GenerateCodePage extends StatefulWidget {
  final List<ProduitPanier> panier;
  final String userId;
  final String baseUrl;

  const GenerateCodePage({
    super.key,
    required this.panier,
    required this.userId,
    required this.baseUrl,
  });

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
        title: Text('Votre Code de Retrait', style: AppTextStyles.h4),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
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
        CircularProgressIndicator(
          strokeWidth: 2.w,
          color: AppColors.primary,
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Génération du code en cours...',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
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
          color: AppColors.error,
          size: 60.sp,
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Erreur lors de la génération du code',
          style: AppTextStyles.h4.copyWith(color: AppColors.error),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          errorMessage,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: _generateCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
          child: Text('Réessayer', style: AppTextStyles.buttonMedium),
        ),
      ],
    );
  }

  Widget _buildCodeDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          elevation: AppSpacing.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 60.sp,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Code Généré',
                  style: AppTextStyles.h3.copyWith(color: AppColors.success),
                ),
                SizedBox(height: AppSpacing.xl),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.codeRadius),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.w,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        generatedCode,
                        style: AppTextStyles.code.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 8.w,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Icon(
                        Icons.qr_code_2,
                        size: 120.sp,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Code valable pendant 5 minutes',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (expiryTime != null)
                  Text(
                    'Expire le ${_formatExpiryTime(expiryTime!)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        Text(
          'Présentez ce code sur l\'écran du distributeur',
          style:
              AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
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
