// import 'package:flutter/material.dart';

// class AdminHomePage extends StatefulWidget {
//   const AdminHomePage({Key? key}) : super(key: key);

//   @override
//   _AdminHomePageState createState() => _AdminHomePageState();
// }

// class _AdminHomePageState extends State<AdminHomePage> {
//   int _selectedIndex = 0;
  
//   // Placeholder data for customers
//   final List<Map<String, dynamic>> _customers = [
//     {'id': 1, 'name': 'John Doe', 'email': 'john@example.com', 'credit': 100.0, 'type': 'Client'},
//     {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com', 'credit': 50.0, 'type': 'Client'},
//     {'id': 3, 'name': 'Bob Tech', 'email': 'bob@example.com', 'credit': 200.0, 'type': 'Technicien'},
//   ];

//   // Placeholder data for transactions
//   final List<Map<String, dynamic>> _transactions = [
//     {'id': 1, 'customer': 'John Doe', 'amount': 50.0, 'type': 'Credit', 'date': '2023-07-01'},
//     {'id': 2, 'customer': 'Jane Smith', 'amount': 25.0, 'type': 'Credit', 'date': '2023-07-02'},
//     {'id': 3, 'customer': 'Bob Tech', 'amount': 100.0, 'type': 'Credit', 'date': '2023-07-03'},
//   ];
  
//   // List of pages to display
//   late final List<Widget> _pages;
  
