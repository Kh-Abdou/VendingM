import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage>
    with WidgetsBindingObserver {
  // Add filter state
  String _currentFilter = 'All';

  // Transaction data
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  Timer? _loadingTimer;
  Timer? _refreshTimer; // Timer pour l'actualisation automatique

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTransactions(forceReload: true);

    // Configurer un timer pour recharger les transactions toutes les 5 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        developer.log("Auto-refreshing transactions");
        _loadTransactions(isAutoRefresh: true, forceReload: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadingTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'app est revenue au premier plan, actualiser les données
      developer.log("App resumed, refreshing transactions");
      _loadTransactions(isAutoRefresh: true, forceReload: true);
    }
  }

  // Load transactions from backend
  Future<void> _loadTransactions(
      {bool isAutoRefresh = false, bool forceReload = false}) async {
    // Si c'est un rechargement automatique, ne pas afficher le loader
    if (!isAutoRefresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        if (forceReload) {
          _transactions = []; // Clear existing transactions
        }
      });
    }

    // Set a timeout to prevent infinite loading
    _loadingTimer?.cancel();
    if (!isAutoRefresh) {
      _loadingTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
            _error = 'Loading took too long. Please try again.';
          });
        }
      });
    }

    try {
      String userId = '';
      bool isAdmin = false;

      try {
        // Try to get the user ID and role from SharedPreferences
        developer.log("Attempting to get user info from SharedPreferences");
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId') ?? '';
        final userRole = prefs.getString('userRole');
        isAdmin = userRole == 'admin';

        developer.log("User ID: $userId, Role: $userRole");
      } catch (prefsError) {
        // Instead of showing an error, just proceed as admin
        developer.log("Error accessing SharedPreferences: $prefsError");
        developer.log("Proceeding in admin mode as fallback");
        isAdmin = true; // Use admin mode as fallback
      }

      // Even if userId is empty, proceed as admin
      if (userId.isEmpty) {
        isAdmin = true;
        developer.log("No user ID found, proceeding in admin mode");
      }

      List<Transaction> loadedTransactions = [];

      try {
        // Always try to load transactions, either as admin or for a specific user
        if (isAdmin) {
          developer.log("Loading transactions as admin");
          loadedTransactions = await TransactionService.getAllTransactions();
        } else {
          developer.log("Loading transactions for user: $userId");
          loadedTransactions =
              await TransactionService.getTransactionHistory(userId);
        }

        // Log the transactions for debugging
        developer.log("Loaded ${loadedTransactions.length} transactions");
        for (var tx in loadedTransactions) {
          developer.log(
              "Transaction: ${tx.id} - ${tx.customerName} - ${tx.amount} - ${tx.date}");
        }
      } catch (apiError) {
        developer.log("API error: $apiError");
        if (!isAutoRefresh) {
          // Ne pas afficher d'erreur en cas d'actualisation automatique
          setState(() {
            _isLoading = false;
            _error =
                'Error connecting to server: ${apiError.toString().split(':').first}';
          });
        }
        return;
      }

      // Cancel the timeout since we got a response
      _loadingTimer?.cancel();

      if (mounted) {
        setState(() {
          _transactions = loadedTransactions;
          if (!isAutoRefresh) {
            _isLoading = false;
          }

          // If we got an empty list, show a more user-friendly message
          if (_transactions.isEmpty && !isAutoRefresh) {
            _error =
                'No transactions found. Add funds to see transactions here.';
          } else {
            _error =
                null; // Clear any previous error if we have transactions now
          }
        });
      }
    } catch (e) {
      developer.log("Error in _loadTransactions: $e");

      // Cancel the timeout since we got an error
      _loadingTimer?.cancel();

      if (mounted && !isAutoRefresh) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load transactions: $e';
        });
      }
    }
  }

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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading
                        ? null
                        : () {
                            _loadTransactions();
                          },
                    tooltip: 'Refresh transactions',
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _isLoading
                        ? null
                        : () {
                            _showFilterOptions();
                          },
                    tooltip: 'Filter transactions',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading transactions...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTransactions,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : _buildTransactionList(),
          ),
          // Debug info at bottom
          if (_transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing ${_transactions.length} transactions',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
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
    List<Transaction> filteredTransactions = _transactions;

    if (_currentFilter != 'All') {
      filteredTransactions = _transactions
          .where((transaction) => transaction.displayType == _currentFilter)
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
              _transactions.isEmpty
                  ? 'No transactions found'
                  : 'No $_currentFilter transactions found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_transactions.isNotEmpty)
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
        final bool isCredit = transaction.isCredit;

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
            title: Text(
                '${transaction.customerName} - ${transaction.displayType}'),
            subtitle: Text('Transaction ID: ${transaction.id}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : ''}${transaction.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isCredit ? Colors.green : Colors.red),
                ),
                Text(transaction.formattedDate,
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

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Transaction #${transaction.id}'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTransactionDetailRow('Customer', transaction.customerName),
              _buildTransactionDetailRow(
                  'Amount', '\$${transaction.amount.abs().toStringAsFixed(2)}'),
              _buildTransactionDetailRow('Type', transaction.displayType),
              _buildTransactionDetailRow('Date', transaction.formattedDate),
              if (transaction.orderId != null)
                _buildTransactionDetailRow('Order ID', transaction.orderId!),
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
