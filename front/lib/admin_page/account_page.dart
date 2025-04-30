import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({Key? key}) : super(key: key);

  @override
  _AccountManagementPageState createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  final String baseUrl =
      'http://192.168.56.1:5000'; // Change to your backend URL
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get all users with 'client' role
      final response = await http.get(
        Uri.parse('$baseUrl/user/clients'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> clientsData = json.decode(response.body);

        // For each client, get their wallet balance
        final List<Map<String, dynamic>> clientsWithBalance = [];

        for (var client in clientsData) {
          final walletResponse = await http.get(
            Uri.parse('$baseUrl/ewallet/${client['_id']}'),
            headers: {'Content-Type': 'application/json'},
          );

          if (walletResponse.statusCode == 200) {
            final walletData = json.decode(walletResponse.body);
            client['balance'] = walletData['balance'] ?? 0;
          } else {
            client['balance'] = 0;
          }

          clientsWithBalance.add(client as Map<String, dynamic>);
        }

        setState(() {
          _clients = clientsWithBalance;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load clients');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _addFunds(String userId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ewallet/add-funds'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        // Update was successful, refresh the client list
        _fetchClients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Balance updated successfully')),
        );
      } else {
        throw Exception('Failed to update balance');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  void _showAddFundsDialog(Map<String, dynamic> client) {
    final amountController = TextEditingController();
    bool isAmountValid = false;
    String? amountError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void validateAmount(String value) {
              setState(() {
                if (value.isEmpty) {
                  amountError = 'Le montant ne peut pas être vide';
                  isAmountValid = false;
                } else {
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    amountError = 'Veuillez entrer un nombre valide';
                    isAmountValid = false;
                  } else if (amount <= 0) {
                    amountError = 'Le montant doit être supérieur à 0';
                    isAmountValid = false;
                  } else {
                    amountError = null;
                    isAmountValid = true;
                  }
                }
              });
            }

            return AlertDialog(
              title: Text('Ajouter des fonds'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client: ${client['name']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Solde actuel: ${client['balance']} DA',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Montant à ajouter (DA)',
                      border: OutlineInputBorder(),
                      errorText: amountError,
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      suffixText: 'DA',
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onChanged: validateAmount,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isAmountValid
                      ? () {
                          final amount = double.parse(amountController.text);
                          Navigator.pop(context);
                          _addFunds(client['_id'], amount);
                        }
                      : null,
                  child: Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $_errorMessage'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchClients,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Clients'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchClients,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _clients.isEmpty
          ? Center(child: Text('Aucun client trouvé'))
          : ListView.builder(
              itemCount: _clients.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final client = _clients[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: Text(client['name'].substring(0, 1)),
                    ),
                    title: Text('${client['name']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${client['email']}'),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Solde: ${client['balance']} DA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Ajouter des fonds'),
                      onPressed: () => _showAddFundsDialog(client),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
