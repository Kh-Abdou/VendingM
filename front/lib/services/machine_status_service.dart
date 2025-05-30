import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class MachineStatusService {
  final String baseUrl;

  MachineStatusService({required this.baseUrl});

  // Get machine status for technicians
  Future<Map<String, dynamic>> getMachineStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/machine-status'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Machine status response: ${response.statusCode}',
          name: 'MachineStatusService');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get machine status: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error getting machine status: $e',
          name: 'MachineStatusService');
      throw Exception('Error getting machine status: $e');
    }
  }

  // Update machine status (technicians only)
  Future<Map<String, dynamic>> updateMachineStatus({
    required String status,
    required String technicianId,
    String? statusMessage,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/machine-status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status,
          'technicianId': technicianId,
          'statusMessage': statusMessage,
        }),
      );

      developer.log('Update machine status response: ${response.statusCode}',
          name: 'MachineStatusService');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Failed to update machine status');
      }
    } catch (e) {
      developer.log('Error updating machine status: $e',
          name: 'MachineStatusService');
      throw Exception('Error updating machine status: $e');
    }
  }

  // Get machine status for client display
  Future<Map<String, dynamic>> getMachineStatusForClient() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/machine-status/client'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Client machine status response: ${response.statusCode}',
          name: 'MachineStatusService');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Return default offline status if request fails
        return {
          'status': 'OFFLINE',
          'isOperational': false,
          'message': 'Unable to get machine status',
          'lastUpdated': null,
        };
      }
    } catch (e) {
      developer.log('Error getting client machine status: $e',
          name: 'MachineStatusService');
      // Return default offline status on error
      return {
        'status': 'OFFLINE',
        'isOperational': false,
        'message': 'Unable to get machine status',
        'lastUpdated': null,
      };
    }
  }

  // Get human-readable status text
  static String getStatusDisplayText(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL':
        return 'Opérationnel';
      case 'MAINTENANCE':
        return 'En maintenance';
      case 'ERROR':
        return 'En panne';
      case 'OFFLINE':
        return 'Hors ligne';
      case 'OUT_OF_SERVICE':
        return 'Hors service';
      case 'NEEDS_RESTOCKING':
        return 'Réapprovisionnement';
      default:
        return 'Statut inconnu';
    }
  }

  // Get status color for UI
  static String getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL':
        return 'green';
      case 'MAINTENANCE':
        return 'orange';
      case 'ERROR':
        return 'red';
      case 'OFFLINE':
        return 'grey';
      case 'OUT_OF_SERVICE':
        return 'red';
      case 'NEEDS_RESTOCKING':
        return 'yellow';
      default:
        return 'grey';
    }
  }
}
