
enum OrderStatus {
  placed,
  confirmed,
  packed,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed by Artisan';
      case OrderStatus.packed:
        return 'Packed with Love';
      case OrderStatus.shipped:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.packed:
        return 2;
      case OrderStatus.shipped:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  static OrderStatus fromString(String? value) {
    switch (value) {
      case 'placed':
        return OrderStatus.placed;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'packed':
        return OrderStatus.packed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.placed;
    }
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String sellerId;
  final String productName;
  final String? productImage;
  final double unitPrice;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.sellerId,
    required this.productName,
    this.productImage,
    required this.unitPrice,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      sellerId: json['seller_id'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      selectedSize: json['selected_size'] as String?,
      selectedColor: json['selected_color'] as String?,
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String buyerId;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double totalAmount;
  final DateTime orderDate;
  OrderStatus status;
  final String paymentMethod; // 'razorpay' or 'cod'
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String deliveryAddress;
  final String customerName;
  final String customerPhone;
  final String? trackingNote;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.deliveryFee = 49,
    required this.totalAmount,
    required this.orderDate,
    this.status = OrderStatus.placed,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.deliveryAddress,
    required this.customerName,
    required this.customerPhone,
    this.trackingNote,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['order_items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      buyerId: json['buyer_id'] as String,
      items: itemsJson.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 49,
      totalAmount: (json['total_amount'] as num).toDouble(),
      orderDate: DateTime.parse(json['created_at'] as String),
      status: OrderStatusExtension.fromString(json['status'] as String?),
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      deliveryAddress: json['delivery_address'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      trackingNote: json['tracking_note'] as String?,
    );
  }
}
