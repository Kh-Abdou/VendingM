import 'package:flutter/foundation.dart';
import '../services/hardware_service.dart';

class HardwareProvider with ChangeNotifier {
  final HardwareService _hardwareService;

  List<dynamic> _machines = [];
  List<dynamic> _environmentData = [];
  bool _isLoading = false;
  String? _error;

  HardwareProvider({required HardwareService hardwareService})
      : _hardwareService = hardwareService;

  List<dynamic> get machines => _machines;
  List<dynamic> get environmentData => _environmentData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllMachines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _machines = await _hardwareService.getAllMachines();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadEnvironmentData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _environmentData = await _hardwareService.getEnvironmentData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getMachineById(String machineId) async {
    try {
      final machine = await _hardwareService.getMachineById(machineId);
      return machine;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateEnvironmentData({
    String? vendingMachineId, // Made optional
    required double temperature,
    required double humidity,
  }) async {
    try {
      await _hardwareService.updateEnvironmentData(
        temperature: temperature,
        humidity: humidity,
      );

      // Refresh environment data after update
      await loadEnvironmentData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get the latest environment data for a specific machine
  Map<String, dynamic>? getLatestEnvironmentForMachine(String machineId) {
    if (_environmentData.isEmpty) return null;

    try {
      final machineData = _environmentData.firstWhere(
        (m) => m['vendingMachineId'] == machineId,
        orElse: () => null,
      );

      return machineData;
    } catch (e) {
      return null;
    }
  }
}
