import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  Product product;
  int quantity;
  final String? selectedSize;
  final String? selectedColor;

  CartItem({
    required this.id,
    required this.productId,
    required this.product,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
  });

  double get totalPrice => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['products'] as Map<String, dynamic>?;
    return CartItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      product: productJson != null
          ? Product.fromJson(productJson)
          : Product(
              id: json['product_id'] as String,
              name: 'Unknown Product',
              description: '',
              price: 0.0,
              categoryId: '',
              sellerId: '',
              imageUrls: [],
              materialOrTechnique: '',
            ),
      quantity: json['quantity'] as int? ?? 1,
      selectedSize: json['selected_size'] as String?,
      selectedColor: json['selected_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    'selected_size': selectedSize,
    'selected_color': selectedColor,
  };
}
