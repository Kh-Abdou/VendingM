import 'package:flutter/material.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // Add filter state
  String _currentFilter = 'All';

  // Placeholder data for transactions
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 1,
      'customer': 'John Doe',
      'amount': 50.0,
      'type': 'Credit',
      'date': '2023-07-01'
    },
    {
      'id': 2,
      'customer': 'Jane Smith',
      'amount': 25.0,
      'type': 'Credit',
      'date': '2023-07-02'
    },
    {
      'id': 4,
      'customer': 'John Doe',
      'amount': -15.0,
      'type': 'Debit',
      'date': '2023-07-04'
    },
    {
      'id': 5,
      'customer': 'Jane Smith',
      'amount': -10.0,
      'type': 'Debit',
      'date': '2023-07-05'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transaction History',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Implement filter functionality
                  _showFilterOptions();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Transactions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Transactions'),
                leading: _currentFilter == 'All'
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentFilter = 'All';
                  });
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing all transactions'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Credits Only'),
                leading: _currentFilter == 'Credit'
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentFilter = 'Credit';
                  });
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing credit transactions only'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Debits Only'),
                leading: _currentFilter == 'Debit'
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentFilter = 'Debit';
                  });
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing debit transactions only'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionList() {
    // Filter transactions based on the selected filter
    List<Map<String, dynamic>> filteredTransactions = _transactions;

    if (_currentFilter != 'All') {
      filteredTransactions = _transactions
          .where((transaction) => transaction['type'] == _currentFilter)
          .toList();
    }

    // If no transactions match the filter, show a message
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No $_currentFilter transactions found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentFilter = 'All';
                });
              },
              child: const Text('Show All Transactions'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        final bool isCredit = transaction['type'] == 'Credit';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (isCredit ? Colors.green : Colors.red).withOpacity(0.2),
              child: Icon(isCredit ? Icons.add_circle : Icons.remove_circle,
                  color: isCredit ? Colors.green : Colors.red),
            ),
            title: Text('${transaction['customer']} - ${transaction['type']}'),
            subtitle: Text('Transaction ID: ${transaction['id']}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : ''}${transaction['amount']}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCredit ? Colors.green : Colors.red),
                ),
                Text('${transaction['date']}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            onTap: () {
              _showTransactionDetails(transaction);
            },
          ),
        );
      },
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Transaction #${transaction['id']}'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTransactionDetailRow('Customer', transaction['customer']),
              _buildTransactionDetailRow(
                  'Amount', '\$${transaction['amount']}'),
              _buildTransactionDetailRow('Type', transaction['type']),
              _buildTransactionDetailRow('Date', transaction['date']),
              const Divider(),
              const Text('Status: Completed',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
