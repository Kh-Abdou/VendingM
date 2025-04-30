class ProductModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final bool available;
  
  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity, 
    this.available = true,
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      available: json['available'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'productId': id,
      'quantity': quantity,
      'price': price,
    };
  }
}