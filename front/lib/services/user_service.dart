import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  // Méthode pour s'inscrire
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String type,
    double? credit,
    String? nfcId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/user'), // Mise à jour : ajout de /user pour correspondre à la route
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

  // Méthode pour connecter un utilisateur
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'), // Mise à jour : ajout de /user
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
        throw Exception(errorData['message'] ?? 'Échec de la connexion');
      }
    } catch (e) {
      throw Exception('Échec de la connexion: $e');
    }
  }

  // Méthode pour obtenir les détails de l'utilisateur
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'), // Mise à jour : ajout de /user
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Impossible de récupérer les détails de l\'utilisateur');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  // Méthode pour mettre à jour le mot de passe
  Future<bool> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/user/$userId/password'), // Mise à jour : ajout de /user
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  // Méthode pour obtenir le solde du portefeuille électronique
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
      print('Erreur lors de la récupération du solde: $e');
      return 0.0;
    }
  }

  // Get all users
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/user'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  // Get clients only
  Future<List<dynamic>> getClients() async {
    final response = await http.get(Uri.parse('$baseUrl/user/clients'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load clients: ${response.body}');
    }
  }

  // Get technicians (filter users with role = technician)
  Future<List<dynamic>> getTechnicians() async {
    final response = await http.get(Uri.parse('$baseUrl/user'));

    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      return users.where((user) => user['role'] == 'technician').toList();
    } else {
      throw Exception('Failed to load technicians: ${response.body}');
    }
  }

  // Create a new user
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to create user');
    }
  }

  // Update a user
  Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update user');
    }
  }

  // Delete a user
  Future<void> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/user/$id'));

    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to delete user');
    }
  }

  // Recharge client balance
  Future<Map<String, dynamic>> rechargeBalance(String id, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/clients/$id/recharge'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to recharge balance');
    }
  }
}
