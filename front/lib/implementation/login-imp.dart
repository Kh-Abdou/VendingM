import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      "http://192.168.56.1:5000"; // Replace with your backend URL

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(
        '$baseUrl/user/login'); // Modifié de /post/login à /user/login
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Successful login
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
