import 'package:flutter/foundation.dart';
import '../services/code_service.dart';
import '../models/cart_item_model.dart';

class CodeProvider with ChangeNotifier {
  final CodeService _codeService;
  final String userId;
  
  String? _generatedCode;
  DateTime? _expiryTime;
  bool _isLoading = false;
  
  CodeProvider({
    required CodeService codeService,
    required this.userId,
  }) : _codeService = codeService;
  
  String? get generatedCode => _generatedCode;
  DateTime? get expiryTime => _expiryTime;
  bool get isLoading => _isLoading;
  
  Future<bool> generateCode(List<CartItemModel> items) async {
    try {
      if (items.isEmpty) return false;
      
      _isLoading = true;
      notifyListeners();
      
      final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      final products = items.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'price': item.product.price,
      }).toList();
      
      final result = await _codeService.generateCode(userId, products, totalAmount);
      
      _generatedCode = result['code'];
      _expiryTime = DateTime.parse(result['expiryTime']);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Failed to generate code: $e');
      return false;
    }
  }
  
  void reset() {
    _generatedCode = null;
    _expiryTime = null;
    notifyListeners();
  }
}