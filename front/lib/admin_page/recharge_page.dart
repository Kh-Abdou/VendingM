import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/client_service.dart';

class RechargeClientPage extends StatefulWidget {
  const RechargeClientPage({super.key});

  @override
  _RechargeClientPageState createState() => _RechargeClientPageState();
}

class _RechargeClientPageState extends State<RechargeClientPage> {
  final ClientService _clientService = ClientService();

  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  String? _selectedClientId;
  final _amountController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _successMessageVisible = false;
  String _successMessage = '';
  double _successAmount = 0;
  String _successClientName = '';

  // Credit balance limit constant
  static const double _maxCreditLimit = 5000.0;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.removeListener(_filterClients);
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients
            .where((client) => client.name.toLowerCase().contains(searchTerm))
            .toList();
      }
    });
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final clients = await _clientService.getClients();
      setState(() {
        // Change this line - use role instead of type and lowercase 'client'
        _clients = clients.where((client) => client.role == 'client').toList();
        _filteredClients = _clients;
        _isLoading = false;

        // Only reset selected client if it doesn't exist in the new list
        if (_selectedClientId != null) {
          final stillExists =
              _clients.any((client) => client.id == _selectedClientId);
          if (!stillExists) {
            _selectedClientId = null;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load clients: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recharge Client Credit',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          // Success message card
          if (_successMessageVisible) _buildSuccessCard(),
          _buildCreditRechargeForm(),
          const SizedBox(height: 20),
          const Text('Client List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Search field for clients
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(child: _buildClientCreditList()),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Transaction Successful',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _successMessageVisible = false;
                    });
                  },
                )
              ],
            ),
            const Divider(color: Colors.green),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.green.shade900, fontSize: 16),
                children: [
                  const TextSpan(text: 'Added '),
                  TextSpan(
                    text: '$_successAmount DA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' to '),
                  TextSpan(
                    text: _successClientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '\'s account'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _successMessage,
              style: TextStyle(color: Colors.green.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditRechargeForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Credit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_clients.isEmpty)
              const Text('No clients available to recharge.')
            else if (_selectedClientId != null)
              Builder(
                builder: (context) {
                  final selectedClient = _clients
                      .firstWhere((client) => client.id == _selectedClientId);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected client: ${selectedClient.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(
                              text: 'Current balance: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${selectedClient.credit.toStringAsFixed(2)} DA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'DZD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed:
                    _clients.isEmpty || _isLoading || _selectedClientId == null
                        ? null
                        : _addCredit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Credit', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCredit() async {
    // Validate form
    if (_selectedClientId == null) {
      setState(() {
        _errorMessage = 'Please select a client';
      });
      return;
    }

    if (_amountController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an amount';
      });
      return;
    }

    // Proper numeric conversion
    double amount;
    try {
      amount = double.parse(_amountController.text);
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
      });
      return;
    }

    // Check for zero amount
    if (amount <= 0) {
      setState(() {
        _errorMessage = 'Amount must be greater than 0';
      });
      return;
    }

    // Get the selected client to check their current balance
    final selectedClient = _clients.firstWhere(
      (client) => client.id == _selectedClientId,
      orElse: () => throw Exception('Selected client not found'),
    );

    // Check if adding this amount would exceed the credit limit
    if (selectedClient.credit + amount > _maxCreditLimit) {
      setState(() {
        _errorMessage =
            'Cannot exceed the maximum balance of $_maxCreditLimit DA. Current balance: ${selectedClient.credit} DA';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Hide any previous success message while processing
      _successMessageVisible = false;
    });

    try {
      // Send the amount as a number, not a string
      await _clientService.rechargeClientBalance(_selectedClientId!, amount);

      // Refresh client list after successful recharge
      await _fetchClients();

      // Clear form
      _amountController.clear();

      // Show custom success message
      setState(() {
        _successAmount = amount;
        _successClientName = selectedClient.name;
        _successMessage =
            'Transaction completed at ${DateTime.now().toString().substring(0, 16)}';
        _successMessageVisible = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add credit: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildClientCreditList() {
    if (_filteredClients.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return const Center(child: Text('No clients match your search'));
      }
      return const Center(child: Text('No clients available'));
    }

    return ListView.builder(
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        final isSelected = client.id == _selectedClientId;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.blue : Colors.grey.shade700,
              child: Text(
                client.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(client.name),
            subtitle: Text(client.email),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Credit: ${client.credit.toStringAsFixed(2)} DA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Available: ${(_maxCreditLimit - client.credit).toStringAsFixed(2)} DA',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedClientId = client.id;
              });
            },
          ),
        );
      },
    );
  }
}
