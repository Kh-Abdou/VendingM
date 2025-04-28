import 'package:flutter/material.dart';

class RechargeClientPage extends StatefulWidget {
  const RechargeClientPage({Key? key}) : super(key: key);

  @override
  _RechargeClientPageState createState() => _RechargeClientPageState();
}

class _RechargeClientPageState extends State<RechargeClientPage> {
  // Placeholder data for customers
  final List<Map<String, dynamic>> _customers = [
    {
      'id': 1,
      'name': 'John Doe',
      'email': 'john@example.com',
      'credit': 100.0,
      'type': 'Client'
    },
    {
      'id': 2,
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'credit': 50.0,
      'type': 'Client'
    },
    {
      'id': 3,
      'name': 'Bob Tech',
      'email': 'bob@example.com',
      'type': 'Technicien'
    }, // No credit field for technicians
  ];

  // Only store clients for recharge operations
  late List<Map<String, dynamic>> _clients;
  int _selectedClientId = 1;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Filter to include only clients
    _clients = _customers.where((c) => c['type'] == 'Client').toList();
    // Set default selected client if available
    if (_clients.isNotEmpty) {
      _selectedClientId = _clients.first['id'];
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
          _buildCreditRechargeForm(),
          const SizedBox(height: 20),
          const Text('Client List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(child: _buildClientCreditList()),
        ],
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
            if (_clients.isEmpty)
              const Text('No clients available to recharge.')
            else
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Select Client',
                  border: OutlineInputBorder(),
                ),
                value: _selectedClientId,
                items: _clients.map((client) {
                  return DropdownMenuItem<int>(
                    value: client['id'],
                    child: Text('${client['name']} (${client['email']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedClientId = value;
                    });
                  }
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
                  backgroundColor: Colors.blue, // Replace with your theme color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _clients.isEmpty ? null : _addCredit,
                child: const Text('Add Credit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCredit() {
    // Validate amount
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Find selected client and add credit
    int customerIndex =
        _customers.indexWhere((c) => c['id'] == _selectedClientId);
    if (customerIndex != -1 && _customers[customerIndex]['type'] == 'Client') {
      setState(() {
        _customers[customerIndex]['credit'] =
            (_customers[customerIndex]['credit'] as double) + amount;

        // Also update _clients reference
        int clientIndex =
            _clients.indexWhere((c) => c['id'] == _selectedClientId);
        if (clientIndex != -1) {
          _clients[clientIndex]['credit'] = _customers[customerIndex]['credit'];
        }
      });

      // Clear form
      _amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credit added successfully!')),
      );
    }
  }

  Widget _buildClientCreditList() {
    // Only show clients in the credit list
    final clientsList = _customers.where((c) => c['type'] == 'Client').toList();

    return ListView.builder(
      itemCount: clientsList.length,
      itemBuilder: (context, index) {
        final client = clientsList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(client['name'].substring(0, 1)),
            ),
            title: Text('${client['name']}'),
            subtitle: Text('${client['email']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Credit: ${client['credit']} DA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
