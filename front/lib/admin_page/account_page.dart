import 'package:flutter/material.dart';
import 'package:lessvsfull/services/user_service.dart';
import 'dart:async';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  // Create instance of user service - Using 10.0.2.2 which is how Android emulators access host localhost
  final UserService _userService = UserService(baseUrl: 'http://10.0.2.2:5000');

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
          const TabBar(
            labelColor: Colors.blue, // Replace with your theme color
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
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          child: Text(account['name'].substring(0, 1)),
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
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditAccountDialog(account);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
        backgroundColor: Colors.blue, // Replace with your theme color
        onPressed: () {
          _showAddAccountDialog(type);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccountDialog(String type) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final creditController = TextEditingController(text: '0.0');
    final nfcIdController =
        TextEditingController(text: 'En attente de scan NFC...');

    // Variables pour suivre si les champs sont valides
    String? nameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? creditError;

    // Variables pour suivre l'état de validation des champs
    bool isNameValid = false;
    bool isEmailValid = false;
    bool isPasswordValid = false;
    bool isConfirmPasswordValid = false;
    bool isCreditValid = true; // Par défaut à true car c'est initialisé à 0.0

    // Variable pour suivre l'état du scan NFC
    bool isNfcScanning = true;
    bool isNfcDetected = false;

    // Variable pour suivre l'état de la soumission
    bool isSubmitting = false;

    // Variable pour contrôler la visibilité du mot de passe
    bool isPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Simuler la détection du NFC après un délai
            if (type == 'Client' && isNfcScanning) {
              Future.delayed(const Duration(seconds: 3), () {
                if (context.mounted) {
                  setState(() {
                    // Générer un code NFC hexadécimal aléatoire
                    final String nfcCode =
                        'A4:F5:${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                    nfcIdController.text = nfcCode;
                    isNfcScanning = false;
                    isNfcDetected = true;
                  });
                }
              });
            }

            // Fonctions de validation
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

            void validateCredit(String value) {
              setState(() {
                if (value.isEmpty) {
                  creditError = 'Le crédit ne peut pas être vide';
                  isCreditValid = false;
                } else {
                  final creditValue = double.tryParse(value);
                  if (creditValue == null) {
                    creditError = 'Veuillez entrer un nombre valide';
                    isCreditValid = false;
                  } else if (creditValue < 0) {
                    creditError = 'Le crédit ne peut pas être négatif';
                    isCreditValid = false;
                  } else {
                    creditError = null;
                    isCreditValid = true;
                  }
                }
              });
            }

            // Validation initiale du crédit
            validateCredit(creditController.text);

            // Fonction pour créer un utilisateur
            Future<void> createUser() async {
              if (!isNameValid ||
                  !isEmailValid ||
                  !isPasswordValid ||
                  !isConfirmPasswordValid ||
                  (type == 'Client' && !isCreditValid)) {
                return;
              }

              setState(() {
                isSubmitting = true;
              });

              try {
                final userData = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'password': passwordController.text,
                  'role': type == 'Client' ? 'client' : 'technician',
                };

                if (type == 'Client') {
                  // Conversion en nombre plutôt qu'en chaîne de caractères
                  userData['credit'] =
                      double.parse(creditController.text).toString();
                  if (isNfcDetected) {
                    userData['nfcId'] = nfcIdController.text;
                  }
                }

                await _userService.createUser(userData);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Account created successfully')),
                  );
                  _loadUsers(); // Reload users list
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating account: $e')),
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
              title: Text('Add New $type'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ajout du champ NFC ID en lecture seule avec meilleure lisibilité
                    if (type == 'Client') ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isNfcDetected ? Colors.green : Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.nfc,
                                  color: isNfcDetected
                                      ? Colors.green
                                      : Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'NFC ID',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isNfcDetected
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                                const Spacer(),
                                if (isNfcScanning)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                    ),
                                  ),
                                if (isNfcDetected)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isNfcDetected
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                nfcIdController.text,
                                style: TextStyle(
                                  fontFamily: 'Courier', // Police monospace
                                  fontSize: 18,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                  color: isNfcDetected
                                      ? Colors.green[800]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Text(
                                isNfcDetected
                                    ? 'Tag NFC détecté avec succès'
                                    : 'Scanning en cours...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isNfcDetected
                                      ? Colors.green
                                      : Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                    // Only show credit field for clients
                    if (type == 'Client') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: creditController,
                        decoration: InputDecoration(
                          labelText: 'Credit (DA)',
                          border: const OutlineInputBorder(),
                          errorText: creditError,
                          helperText: isCreditValid
                              ? 'Crédit valide'
                              : 'Entrez un nombre valide',
                          helperStyle: TextStyle(
                            color:
                                isCreditValid ? Colors.green : Colors.grey[600],
                          ),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                          suffixText: 'DA',
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          try {
                            final amount = double.parse(value);
                            if (amount >= 0) {
                              setState(() {
                                creditError = null;
                                isCreditValid = true;
                              });
                            } else {
                              setState(() {
                                creditError = 'Le montant doit être positif';
                                isCreditValid = false;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              creditError = 'Veuillez entrer un nombre valide';
                              isCreditValid = false;
                            });
                          }
                        },
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
                  onPressed: isSubmitting
                      ? null
                      : () {
                          // Validation finale avant création
                          validateName(nameController.text);
                          validateEmail(emailController.text);
                          validatePassword(passwordController.text);
                          validateConfirmPassword(
                              confirmPasswordController.text);
                          if (type == 'Client') {
                            validateCredit(creditController.text);
                          }

                          // Vérifier si tous les champs sont valides après validation finale
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty ||
                              confirmPasswordController.text.isEmpty ||
                              (type == 'Client' &&
                                  (creditError != null ||
                                      creditController.text.isEmpty))) {
                            return;
                          }

                          // Call the API to create user
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
