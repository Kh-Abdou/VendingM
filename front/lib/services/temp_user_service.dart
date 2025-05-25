import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl;
  Timer? _rfidPollTimer;
  final StreamController<Map<String, dynamic>> _rfidStreamController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get rfidStream => _rfidStreamController.stream;

  UserService({required this.baseUrl}) {
    _startRfidPolling();
  }

  void dispose() {
    _rfidPollTimer?.cancel();
    _rfidStreamController.close();
  }

  void _startRfidPolling() {
    _rfidPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      checkPendingRfidRegistration().then((response) {
        if (response.containsKey('pendingRegistrations')) {
          for (var registration in response['pendingRegistrations']) {
            _rfidStreamController
                .add({'type': 'pending_registration', 'data': registration});
          }
        }
      }).catchError((error) {
        _rfidStreamController.add({'type': 'error', 'error': error.toString()});
      });
    });
  }

  // RFID Related Methods
  Future<Map<String, dynamic>> initRfidRegistration({
    required String name,
    required String email,
    required String password,
    required String type,
    double? credit,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/rfid/init'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': type == 'Client' ? 'client' : 'technician',
          if (credit != null && credit > 0) 'credit': credit,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to init RFID registration');
      }
    } catch (e) {
      throw Exception('Failed to init RFID registration: $e');
    }
  }

  Future<Map<String, dynamic>> checkPendingRfidRegistration() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/rfid/check-pending'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'pendingRegistrations': []};
      }
    } catch (e) {
      throw Exception('Failed to check pending RFID registrations: $e');
    }
  }

  Future<Map<String, dynamic>> completeRfidRegistration({
    required String userId,
    required String rfidUID,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/rfid/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'rfidUID': rfidUID,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to complete RFID registration');
      }
    } catch (e) {
      throw Exception('Failed to complete RFID registration: $e');
    }
  }

  // User Management Methods
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String type,
    double? credit,
    String? rfidUID,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': '123456', // Default password
          'role': type == 'Client' ? 'client' : 'technician',
          if (credit != null) 'balance': credit,
          if (rfidUID != null) 'rfidUID': rfidUID,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user details');
      }
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  Future<bool> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  Future<double> getWalletBalance(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ewallet/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['balance'] != null ? data['balance'].toDouble() : 0.0;
      } else {
        return 0.0;
      }
    } catch (e) {
      print('Failed to get wallet balance: $e');
      return 0.0;
    }
  }

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<List<dynamic>> getClients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/clients'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load clients');
      }
    } catch (e) {
      throw Exception('Failed to load clients: $e');
    }
  }

  Future<List<dynamic>> getTechnicians() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        return users.where((user) => user['role'] == 'technician').toList();
      } else {
        throw Exception('Failed to load technicians');
      }
    } catch (e) {
      throw Exception('Failed to load technicians: $e');
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<Map<String, dynamic>> rechargeBalance(String id, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/clients/$id/recharge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to recharge balance');
      }
    } catch (e) {
      throw Exception('Failed to recharge balance: $e');
    }
  }
}
