import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // Update with your actual backend URL
  final String baseUrl =
      'http://10.0.2.2:5000'; // Use this for Android emulator
  // For physical devices or web, use your actual server IP/domain
  // final String baseUrl = 'http://192.168.1.x:5000';

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String type,
    double? credit,
    String? nfcId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/'), // This uses the POST / route
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password':
              '123456', // Default password, consider making this configurable
          'userType': type == 'Client' ? 'client' : 'technician',
          if (credit != null) 'balance': credit,
          if (nfcId != null) 'nfcId': nfcId,
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
}
