import 'package:flutter/material.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({Key? key}) : super(key: key);

  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  // Placeholder data for customers - update technicians to have no credit
  final List<Map<String, dynamic>> _customers = [
    {
      'id': 1,
      'name': 'John Doe',
      'email': 'john@example.com',
      'credit': 1000.0,
      'type': 'Client'
    },
    {
      'id': 2,
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'credit': 500.0,
      'type': 'Client'
    },
    {
      'id': 3,
      'name': 'Bob Tech',
      'email': 'bob@example.com',
      'type': 'Technicien'
    },
  ];

  @override
  Widget build(BuildContext context) {
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
    final filteredAccounts =
        _customers.where((c) => c['type'] == type).toList();

    return Scaffold(
      body: ListView.builder(
        itemCount: filteredAccounts.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final account = filteredAccounts[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Text(account['name'].substring(0, 1)),
              ),
              title: Text('${account['name']}'),
              subtitle: Text(type == 'Client'
                  ? '${account['email']} - Credit: ${account['credit']} DA'
                  : account['email']),
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
            ),
          );
        },
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
    final creditController = TextEditingController(text: '0.0');
    final nfcIdController =
        TextEditingController(text: 'En attente de scan NFC...');

    // Variables pour suivre si les champs sont valides
    String? nameError;
    String? emailError;
    String? creditError;

    // Variables pour suivre l'état de validation des champs
    bool isNameValid = false;
    bool isEmailValid = false;
    bool isCreditValid = true; // Par défaut à true car c'est initialisé à 0.0

    // Variable pour suivre l'état du scan NFC
    bool isNfcScanning = true;
    bool isNfcDetected = false;

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
                                  SizedBox(
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
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (nameError != null ||
                          emailError != null ||
                          (type == 'Client' && creditError != null))
                      ? null // Disable the button if any field is invalid
                      : () {
                          // Validation finale avant création
                          validateName(nameController.text);
                          validateEmail(emailController.text);
                          if (type == 'Client')
                            validateCredit(creditController.text);

                          // Vérifier si tous les champs sont valides après validation finale
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              (type == 'Client' &&
                                  (creditError != null ||
                                      creditController.text.isEmpty))) {
                            return;
                          }

                          // Implement add account logic
                          setState(() {
                            final Map<String, dynamic> newAccount = {
                              'id': _customers.length + 1,
                              'name': nameController.text,
                              'email': emailController.text,
                              'type': type,
                            };

                            // Only add credit for clients
                            if (type == 'Client') {
                              newAccount['credit'] =
                                  double.tryParse(creditController.text) ?? 0.0;
                            }

                            _customers.add(newAccount);
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Account created successfully')),
                          );
                        },
                  child: const Text('Create'),
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
        ? TextEditingController(text: account['credit'].toString())
        : null;

    // Variables pour suivre si les champs sont valides
    String? nameError;
    String? emailError;
    String? creditError;

    // Variables pour suivre l'état de validation des champs
    bool isNameValid =
        true; // Supposons que les valeurs existantes sont valides
    bool isEmailValid = true;
    bool isCreditValid = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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

            // Validation initiale
            validateName(nameController.text);
            validateEmail(emailController.text);
            if (account['type'] == 'Client') {
              validateCredit(creditController!.text);
            }

            return AlertDialog(
              title: const Text('Edit Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    // Only show credit field for clients
                    if (account['type'] == 'Client') ...[
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
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (nameError != null ||
                          emailError != null ||
                          (account['type'] == 'Client' && creditError != null))
                      ? null // Disable the button if any field is invalid
                      : () {
                          // Implement update account logic
                          setState(() {
                            final index = _customers
                                .indexWhere((c) => c['id'] == account['id']);
                            if (index != -1) {
                              final Map<String, dynamic> updatedAccount = {
                                'id': account['id'],
                                'name': nameController.text,
                                'email': emailController.text,
                                'type': account['type'],
                              };

                              // Only update credit for clients
                              if (account['type'] == 'Client') {
                                updatedAccount['credit'] =
                                    double.tryParse(creditController!.text) ??
                                        0.0;
                              }

                              _customers[index] = updatedAccount;
                            }
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Account updated successfully')),
                          );
                        },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete ${account['name']}\'s account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Implement delete account logic
                setState(() {
                  _customers.removeWhere((c) => c['id'] == account['id']);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
