import 'package:flutter/material.dart';
import 'package:lessvsfull/services/user_service.dart';
import 'package:lessvsfull/theme/app_colors.dart';
import 'dart:async';
import '../main.dart' show apiBaseUrl;

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  // Create instance of user service
  final UserService _userService = UserService(baseUrl: apiBaseUrl);

  // Lists to store user data
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _technicians = [];

  // Loading state
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Load users from API
  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get clients and technicians using the correct methods
      final clients = await _userService.getClients();
      final technicians = await _userService.getTechnicians();

      // Process clients with wallet data
      final List<Map<String, dynamic>> processedClients = [];
      for (var client in clients) {
        final formattedClient = await _formatUserData(client, 'Client');
        processedClients.add(formattedClient);
      }

      // Process technicians
      final List<Map<String, dynamic>> processedTechnicians = [];
      for (var tech in technicians) {
        final formattedTech = await _formatUserData(tech, 'Technicien');
        processedTechnicians.add(formattedTech);
      }

      if (mounted) {
        setState(() {
          _clients = processedClients;
          _technicians = processedTechnicians;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading users: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Format API user data to match our UI format
  Future<Map<String, dynamic>> _formatUserData(
      dynamic user, String type) async {
    double credit = 0.0;
    if (type == 'Client') {
      try {
        final walletResponse = await _userService.getWalletBalance(user['_id']);
        if (walletResponse > 0) {
          // Changed from null check to value check
          credit = walletResponse;
        }
      } catch (e) {
        print('Error fetching wallet balance for user ${user['_id']}: $e');
      }
    }

    return {
      'id': user['_id'],
      'name': user['name'],
      'email': user['email'],
      'type': type,
      'credit': type == 'Client' ? credit : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Clients'),
              Tab(text: 'Techniciens'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAccountsList('Client'),
                _buildAccountsList('Technicien'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(String type) {
    final filteredAccounts = type == 'Client' ? _clients : _technicians;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: filteredAccounts.isEmpty
            ? Center(child: Text('No ${type.toLowerCase()}s found'))
            : ListView.builder(
                itemCount: filteredAccounts.length,
                padding: const EdgeInsets.all(8.0),
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.border.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            account['name'].substring(0, 1),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('${account['name']}'),
                        subtitle: type == 'Client'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(account['email']),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.account_balance_wallet,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${account['credit']?.toStringAsFixed(2) ?? '0.00'} DA',
                                        style: TextStyle(
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Text(account['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () {
                                _showEditAccountDialog(account);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: AppColors.error),
                              onPressed: () {
                                _showDeleteConfirmationDialog(account);
                              },
                            ),
                          ],
                        ),
                      ));
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () {
          _showAddAccountDialog(type);
        },
        child: const Icon(Icons.add),
        elevation: 4,
      ),
    );
  }

  void _showAddAccountDialog(String type) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final creditController = TextEditingController(text: '0.0');
    final rfidIdController = TextEditingController(text: '');
    final rfidPinController = TextEditingController();

    // Variables pour suivre si les champs sont valides
    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? rfidPinError;

    // Variables pour suivre l'état de validation des champs
    bool isNameValid = false;
    bool isEmailValid = false;
    bool isPasswordValid = false;
    bool isConfirmPasswordValid = false;
    bool isRfidPinValid = false;

    // Variable pour suivre l'état du scan RFID
    bool isRfidScanning = false; // Only true when scan button pressed
    bool isRfidDetected = false;

    // Variable pour suivre l'état de la soumission
    bool isSubmitting = false;

    // Variable pour contrôler la visibilité du mot de passe
    bool isPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    Future<void> scanRfidCard(StateSetter setState, String name, String email,
        String password, String type) async {
      setState(() {
        isRfidScanning = true;
        isRfidDetected = false;
        rfidIdController.text = '';
      });
      try {
        await _userService.initRfidRegistration(
          name: name,
          email: email,
          password: password,
          type: type,
        );
        bool registrationComplete = false;
        while (!registrationComplete) {
          await Future.delayed(const Duration(seconds: 2));
          try {
            final response = await _userService.checkPendingRfidRegistration();
            if (response.containsKey('registeredUID')) {
              setState(() {
                rfidIdController.text = response['registeredUID'];
                isRfidScanning = false;
                isRfidDetected = true;
              });
              registrationComplete = true;
              break;
            }
          } catch (_) {}
        }
      } catch (e) {
        setState(() {
          isRfidScanning = false;
          isRfidDetected = false;
          rfidIdController.text = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('RFID scan failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }

    Future<void> createUser() async {
      if (!isNameValid ||
          !isEmailValid ||
          !isPasswordValid ||
          !isConfirmPasswordValid) {
        return;
      }
      setState(() {
        isSubmitting = true;
      });
      try {
        await _userService.registerUser(
          name: nameController.text,
          email: emailController.text,
          password: passwordController.text,
          type: type,
          rfidUID: (isRfidDetected && rfidIdController.text.isNotEmpty)
              ? rfidIdController.text
              : null,
          credit: double.tryParse(creditController.text) ?? 0.0,
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully')),
          );
          _loadUsers();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error creating account: $e'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          isSubmitting = false;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Fonctions de validation
            void validateRfidPin(String value) {
              setState(() {
                if (value.isEmpty) {
                  rfidPinError = 'Le code PIN est requis';
                  isRfidPinValid = false;
                } else if (value.length != 4) {
                  rfidPinError = 'Le code PIN doit contenir 4 chiffres';
                  isRfidPinValid = false;
                } else if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) {
                  rfidPinError = 'Le code PIN doit être composé de 4 chiffres';
                  isRfidPinValid = false;
                } else {
                  rfidPinError = null;
                  isRfidPinValid = true;
                }
              });
            }

            void validateName(String value) {
              setState(() {
                if (value.isEmpty) {
                  nameError = 'Le nom ne peut pas être vide';
                  isNameValid = false;
                } else if (value.length < 2) {
                  nameError = 'Le nom doit contenir au moins 2 caractères';
                  isNameValid = false;
                } else {
                  nameError = null;
                  isNameValid = true;
                }
              });
            }

            void validateEmail(String value) {
              setState(() {
                if (value.isEmpty) {
                  emailError = 'L\'email ne peut pas être vide';
                  isEmailValid = false;
                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  emailError = 'Veuillez entrer un email valide';
                  isEmailValid = false;
                } else {
                  emailError = null;
                  isEmailValid = true;
                }
              });
            }

            void validateConfirmPassword(String value) {
              setState(() {
                if (value.isEmpty) {
                  confirmPasswordError = 'Veuillez confirmer le mot de passe';
                  isConfirmPasswordValid = false;
                } else if (value != passwordController.text) {
                  confirmPasswordError =
                      'Les mots de passe ne correspondent pas';
                  isConfirmPasswordValid = false;
                } else {
                  confirmPasswordError = null;
                  isConfirmPasswordValid = true;
                }
              });
            }

            void validatePassword(String value) {
              setState(() {
                if (value.isEmpty) {
                  passwordError = 'Le mot de passe ne peut pas être vide';
                  isPasswordValid = false;
                } else if (value.length < 6) {
                  passwordError =
                      'Le mot de passe doit contenir au moins 6 caractères';
                  isPasswordValid = false;
                } else {
                  passwordError = null;
                  isPasswordValid = true;
                }

                // Valider la confirmation si elle n'est pas vide
                if (confirmPasswordController.text.isNotEmpty) {
                  validateConfirmPassword(confirmPasswordController.text);
                }
              });
            }

            // Fonction pour créer un utilisateur
            Future<void> createUser() async {
              if (!isNameValid ||
                  !isEmailValid ||
                  !isPasswordValid ||
                  !isConfirmPasswordValid) {
                return;
              }

              setState(() {
                isSubmitting = true;
              });

              try {
                await _userService.registerUser(
                  name: nameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  type: type,
                  rfidUID: (isRfidDetected && rfidIdController.text.isNotEmpty)
                      ? rfidIdController.text
                      : null,
                  credit: double.tryParse(creditController.text) ?? 0.0,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account created successfully'),
                    ),
                  );
                  _loadUsers(); // Reload users list
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating account: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: Text('Add New $type'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // RFID Card section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isRfidDetected ? Colors.green : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        color: Colors.grey[50],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.contactless,
                                    color: isRfidDetected
                                        ? Colors.green
                                        : Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'RFID Card (Optional)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isRfidDetected
                                          ? Colors.green
                                          : Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              if (isRfidDetected)
                                Chip(
                                  backgroundColor:
                                      Colors.green.withOpacity(0.1),
                                  side: const BorderSide(color: Colors.green),
                                  avatar: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Registered',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRfidDetected
                                  ? Colors.green.withOpacity(0.1)
                                  : isRfidScanning
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isRfidDetected
                                    ? Colors.green
                                    : isRfidScanning
                                        ? Colors.blue
                                        : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isRfidDetected
                                          ? Icons.check_circle
                                          : isRfidScanning
                                              ? Icons.pending
                                              : Icons.info_outline,
                                      color: isRfidDetected
                                          ? Colors.green
                                          : isRfidScanning
                                              ? Colors.blue
                                              : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isRfidDetected
                                          ? 'Card Registered'
                                          : isRfidScanning
                                              ? 'Waiting for Card...'
                                              : 'No Card Scanned',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isRfidDetected
                                            ? Colors.green
                                            : isRfidScanning
                                                ? Colors.blue
                                                : Colors.grey[700],
                                      ),
                                    ),
                                    if (isRfidScanning)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (isRfidDetected)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      rfidIdController.text,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto Mono',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: isRfidScanning || isRfidDetected
                                  ? null
                                  : () {
                                      validateName(nameController.text);
                                      validateEmail(emailController.text);
                                      validatePassword(passwordController.text);
                                      validateConfirmPassword(
                                          confirmPasswordController.text);
                                      if (!isNameValid ||
                                          !isEmailValid ||
                                          !isPasswordValid ||
                                          !isConfirmPasswordValid) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please fill all required fields correctly before scanning'),
                                            backgroundColor: AppColors.warning,
                                          ),
                                        );
                                        return;
                                      }
                                      scanRfidCard(
                                          setState,
                                          nameController.text,
                                          emailController.text,
                                          passwordController.text,
                                          type);
                                    },
                              icon: isRfidScanning
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.contactless),
                              label: Text(
                                isRfidDetected
                                    ? 'Card Registered'
                                    : isRfidScanning
                                        ? 'Scanning...'
                                        : 'Scan RFID Card',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isRfidDetected ? Colors.green : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          if (!isRfidDetected && !isRfidScanning)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Center(
                                child: Text(
                                  'RFID card is optional. You can create the account without it.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Champ pour le code PIN de la carte RFID
                    TextField(
                      controller: rfidPinController,
                      decoration: InputDecoration(
                        labelText: 'Code PIN RFID (4 chiffres)',
                        border: const OutlineInputBorder(),
                        errorText: rfidPinError,
                        helperText: isRfidPinValid
                            ? 'Code PIN valide'
                            : 'Entrez un code PIN à 4 chiffres',
                        helperStyle: TextStyle(
                          color:
                              isRfidPinValid ? Colors.green : Colors.grey[600],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isRfidPinValid ? Colors.green : Colors.grey,
                            width: isRfidPinValid ? 2.0 : 1.0,
                          ),
                        ),
                        prefixIcon: const Icon(Icons.pin),
                        suffixIcon: isRfidPinValid
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      onChanged: validateRfidPin,
                    ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: const OutlineInputBorder(),
                        errorText: nameError,
                        helperText: isNameValid
                            ? 'Nom valide'
                            : 'Entrez le nom complet',
                        helperStyle: TextStyle(
                          color: isNameValid ? Colors.green : Colors.grey[600],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isNameValid ? Colors.green : Colors.grey,
                            width: isNameValid ? 2.0 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isNameValid ? Colors.green : Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: isNameValid
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                      onChanged: validateName,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        errorText: emailError,
                        helperText: isEmailValid
                            ? 'Email valide'
                            : 'Entrez une adresse email valide',
                        helperStyle: TextStyle(
                          color: isEmailValid ? Colors.green : Colors.grey[600],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isEmailValid ? Colors.green : Colors.grey,
                            width: isEmailValid ? 2.0 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isEmailValid ? Colors.green : Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: isEmailValid
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    // Ajout du champ mot de passe
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const OutlineInputBorder(),
                        errorText: passwordError,
                        helperText: isPasswordValid
                            ? 'Mot de passe valide'
                            : 'Minimum 6 caractères',
                        helperStyle: TextStyle(
                          color:
                              isPasswordValid ? Colors.green : Colors.grey[600],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isPasswordValid ? Colors.green : Colors.grey,
                            width: isPasswordValid ? 2.0 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isPasswordValid ? Colors.green : Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            if (isPasswordValid)
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                          ],
                        ),
                      ),
                      onChanged: validatePassword,
                    ),
                    const SizedBox(height: 16),
                    // Ajout du champ de confirmation de mot de passe
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        border: const OutlineInputBorder(),
                        errorText: confirmPasswordError,
                        helperText: isConfirmPasswordValid
                            ? 'Les mots de passe correspondent'
                            : 'Doit correspondre au mot de passe',
                        helperStyle: TextStyle(
                          color: isConfirmPasswordValid
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isConfirmPasswordValid
                                ? Colors.green
                                : Colors.grey,
                            width: isConfirmPasswordValid ? 2.0 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isConfirmPasswordValid
                                ? Colors.green
                                : Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  isConfirmPasswordVisible =
                                      !isConfirmPasswordVisible;
                                });
                              },
                            ),
                            if (isConfirmPasswordValid)
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                          ],
                        ),
                      ),
                      onChanged: validateConfirmPassword,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          validateName(nameController.text);
                          validateEmail(emailController.text);
                          validatePassword(passwordController.text);
                          validateConfirmPassword(
                              confirmPasswordController.text);
                          validateRfidPin(rfidPinController.text);
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty ||
                              rfidPinController.text.isEmpty) {
                            return;
                          }
                          createUser();
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAccountDialog(Map<String, dynamic> account) {
    final nameController = TextEditingController(text: account['name']);
    final emailController = TextEditingController(text: account['email']);
    final creditController = account['type'] == 'Client'
        ? TextEditingController(
            text: account['credit']?.toStringAsFixed(2) ?? '0.00')
        : null;

    bool isSubmitting = false;
    bool isNameValid = true;
    bool isEmailValid = true;
    bool isCreditValid = true;
    String? nameError;
    String? emailError;
    String? creditError;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void validateName(String value) {
              if (value.isEmpty) {
                setState(() {
                  nameError = 'Name is required';
                  isNameValid = false;
                });
              } else {
                setState(() {
                  nameError = null;
                  isNameValid = true;
                });
              }
            }

            void validateEmail(String value) {
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                setState(() {
                  emailError = 'Enter a valid email address';
                  isEmailValid = false;
                });
              } else {
                setState(() {
                  emailError = null;
                  isEmailValid = true;
                });
              }
            }

            void validateCredit(String value) {
              if (value.isEmpty) {
                setState(() {
                  creditError = 'Le montant est requis';
                  isCreditValid = false;
                });
                return;
              }

              try {
                final amount = double.parse(value);
                if (amount < 0) {
                  setState(() {
                    creditError = 'Le montant doit être positif';
                    isCreditValid = false;
                  });
                } else {
                  setState(() {
                    creditError = null;
                    isCreditValid = true;
                  });
                }
              } catch (e) {
                setState(() {
                  creditError = 'Veuillez entrer un nombre valide';
                  isCreditValid = false;
                });
              }
            }

            Future<void> updateAccount() async {
              // Validate all fields first
              validateName(nameController.text);
              validateEmail(emailController.text);
              if (account['type'] == 'Client' && creditController != null) {
                validateCredit(creditController.text);
              }

              if (!isNameValid ||
                  !isEmailValid ||
                  (account['type'] == 'Client' && !isCreditValid)) {
                return;
              }

              setState(() {
                isSubmitting = true;
              });

              try {
                final Map<String, dynamic> userData = {
                  'name': nameController.text,
                  'email': emailController.text,
                };

                if (account['type'] == 'Client' && creditController != null) {
                  userData['credit'] =
                      double.parse(creditController.text).toString();
                }

                await _userService.updateUser(account['id'], userData);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Account updated successfully')),
                  );
                  _loadUsers(); // Reload users list
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating account: $e')),
                  );
                }
              } finally {
                if (context.mounted) {
                  setState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Edit Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: const OutlineInputBorder(),
                        errorText: nameError,
                        helperText: isNameValid
                            ? 'Name is valid'
                            : 'Enter a valid name',
                      ),
                      onChanged: validateName,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        errorText: emailError,
                        helperText: isEmailValid
                            ? 'Email is valid'
                            : 'Enter a valid email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: validateEmail,
                    ),
                    if (account['type'] == 'Client' &&
                        creditController != null) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: creditController,
                        decoration: InputDecoration(
                          labelText: 'Credit (DA)',
                          border: const OutlineInputBorder(),
                          errorText: creditError,
                          helperText: isCreditValid
                              ? 'Credit valide'
                              : 'Entrez un nombre valide',
                          helperStyle: TextStyle(
                            color:
                                isCreditValid ? Colors.green : Colors.grey[600],
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isCreditValid ? Colors.green : Colors.grey,
                              width: isCreditValid ? 2.0 : 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isCreditValid ? Colors.green : Colors.blue,
                              width: 2.0,
                            ),
                          ),
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('DA  ',
                                  style: TextStyle(color: Colors.grey[600])),
                              if (isCreditValid)
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                            ],
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: validateCredit,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : updateAccount,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> account) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(
                'Are you sure you want to delete ${account['name']}\'s account?'),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() {
                          isDeleting = true;
                        });

                        try {
                          // Call the API to delete the user
                          await _userService.deleteUser(account['id']);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Account deleted successfully')),
                            );

                            // Reload the user list
                            _loadUsers();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error deleting account: $e')),
                            );
                          }
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          );
        });
      },
    );
  }
}
