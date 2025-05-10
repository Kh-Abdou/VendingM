import 'dart:developer' as developer;
import 'api_service.dart';

class EWalletService {
  Future<Map<String, dynamic>> getBalance(String userId) async {
    try {
      developer.log("Requesting balance for user: $userId");
      final result = await ApiService.get('/ewallet/$userId');
      developer.log("Balance response: $result");
      return result;
    } catch (e) {
      developer.log("Error getting balance: $e", error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addFunds(String userId, double amount) async {
    try {
      developer.log("Adding funds for user: $userId, Amount: $amount");
      final result = await ApiService.post('/ewallet/add-funds', {
        'userId': userId,
        'amount': amount,
      });
      developer.log("Add funds response: $result");
      return result;
    } catch (e) {
      developer.log("Error adding funds: $e", error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processPayment(
      String userId, double amount, List<Map<String, dynamic>> products) async {
    try {
      developer.log(
          "Processing payment for user: $userId, Amount: $amount, Products: $products");
      final result = await ApiService.post('/ewallet/payment', {
        'userId': userId,
        'amount': amount,
        'products': products,
      });
      developer.log("Process payment response: $result");
      return result;
    } catch (e) {
      developer.log("Error processing payment: $e", error: e);
      rethrow;
    }
  }

  Future<List<dynamic>> getTransactionHistory(String userId) async {
    try {
      developer.log("Fetching transaction history for user: $userId");
      final result = await ApiService.get('/ewallet/transactions/$userId');
      final transactions = result['transactions'] ?? [];
      developer.log("Transaction history response: $transactions");
      return transactions;
    } catch (e) {
      developer.log("Error fetching transaction history: $e", error: e);
      rethrow;
    }
  }
}
