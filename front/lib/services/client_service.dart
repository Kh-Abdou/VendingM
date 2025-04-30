import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client.dart';

class ClientService {
  // Update this with your actual API base URL
  final String baseUrl = 'http://192.168.56.1:5000';

  Future<List<Client>> getClients() async {
    final response = await http.get(Uri.parse('$baseUrl/post/clients'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }

  Future<Client> rechargeClientBalance(int clientId, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/post/clients/$clientId/recharge'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return Client.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to recharge client balance');
    }
  }
}
