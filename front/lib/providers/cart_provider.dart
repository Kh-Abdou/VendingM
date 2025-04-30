import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService;
  final String userId;

  List<CartItemModel> _items = [];
  String? _cartId;

  CartProvider({
    required CartService cartService,
    required this.userId,
  }) : _cartService = cartService;

  List<CartItemModel> get items => _items;

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount => _items.length;

  void addItem(ProductModel product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        CartItemModel(
          product: product,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
    _syncWithServer();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    _syncWithServer();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
      _syncWithServer();
    }
  }

  void clear() {
    _items = [];
    notifyListeners();
    if (_cartId != null) {
      _cartService.deleteCart(_cartId!);
      _cartId = null;
    }
  }

  Future<void> _syncWithServer() async {
    try {
      final itemsJson = _items.map((item) => item.toJson()).toList();

      if (_cartId == null) {
        final result = await _cartService.createCart(userId, itemsJson);
        _cartId = result['_id'];
      } else {
        await _cartService.updateCart(_cartId!, itemsJson);
      }
    } catch (e) {
      print('Failed to sync cart with server: $e');
    }
  }
}
