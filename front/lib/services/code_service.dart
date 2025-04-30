import 'api_service.dart';

class CodeService {
  final ApiService _apiService;

  CodeService(this._apiService);

  Future<Map<String, dynamic>> generateCode(String userId,
      List<Map<String, dynamic>> products, double totalAmount) async {
    return await _apiService.post('code/generate', {
      'userId': userId,
      'products': products,
      'totalAmount': totalAmount,
    });
  }

  Future<Map<String, dynamic>> validateCode(
      String code, String vendingMachineId) async {
    return await _apiService.post('code/validate', {
      'code': code,
      'vendingMachineId': vendingMachineId,
    });
  }
}
