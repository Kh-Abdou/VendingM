import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/client.dart';

class ClientService {
  // Use the API base URL from main.dart
  final String baseUrl;

  ClientService({required this.baseUrl});

  Future<List<Client>> getClients() async {
    try {
      // Updated endpoint from /post/clients to /user/clients to match server routes
      print('Attempting to fetch clients from: $baseUrl/user/clients');
      final response = await http.get(
        Uri.parse('$baseUrl/user/clients'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Is the server running?');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> clientsData = json.decode(response.body);
        List<Client> clients = [];

        // Fetch wallet data for each client
        for (var clientData in clientsData) {
          try {
            final clientId = clientData['_id'];
            if (clientId != null) {
              // Get wallet data
              final walletResponse = await http.get(
                Uri.parse('$baseUrl/ewallet/$clientId'),
                headers: {'Content-Type': 'application/json'},
              );

              if (walletResponse.statusCode == 200) {
                final walletData = json.decode(walletResponse.body);
                if (walletData['balance'] != null) {
                  // Update client data with wallet balance
                  clientData['credit'] = walletData['balance'];
                }
              }
            }
          } catch (e) {
            print('Error fetching wallet for client ${clientData['_id']}: $e');
          }

          clients.add(Client.fromJson(clientData));
        }
        return clients;
      } else {
        throw Exception(
            'Server returned status code ${response.statusCode}: ${response.body}');
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      throw Exception(
          'Cannot connect to the server. Please check your network connection and server status.');
    } on HttpException catch (e) {
      print('HTTP exception: $e');
      throw Exception('HTTP error occurred: $e');
    } on FormatException catch (e) {
      print('Format exception: $e');
      throw Exception('Invalid response format: $e');
    } on TimeoutException catch (e) {
      print('Timeout exception: $e');
      throw Exception('Connection timed out. Please try again.');
    } catch (e) {
      print('Unknown error occurred: $e');
      throw Exception('Failed to load clients: $e');
    }
  }

  Future<Client> rechargeClientBalance(String clientId, double amount) async {
    print('Attempting to recharge client: $clientId with amount: $amount');

    try {
      // Updated endpoint from /post/clients to /user/clients to match server routes
      final response = await http
          .post(
        Uri.parse('$baseUrl/user/clients/$clientId/recharge'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Is the server running?');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        // Parse the response body
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Get the updated balance from the wallet data
        final walletData = responseData['wallet'];

        // Create an updated client object with the new balance
        final Map<String, dynamic> clientData = responseData['client'];
        if (walletData != null) {
          clientData['credit'] = walletData['balance'];
        }

        return Client.fromJson(clientData);
      } else {
        throw Exception('Failed to recharge client balance: ${response.body}');
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
      throw Exception(
          'Cannot connect to the server. Please check your network connection and server status.');
    } on HttpException catch (e) {
      print('HTTP exception: $e');
      throw Exception('HTTP error occurred: $e');
    } on FormatException catch (e) {
      print('Format exception: $e');
      throw Exception('Invalid response format: $e');
    } catch (e) {
      print('Error in rechargeClientBalance: $e');
      rethrow;
    }
  }

  // Add a method to get a single client by ID
  Future<Client> getClient(String clientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$clientId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Is the server running?');
        },
      );

      if (response.statusCode == 200) {
        return Client.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get client: ${response.body}');
      }
    } catch (e) {
      print('Error getting client: $e');
      rethrow;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
