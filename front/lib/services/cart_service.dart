import 'api_service.dart';

class CartService {
  final ApiService _apiService;

  CartService(this._apiService);

  Future<Map<String, dynamic>> createCart(
      String clientId, List<Map<String, dynamic>> items) async {
    return await ApiService.post('cart', {
      'clientId': clientId,
      'items': items,
    });
  }

  Future<Map<String, dynamic>> getCartById(String cartId) async {
    return await ApiService.get('cart/$cartId');
  }

  Future<Map<String, dynamic>> updateCart(
      String cartId, List<Map<String, dynamic>> items) async {
    return await ApiService.put('cart/$cartId', {
      'items': items,
    });
  }

  Future<void> deleteCart(String cartId) async {
    await ApiService.delete('cart/$cartId');
  }
}
