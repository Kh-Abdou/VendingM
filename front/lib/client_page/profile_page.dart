import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Login/login_page.dart';
import '../services/user_service.dart';
import '../theme/app_design_system.dart'; // Import our design system
import 'dart:developer' as developer;

class ProfilePage extends StatefulWidget {
  final String userId; // ID de l'utilisateur connecté
  final String baseUrl; // URL de base pour les API
  final String userName;
  final String userEmail;
  final double soldeUtilisateur;
  final bool isInMaintenance;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.baseUrl,
    this.userName = '',
    this.userEmail = '',
    this.soldeUtilisateur = 0.0,
    required this.isInMaintenance,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserService _userService;
  bool _isLoading = true;
  String _errorMessage = '';

  // Données de l'utilisateur
  String _userName = '';
  String _userEmail = '';
  double _userBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _userService = UserService(baseUrl: widget.baseUrl);
    _fetchUserData();
  }

  // Récupérer les données de l'utilisateur
  Future<void> _fetchUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // Si les données sont déjà fournies, les utiliser
      if (widget.userName.isNotEmpty && widget.userEmail.isNotEmpty) {
        _userName = widget.userName;
        _userEmail = widget.userEmail;
        _userBalance = widget.soldeUtilisateur;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Sinon, récupérer les données depuis l'API
      final userDetails = await _userService.getUserDetails(widget.userId);
      final walletBalance = await _userService.getWalletBalance(widget.userId);

      if (mounted) {
        setState(() {
          _userName = userDetails['name'] ?? 'Utilisateur';
          _userEmail = userDetails['email'] ?? 'email@example.com';
          _userBalance = walletBalance;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Erreur lors de la récupération des données: $e',
          name: 'ProfilePage');
      if (mounted) {
        setState(() {
          _errorMessage = 'Impossible de récupérer les informations du profil';
          _isLoading = false;
        });
      }
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

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 60.sp),
            SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _fetchUserData,
              child: Text('Réessayer', style: AppTextStyles.buttonMedium),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 60.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  _userName,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _userEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // Account details section
          Text(
            'Informations du compte',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            elevation: AppSpacing.cardElevation,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Solde row
                  ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    title: Text('Solde', style: AppTextStyles.bodyLarge),
                    trailing: Text(
                      '${_userBalance.toStringAsFixed(2)} DA',
                      style: AppTextStyles.balanceText,
                    ),
                  ),
                  Divider(thickness: 1.h, color: AppColors.divider),

                  // Email row
                  ListTile(
                    leading: Icon(
                      Icons.email,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    title: Text('Email', style: AppTextStyles.bodyLarge),
                    subtitle: Text(_userEmail, style: AppTextStyles.bodySmall),
                  ),
                  Divider(thickness: 1.h, color: AppColors.divider),

                  // Password row (masked)
                  ListTile(
                    leading: Icon(
                      Icons.lock,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    title: Text('Mot de passe', style: AppTextStyles.bodyLarge),
                    subtitle: Text('••••••••', style: AppTextStyles.bodySmall),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, size: 22.sp),
                      onPressed: () {
                        _showChangePasswordDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // Actions section
          Text(
            'Actions',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            elevation: AppSpacing.cardElevation,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Support button
                  ListTile(
                    leading: Icon(
                      Icons.support_agent,
                      color: AppColors.info,
                      size: 24.sp,
                    ),
                    title: Text('Support', style: AppTextStyles.bodyLarge),
                    subtitle: Text('Besoin d\'aide ? Contactez-nous',
                        style: AppTextStyles.bodySmall),
                    trailing: Icon(Icons.chevron_right, size: 22.sp),
                    onTap: () {
                      _showSupportDialog();
                    },
                  ),
                  Divider(thickness: 1.h, color: AppColors.divider),

                  // Status of the distributor
                  ListTile(
                    leading: Icon(
                      widget.isInMaintenance
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color: widget.isInMaintenance
                          ? AppColors.warning
                          : AppColors.success,
                      size: 24.sp,
                    ),
                    title: Text('Statut du distributeur',
                        style: AppTextStyles.bodyLarge),
                    subtitle: Text(
                      widget.isInMaintenance ? 'En maintenance' : 'Disponible',
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: Icon(Icons.chevron_right, size: 22.sp),
                    onTap: () {
                      _showStatusDialog();
                    },
                  ),
                  Divider(thickness: 1.h, color: AppColors.divider),

                  // Logout button
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 24.sp,
                    ),
                    title:
                        Text('Se déconnecter', style: AppTextStyles.bodyLarge),
                    trailing: Icon(Icons.chevron_right, size: 22.sp),
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
    bool isUpdating = false;
    String passwordError = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Changer le mot de passe',
              style: AppTextStyles.h4,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (passwordError.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      margin: EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.chipRadius),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error,
                              color: AppColors.error, size: 18.sp),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              passwordError,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_open),
                      helperText: 'Minimum 6 caractères',
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_reset),
                    ),
                  ),
                  if (isUpdating)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.md),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUpdating
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: Text('Annuler', style: AppTextStyles.buttonMedium),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        // Validation
                        if (currentPasswordController.text.isEmpty ||
                            newPasswordController.text.isEmpty ||
                            confirmPasswordController.text.isEmpty) {
                          setState(() {
                            passwordError = 'Tous les champs sont obligatoires';
                          });
                          return;
                        }

                        if (newPasswordController.text.length < 6) {
                          setState(() {
                            passwordError =
                                'Le mot de passe doit contenir au moins 6 caractères';
                          });
                          return;
                        }

                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          setState(() {
                            passwordError =
                                'Les mots de passe ne correspondent pas';
                          });
                          return;
                        }

                        setState(() {
                          isUpdating = true;
                          passwordError = '';
                        });

                        try {
                          final success = await _userService.updatePassword(
                            userId: widget.userId,
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );

                          Navigator.of(context).pop();

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Mot de passe modifié avec succès',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Échec de la mise à jour du mot de passe',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            isUpdating = false;
                            passwordError =
                                e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                child: Text('Enregistrer', style: AppTextStyles.buttonMedium),
              ),
            ],
          );
        });
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Se déconnecter',
            style: AppTextStyles.h4,
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              child: Text('Annuler', style: AppTextStyles.buttonMedium),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Déconnecter', style: AppTextStyles.buttonMedium),
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
                color: AppColors.primary,
                size: 28.sp,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Assistance',
                style: AppTextStyles.h4,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pour toute question ou problème avec le distributeur, veuillez contacter:',
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(height: AppSpacing.md),

              // Phone number section
              Row(
                children: [
                  Icon(Icons.phone, color: AppColors.success, size: 22.sp),
                  SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Téléphone',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+213 123 456 789',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.md),

              // Email section
              Row(
                children: [
                  Icon(Icons.email, color: AppColors.info, size: 22.sp),
                  SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'support@distributeur.com',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.md),
              Text(
                'Horaires du support: 8h-18h, 7j/7',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('Fermer', style: AppTextStyles.buttonMedium),
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
          title: Text(
            'Statut du Distributeur',
            style: AppTextStyles.h4,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isInMaintenance ? Icons.warning : Icons.check_circle,
                    color: widget.isInMaintenance
                        ? AppColors.warning
                        : AppColors.success,
                    size: 24.sp,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.isInMaintenance ? 'En maintenance' : 'Disponible',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'ID Distributeur: DIS-42501',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                'Dernière mise à jour: 16/03/2025',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Fermer', style: AppTextStyles.buttonMedium),
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
