import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/client.dart';

class ClientService {
  // Update this with your actual API base URL
  final String baseUrl = 'http://192.168.56.1:5000';

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
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Client.fromJson(json)).toList();
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

        // Check if the client data is present in the response
        if (responseData.containsKey('client')) {
          // Extract and return the client data
          return Client.fromJson(responseData['client']);
        } else {
          // If client data is not available, fetch the client details
          return getClient(clientId);
        }
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
