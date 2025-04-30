import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double get totalPrice => product.price * quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}
