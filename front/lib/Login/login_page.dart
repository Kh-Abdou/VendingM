import 'package:flutter/material.dart';
import 'package:lessvsfull/Login/inscription.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_design_system.dart'; // Import our design system
import '../admin_page/admin_page.dart';
import '../main.dart';
import '../technician_page/technician_home.dart';
import '../implementation/login-imp.dart';
import '../providers/user_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Card(
                  elevation: AppSpacing.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: AppSpacing.md),
                        Icon(
                          Icons.local_cafe,
                          size: 80.sp,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Connectez-vous',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        if (_errorMessage != null)
                          Container(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            margin: EdgeInsets.only(bottom: AppSpacing.md),
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
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Adresse Email',
                            prefixIcon: const Icon(Icons.email),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              _showForgotPasswordDialog();
                            },
                            child: Text(
                              'Mot de passe oublié?',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                      color: AppColors.textOnPrimary,
                                      strokeWidth: 2.w,
                                    ))
                                : Text(
                                    'Se connecter',
                                    style: AppTextStyles.buttonLarge,
                                  ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous n'avez pas de compte?",
                              style: AppTextStyles.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InscriptionPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'S\'inscrire',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Call the backend login API
      final authService = AuthService();
      final response = await authService.login(email, password);

      // Debugging: Print the response
      print("Login response: $response");

      // Store user info in the UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUserInfo(
        userId: response['user']['_id'],
        name: response['user']['name'],
        email: response['user']['email'],
        role: response['user']['role'].toLowerCase(),
      );

      // Handle successful login
      final role =
          response['user']['role'].toLowerCase(); // Normalize to lowercase
      print("User role: $role"); // Debugging: Print the role

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomePage()),
        );
      } else if (role == 'technician') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TechnicianHomePage()),
        );
      } else if (role == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      // Handle login failure
      setState(() {
        _errorMessage = 'Échec de la connexion : ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Réinitialisation du mot de passe',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Veuillez entrer votre adresse email pour recevoir un lien de réinitialisation de mot de passe.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.md),
                    if (errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        margin: EdgeInsets.only(bottom: AppSpacing.md),
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
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Adresse Email',
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text('Annuler', style: AppTextStyles.buttonMedium),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();

                          // Basic validation
                          if (email.isEmpty) {
                            setState(() {
                              errorMessage =
                                  'Veuillez entrer votre adresse email';
                            });
                            return;
                          }

                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(email)) {
                            setState(() {
                              errorMessage = 'Adresse email invalide';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          // Simulate API call delay
                          await Future.delayed(const Duration(seconds: 2));

                          // Close the dialog
                          Navigator.pop(context);

                          // Show a snackbar with the result
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Un lien de réinitialisation a été envoyé à $email si ce compte existe.',
                                style: AppTextStyles.bodyMedium,
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                  child: isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: AppColors.textOnPrimary,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Text('Envoyer', style: AppTextStyles.buttonMedium),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
