import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
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
      'credit': 200.0,
      'type': 'Technicien'
    },
  ];

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
      'id': 3,
      'customer': 'Bob Tech',
      'amount': 100.0,
      'type': 'Credit',
      'date': '2023-07-03'
    },
  ];

  DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSummaryCards(),
          const SizedBox(height: 20),
          const Text('Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildRecentActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSummaryCard(
            'Total Clients',
            '${_customers.where((c) => c['type'] == 'Client').length}',
            Icons.people,
            Colors.blue),
        _buildSummaryCard(
            'Total Techniciens',
            '${_customers.where((c) => c['type'] == 'Technicien').length}',
            Icons.engineering,
            Colors.green),
        _buildSummaryCard(
            'Total Credit',
            '${_customers.fold(0.0, (sum, customer) => sum + (customer['credit'] as double))}',
            Icons.account_balance_wallet,
            Colors.orange),
        _buildSummaryCard('Transactions', '${_transactions.length}',
            Icons.receipt_long, Colors.purple),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesList() {
    return Card(
      elevation: 2,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.take(5).length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.2),
              child: const Icon(Icons.swap_horiz, color: Colors.blue),
            ),
            title: Text('${transaction['customer']} - ${transaction['type']}'),
            subtitle: Text(
                'Amount: ${transaction['amount']} DA • ${transaction['date']}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        },
      ),
    );
  }
}
