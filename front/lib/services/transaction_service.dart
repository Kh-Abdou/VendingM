import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import '../models/transaction_model.dart';
import 'api_service.dart';

class TransactionService {
  // Add a timeout duration for API requests
  static const Duration _requestTimeout = Duration(seconds: 10);

  // Get transaction history for a user
  static Future<List<Transaction>> getTransactionHistory(String userId) async {
    try {
      developer.log("Fetching transaction history for user: $userId");

      // Add timestamp to prevent caching issues
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final requestUrl = '/ewallet/transactions/$userId?timestamp=$timestamp';
      developer.log("Making API request to: $requestUrl");

      final result = await ApiService.get(requestUrl).timeout(_requestTimeout,
          onTimeout: () {
        developer.log("API request timed out");
        throw TimeoutException(
            'Connection timed out. Please check your internet connection.');
      });

      developer.log("API response received: ${jsonEncode(result)}");

      List<Transaction> transactions = [];

      // Handle the case where result is null
      if (result == null) {
        developer.log("API returned null result");
        throw Exception("No data received from server");
      }

      // Get the user name for these transactions
      final userResponse =
          await ApiService.get('/user/${userId}?timestamp=$timestamp');
      final String userName = userResponse['name'] ?? 'Unknown User';

      if (result['transactions'] != null) {
        final List transactionList = result['transactions'];
        transactions = transactionList.map((item) {
          // Add an ID if it's missing in the backend response
          final transactionData = Map<String, dynamic>.from(item);
          if (!transactionData.containsKey('_id')) {
            transactionData['_id'] = transactionData['orderId'] ??
                DateTime.now().millisecondsSinceEpoch.toString();
          }
          // Add customer name to each transaction
          transactionData['customerName'] = userName;
          return Transaction.fromJson(transactionData);
        }).toList();
      } else if (result is List) {
        // Try to interpret the result as a direct list of transactions
        transactions = (result as List).map((item) {
          final transactionData = Map<String, dynamic>.from(item);
          if (!transactionData.containsKey('_id')) {
            transactionData['_id'] = transactionData['orderId'] ??
                DateTime.now().millisecondsSinceEpoch.toString();
          }
          // Add customer name to each transaction
          transactionData['customerName'] = userName;
          return Transaction.fromJson(transactionData);
        }).toList();
      } else {
        // If we got back a response but it's not in the format we expect
        developer.log("Unexpected API response format: ${jsonEncode(result)}");
        throw Exception("Unexpected response format from server");
      }

      developer.log("Received ${transactions.length} transactions");
      return transactions;
    } catch (e) {
      // More detailed error logging
      developer.log("Error fetching transaction history: $e", error: e);
      rethrow; // Rethrow so we can show proper error in the UI
    }
  }

  // Get all transactions (for admin)
  static Future<List<Transaction>> getAllTransactions() async {
    try {
      developer.log("Fetching all transactions as admin");

      // Add timestamp to prevent caching issues
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final requestUrl = '/user/clients?timestamp=$timestamp';

      final result = await ApiService.get(requestUrl).timeout(_requestTimeout,
          onTimeout: () {
        developer.log("Admin API request timed out");
        throw TimeoutException(
            'Connection timed out. Please check your internet connection.');
      });

      if (result == null) {
        developer.log("Admin API returned null result");
        throw Exception("No data received from server");
      }

      developer.log("Got clients list, fetching their wallets");

      // Now get wallet data for each client
      List<Transaction> allTransactions = [];

      if (result is List) {
        // Process each client
        for (var client in result) {
          if (client['_id'] != null) {
            try {
              final String userId = client['_id'].toString();
              final walletResult =
                  await ApiService.get('/ewallet/$userId?timestamp=$timestamp');

              if (walletResult != null &&
                  walletResult['transactions'] != null) {
                final List transactionList = walletResult['transactions'];
                // Add client name to each transaction for better display
                final clientName = client['name'] ?? 'Utilisateur Inconnu';

                allTransactions.addAll(transactionList.map((item) {
                  final transactionData = Map<String, dynamic>.from(item);
                  // Add ID and customer name
                  if (!transactionData.containsKey('_id')) {
                    transactionData['_id'] = transactionData['orderId'] ??
                        DateTime.now().millisecondsSinceEpoch.toString();
                  }
                  transactionData['customerName'] = clientName;
                  transactionData['userId'] = userId;

                  return Transaction.fromJson(transactionData);
                }));
              }
            } catch (clientError) {
              developer.log("Error fetching wallet for client: $clientError");
              // Continue with next client
            }
          }
        }
      }

      // Sort transactions by date (most recent first)
      allTransactions.sort((a, b) => b.date.compareTo(a.date));

      developer.log("Received ${allTransactions.length} total transactions");
      return allTransactions;
    } catch (e) {
      developer.log("Error fetching all transactions: $e", error: e);
      rethrow; // Rethrow so we can show proper error in the UI
    }
  }
}
