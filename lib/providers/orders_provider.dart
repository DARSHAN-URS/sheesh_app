import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/api_service.dart';

// ─── Orders (Buyer) ───────────────────────────────────────────────────────────

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  OrdersNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/orders') as List<dynamic>;
      final orders = data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Place a new order. Returns the order + optional Razorpay details.
  Future<Map<String, dynamic>> placeOrder({
    required String deliveryAddress,
    required String customerName,
    required String customerPhone,
    required String paymentMethod, // 'razorpay' or 'cod'
  }) async {
    final result = await apiService.post('/orders', data: {
      'delivery_address': deliveryAddress,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
    });
    await fetch(); // Refresh orders list
    return result as Map<String, dynamic>;
  }

  /// Verify Razorpay payment after successful checkout
  Future<void> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await apiService.post('/orders/verify-payment', data: {
      'order_id': orderId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    });
    await fetch(); // Refresh
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return OrdersNotifier();
});

// ─── Seller Orders ────────────────────────────────────────────────────────────

final sellerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final data = await apiService.get('/orders/seller') as List<dynamic>;
  return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
});

// Seller order status update
class SellerOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  SellerOrdersNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/orders/seller') as List<dynamic>;
      final orders = data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(
    String orderId,
    String newStatus, {
    String? trackingNote,
  }) async {
    final data = <String, dynamic>{'status': newStatus};
    if (trackingNote != null) data['tracking_note'] = trackingNote;
    await apiService.put('/orders/$orderId/status', data: data);
    await fetch();
  }
}

final sellerOrdersNotifierProvider =
    StateNotifierProvider<SellerOrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return SellerOrdersNotifier();
});
