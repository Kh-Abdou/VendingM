import 'dart:developer' as developer;

// Mock implementation of ApiService
class ApiService {
  Future<Map<String, dynamic>> get(String endpoint) async {
    // Simulate API GET request
    return {};
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    // Simulate API POST request
    return {};
  }
}

class EWalletService {
  final ApiService _apiService;

  EWalletService(this._apiService);

  Future<Map<String, dynamic>> getBalance(String userId) async {
    try {
      developer.log("Requesting balance for user: $userId");
      final result = await _apiService.get('ewallet/$userId');
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
      final result = await _apiService.post('ewallet/add-funds', {
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
      final result = await _apiService.post('ewallet/payment', {
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
      final result = await _apiService.get('ewallet/transactions/$userId');
      final transactions = result['transactions'] ?? [];
      developer.log("Transaction history response: $transactions");
      return transactions;
    } catch (e) {
      developer.log("Error fetching transaction history: $e", error: e);
      rethrow;
    }
  }
}
