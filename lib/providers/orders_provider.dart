import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../data/mock_data.dart';

// ─── Orders (Buyer) ───────────────────────────────────────────────────────────

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  OrdersNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    final token = SupabaseService.accessToken;
    if (token == null || !SupabaseService.isLoggedIn) {
      state = AsyncValue.data(MockData.mockBuyerOrders);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/orders');
      if (data is List && data.isNotEmpty) {
        final orders = data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(orders);
      } else {
        state = AsyncValue.data(MockData.mockBuyerOrders);
      }
    } catch (_) {
      state = AsyncValue.data(MockData.mockBuyerOrders);
    }
  }

  /// Place a new order. Returns the order + optional Razorpay details.
  Future<Map<String, dynamic>> placeOrder({
    required String deliveryAddress,
    required String customerName,
    required String customerPhone,
    required String paymentMethod, // 'razorpay' or 'cod'
    String? couponCode,
  }) async {
    final payload = <String, dynamic>{
      'delivery_address': deliveryAddress,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
    };
    if (couponCode != null && couponCode.isNotEmpty) {
      payload['coupon_code'] = couponCode;
    }
    final result = await apiService.post('/orders', data: payload);
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

  /// Cancel an order (for buyer)
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await apiService.post('/orders/$orderId/cancel', data: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    await fetch(); // Refresh orders list
  }

  /// Submit a product review
  Future<void> submitReview({
    required String productId,
    required int rating,
    String title = '',
    String comment = '',
    String? orderId,
  }) async {
    await apiService.post('/reviews', data: {
      'product_id': productId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'order_id': ?orderId,
    });
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return OrdersNotifier();
});

// ─── Seller Orders ────────────────────────────────────────────────────────────

final sellerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  try {
    final token = SupabaseService.accessToken;
    if (token == null || !SupabaseService.isLoggedIn) return MockData.mockSellerOrders;
    final data = await apiService.get('/orders/seller');
    if (data is List && data.isNotEmpty) {
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return MockData.mockSellerOrders;
  } catch (_) {
    return MockData.mockSellerOrders;
  }
});

// Seller order status update
class SellerOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  SellerOrdersNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    final token = SupabaseService.accessToken;
    if (token == null || !SupabaseService.isLoggedIn) {
      state = AsyncValue.data(MockData.mockSellerOrders);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/orders/seller');
      if (data is List && data.isNotEmpty) {
        final orders = data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(orders);
      } else {
        state = AsyncValue.data(MockData.mockSellerOrders);
      }
    } catch (_) {
      state = AsyncValue.data(MockData.mockSellerOrders);
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