//   @override
//   void initState() {
//     super.initState();
//     _pages = [
//       _buildDashboardPage(),
//       _buildCreditManagementPage(),
//       _buildAccountManagementPage(),
//       _buildTransactionHistoryPage(),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         backgroundColor: Colors.blue, // Replace with your theme color
//       ),
//       drawer: _buildDrawer(),
//       body: _pages[_selectedIndex],
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               color: Colors.blue, // Replace with your theme color
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.white,
//                   child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.blue),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'Admin Panel',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                   ),
//                 ),
//                 Text(
//                   'Admin@gmail.com',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildDrawerItem(0, 'Dashboard', Icons.dashboard),
//           _buildDrawerItem(1, 'Recharge Client Credit', Icons.account_balance_wallet),
//           _buildDrawerItem(2, 'Account Management', Icons.people),
//           _buildDrawerItem(3, 'Transaction History', Icons.history),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text('Logout'),
//             onTap: () {
//               // TODO: Implement logout functionality
//               Navigator.pop(context);
//               Navigator.of(context).pushReplacementNamed('/login'); // Redirect to login page
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem(int index, String title, IconData icon) {
//     return ListTile(
//       leading: Icon(icon),
//       title: Text(title),
//       selected: _selectedIndex == index,
//       onTap: () {
//         setState(() {
//           _selectedIndex = index;
//         });
//         Navigator.pop(context);
//       },
//     );
//   }

//   // Dashboard Page
//   Widget _buildDashboardPage() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 20),
//           _buildSummaryCards(),
//           const SizedBox(height: 20),
//           const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           _buildRecentActivitiesList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryCards() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       crossAxisSpacing: 16,
//       mainAxisSpacing: 16,
//       children: [
//         _buildSummaryCard('Total Clients', '${_customers.where((c) => c['type'] == 'Client').length}', Icons.people, Colors.blue),
//         _buildSummaryCard('Total Techniciens', '${_customers.where((c) => c['type'] == 'Technicien').length}', Icons.engineering, Colors.green),
//         _buildSummaryCard('Total Credit', '${_customers.fold(0.0, (sum, customer) => sum + (customer['credit'] as double))}', Icons.account_balance_wallet, Colors.orange),
//         _buildSummaryCard('Transactions', '${_transactions.length}', Icons.receipt_long, Colors.purple),
//       ],
//     );
//   }

//   Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 40, color: color),
//             const SizedBox(height: 8),
//             Text(title, style: const TextStyle(fontSize: 16)),
//             Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivitiesList() {
//     return Card(
//       elevation: 2,
//       child: ListView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: _transactions.take(5).length,
//         itemBuilder: (context, index) {
//           final transaction = _transactions[index];
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.blue.withOpacity(0.2),
//               child: const Icon(Icons.swap_horiz, color: Colors.blue),
//             ),
//             title: Text('${transaction['customer']} - ${transaction['type']}'),
//             subtitle: Text('Amount: \$${transaction['amount']} • ${transaction['date']}'),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           );
//         },
//       ),
//     );
//   }

//   // Credit Management Page
//   Widget _buildCreditManagementPage() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Recharge Client Credit', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 20),
//           _buildCreditRechargeForm(),
//           const SizedBox(height: 20),
//           const Text('Client List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           Expanded(child: _buildClientCreditList()),
//         ],
//       ),
//     );
//   }

//   Widget _buildCreditRechargeForm() {
//     final _selectedClient = _customers.first;
//     final _amountController = TextEditingController();

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Add Credit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<int>(
//               decoration: const InputDecoration(
//                 labelText: 'Select Client',
//                 border: OutlineInputBorder(),
//               ),
//               value: _selectedClient['id'],
//               items: _customers.map((customer) {
//                 return DropdownMenuItem<int>(
//                   value: customer['id'],
//                   child: Text('${customer['name']} (${customer['email']})'),
//                 );
//               }).toList(),
//               onChanged: (value) {},
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _amountController,
//               decoration: const InputDecoration(
//                 labelText: 'Amount',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.attach_money),
//               ),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue, // Replace with your theme color
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//                 onPressed: () {
//                   // TODO: Implement credit recharge logic
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Credit added successfully!')),
//                   );
//                 },
//                 child: const Text('Add Credit'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildClientCreditList() {
//     return ListView.builder(
//       itemCount: _customers.length,
//       itemBuilder: (context, index) {
//         final customer = _customers[index];
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           child: ListTile(
//             leading: CircleAvatar(
//               child: Text(customer['name'].substring(0, 1)),
//             ),
//             title: Text('${customer['name']} (${customer['type']})'),
//             subtitle: Text('${customer['email']}'),
//             trailing: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text('Credit: \$${customer['credit']}', 
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ],
//             ),
//             onTap: () {
//               // Show detail view if needed
//             },
//           ),
//         );
//       },
//     );
//   }

//   // Account Management Page
//   Widget _buildAccountManagementPage() {
//     return DefaultTabController(
//       length: 2,
//       child: Column(
//         children: [
//           const TabBar(
//             labelColor: Colors.blue, // Replace with your theme color
//             tabs: [
//               Tab(text: 'Clients'),
//               Tab(text: 'Techniciens'),
//             ],
//           ),
//           Expanded(
//             child: TabBarView(
//               children: [
//                 _buildAccountsList('Client'),
//                 _buildAccountsList('Technicien'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAccountsList(String type) {
//     final filteredAccounts = _customers.where((c) => c['type'] == type).toList();
    
//     return Scaffold(
//       body: ListView.builder(
//         itemCount: filteredAccounts.length,
//         padding: const EdgeInsets.all(8.0),
//         itemBuilder: (context, index) {
//           final account = filteredAccounts[index];
//           return Card(
//             elevation: 2,
//             margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.blue.withOpacity(0.2),
//                 child: Text(account['name'].substring(0, 1)),
//               ),
//               title: Text('${account['name']}'),
//               subtitle: Text('${account['email']} - Credit: \$${account['credit']}'),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.edit, color: Colors.blue),
//                     onPressed: () {
//                       _showEditAccountDialog(account);
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.red),
//                     onPressed: () {
//                       _showDeleteConfirmationDialog(account);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.blue, // Replace with your theme color
//         onPressed: () {
//           _showAddAccountDialog(type);
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   void _showAddAccountDialog(String type) {
//     final nameController = TextEditingController();
//     final emailController = TextEditingController();
//     final creditController = TextEditingController(text: '0.0');
    
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Add New $type'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Name',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: creditController,
//                   decoration: const InputDecoration(
//                     labelText: 'Credit',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // TODO: Implement add account logic
//                 setState(() {
//                   _customers.add({
//                     'id': _customers.length + 1,
//                     'name': nameController.text,
//                     'email': emailController.text,
//                     'credit': double.tryParse(creditController.text) ?? 0.0,
//                     'type': type,
//                   });
//                 });
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Account created successfully')),
//                 );
//               },
//               child: const Text('Create'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showEditAccountDialog(Map<String, dynamic> account) {
//     final nameController = TextEditingController(text: account['name']);
//     final emailController = TextEditingController(text: account['email']);
//     final creditController = TextEditingController(text: account['credit'].toString());
    
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Edit Account'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Name',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: emailController,
//                   decoration: const InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.emailAddress,
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: creditController,
//                   decoration: const InputDecoration(
//                     labelText: 'Credit',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // TODO: Implement update account logic
//                 setState(() {
//                   final index = _customers.indexWhere((c) => c['id'] == account['id']);
//                   if (index != -1) {
//                     _customers[index] = {
//                       'id': account['id'],
//                       'name': nameController.text,
//                       'email': emailController.text,
//                       'credit': double.tryParse(creditController.text) ?? 0.0,
//                       'type': account['type'],
//                     };
//                   }
//                 });
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Account updated successfully')),
//                 );
//               },
//               child: const Text('Update'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showDeleteConfirmationDialog(Map<String, dynamic> account) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Confirm Delete'),
//           content: Text('Are you sure you want to delete ${account['name']}\'s account?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 // TODO: Implement delete account logic
//                 setState(() {
//                   _customers.removeWhere((c) => c['id'] == account['id']);
//                 });
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Account deleted successfully')),
//                 );
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               child: const Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Transaction History Page
//   Widget _buildTransactionHistoryPage() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('Transaction History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//               IconButton(
//                 icon: const Icon(Icons.filter_list),
//                 onPressed: () {
//                   // TODO: Implement filter functionality
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: _buildTransactionList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionList() {
//     return ListView.builder(
//       itemCount: _transactions.length,
//       itemBuilder: (context, index) {
//         final transaction = _transactions[index];
//         return Card(
//           elevation: 2,
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.blue.withOpacity(0.2),
//               child: const Icon(Icons.receipt, color: Colors.blue),
//             ),
//             title: Text('${transaction['customer']} - ${transaction['type']}'),
//             subtitle: Text('Transaction ID: ${transaction['id']}'),
//             trailing: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text('\$${transaction['amount']}', 
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Text('${transaction['date']}', style: const TextStyle(fontSize: 12)),
//               ],
//             ),
//             onTap: () {
//               _showTransactionDetails(transaction);
//             },
//           ),
//         );
//       },
//     );
//   }

//   void _showTransactionDetails(Map<String, dynamic> transaction) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Transaction #${transaction['id']}'),
//           content: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildTransactionDetailRow('Customer', transaction['customer']),
//               _buildTransactionDetailRow('Amount', '\$${transaction['amount']}'),
//               _buildTransactionDetailRow('Type', transaction['type']),
//               _buildTransactionDetailRow('Date', transaction['date']),
//               const Divider(),
//               const Text('Status: Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildTransactionDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
// }
