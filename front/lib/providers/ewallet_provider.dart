import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ewallet_service.dart';
import '../models/cart_item_model.dart';

class EWalletProvider with ChangeNotifier {
  final EWalletService _ewalletService;
  final String userId;

  double _balance = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = false;

  EWalletProvider({
    required EWalletService ewalletService,
    required this.userId,
  }) : _ewalletService = ewalletService {
    _loadBalance();
  }

  double get balance => _balance;
  List<dynamic> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> _loadBalance() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await _ewalletService.getBalance(userId);
      _balance = (data['balance'] ?? 0).toDouble();
      _transactions = data['transactions'] ?? [];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Failed to load balance: $e');
    }
  }

  Future<bool> addFunds(double amount) async {
    try {
      _isLoading = true;
      notifyListeners();

      // S'assurer que amount est bien un double
      if (amount is! double) {
        amount = double.parse(amount.toString());
      }

      print("Adding funds: $amount to user: $userId"); // Débogage

      final result = await _ewalletService.addFunds(userId, amount);
      print("Add funds result: $result"); // Débogage

      // S'assurer que la balance est bien un double
      _balance = double.parse((result['balance'] ?? 0).toString());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error adding funds: $e"); // Débogage
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> processPayment(
      List<CartItemModel> items) async {
    try {
      if (items.isEmpty) return null;

      _isLoading = true;
      notifyListeners();

      final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);

      if (totalAmount > _balance) {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Insufficient funds'};
      }

      final products = items
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
                'price': item.product.price,
              })
          .toList();

      final result =
          await _ewalletService.processPayment(userId, totalAmount, products);
      _balance = (result['balance'] ?? 0).toDouble();

      _isLoading = false;
      notifyListeners();

      return {'success': true, 'orderId': result['orderId']};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Failed to process payment: $e');
      return {'success': false, 'message': 'Payment failed'};
    }
  }

  // Méthode pour forcer le rafraîchissement
  Future<void> forceRefresh() async {
    try {
      final data = await _ewalletService.getBalance(userId);
      print("Balance data: $data"); // Débogage
      _balance = (data['balance'] ?? 0).toDouble();
      _transactions = data['transactions'] ?? [];
      notifyListeners();
    } catch (e) {
      print("Error refreshing balance: $e");
    }
  }
}

// Dans votre page où vous affichez le portefeuille:
void _showWallet(BuildContext context) async {
  final ewalletProvider = Provider.of<EWalletProvider>(context, listen: false);

  // Montrer un indicateur de chargement
  showDialog(
    context: context,
    builder: (context) => Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  // Forcer le rafraîchissement
  await ewalletProvider.forceRefresh();

  // Fermer l'indicateur de chargement
  Navigator.of(context).pop();

  // Afficher le portefeuille
  // ...
}
