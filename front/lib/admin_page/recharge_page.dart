import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/client_service.dart';

class RechargeClientPage extends StatefulWidget {
  const RechargeClientPage({Key? key}) : super(key: key);

  @override
  _RechargeClientPageState createState() => _RechargeClientPageState();
}

class _RechargeClientPageState extends State<RechargeClientPage> {
  final ClientService _clientService = ClientService();

  List<Client> _clients = [];
  String?
      _selectedClientId; // Changed from int? to String? to match MongoDB ObjectID
  final _amountController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchClients();
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
        _isLoading = false;

        // Set default selected client if available
        if (_clients.isNotEmpty) {
          _selectedClientId = _clients.first.id;
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
          _buildCreditRechargeForm(),
          const SizedBox(height: 20),
          const Text('Client List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(child: _buildClientCreditList()),
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_clients.isEmpty)
              const Text('No clients available to recharge.')
            else
              DropdownButtonFormField<String>(
                // Changed from int to String
                decoration: const InputDecoration(
                  labelText: 'Select Client',
                  border: OutlineInputBorder(),
                ),
                value: _selectedClientId,
                items: _clients.map((client) {
                  return DropdownMenuItem<String>(
                    // Changed from int to String
                    value: client.id,
                    child: Text('${client.name} (${client.email})'),
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
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _clients.isEmpty || _isLoading ? null : _addCredit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Credit'),
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

    // Proper numeric conversion - this will fix the error
    double amount;
    try {
      amount = double.parse(_amountController.text);
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Send the amount as a number, not a string
      await _clientService.rechargeClientBalance(_selectedClientId! as String, amount);

      // Refresh client list after successful recharge
      await _fetchClients();

      // Clear form
      _amountController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credit added successfully')),
      );
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
    if (_clients.isEmpty) {
      return const Center(child: Text('No clients available'));
    }

    return ListView.builder(
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(client.name.substring(0, 1)),
            ),
            title: Text(client.name),
            subtitle: Text(client.email),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Credit: ${client.credit} DA',
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
