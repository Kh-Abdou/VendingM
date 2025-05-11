import 'dart:convert';
import 'package:http/http.dart' as http;

class HardwareService {
  final String baseUrl;

  HardwareService({required this.baseUrl});

  // Get all vending machines
  Future<List<dynamic>> getAllMachines() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hardware'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error fetching vending machines');
      }
    } catch (e) {
      throw Exception('Error fetching vending machines: $e');
    }
  }

  // Get environment data from all machines
  Future<List<dynamic>> getEnvironmentData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hardware/environment'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error fetching environment data');
      }
    } catch (e) {
      throw Exception('Error fetching environment data: $e');
    }
  }

  // Get a specific vending machine by ID
  Future<Map<String, dynamic>> getMachineById(String machineId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hardware/$machineId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error fetching vending machine details');
      }
    } catch (e) {
      throw Exception('Error fetching vending machine details: $e');
    }
  }

  // Update environment data for a machine
  Future<Map<String, dynamic>> updateEnvironmentData({
    required double temperature,
    required double humidity,
    String? vendingMachineId, // Made optional
  }) async {
    try {
      // We don't need vendingMachineId anymore since we'll be using a single machine
      final response = await http.post(
        Uri.parse('$baseUrl/hardware/environment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'temperature': temperature,
          'humidity': humidity,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error updating environment data');
      }
    } catch (e) {
      throw Exception('Error updating environment data: $e');
    }
  }

  // Register a new vending machine
  Future<Map<String, dynamic>> registerMachine({
    String? vendingMachineId, // Made optional
    String? name,
    String? location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hardware/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          // No need to send vendingMachineId anymore
          'name': name,
          'location': location,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error registering vending machine');
      }
    } catch (e) {
      throw Exception('Error registering vending machine: $e');
    }
  }

  // Update vending machine status
  Future<Map<String, dynamic>> updateMachineStatus({
    String? vendingMachineId, // Made optional
    String? status,
    double? temperature,
    double? humidity,
  }) async {
    try {
      // Use a simple endpoint without machine ID since we only have one machine
      final response = await http.put(
        Uri.parse('$baseUrl/hardware/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'temperature': temperature,
          'humidity': humidity,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Error updating machine status');
      }
    } catch (e) {
      throw Exception('Error updating machine status: $e');
    }
  }

  // Validate RFID card
  Future<Map<String, dynamic>> validateRfidCard(String rfidUid,
      [String? vendingMachineId]) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hardware/auth/rfid'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rfidUID': rfidUid,
          // vendingMachineId is no longer needed
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error validating RFID card');
      }
    } catch (e) {
      throw Exception('Error validating RFID card: $e');
    }
  }
}
