import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

// ─── Orders (Buyer) ───────────────────────────────────────────────────────────

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  OrdersNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    final token = SupabaseService.accessToken;
    if (token == null || !SupabaseService.isLoggedIn) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/orders');
      if (data is List) {
        final orders = data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(orders);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      // Direct Supabase fallback
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          final res = await SupabaseService.client
              .from('orders')
              .select('*, order_items(*)')
              .eq('buyer_id', userId)
              .order('created_at', ascending: false);
          if (res is List) {
            final orders = (res as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
            state = AsyncValue.data(orders);
            return;
          }
        }
      } catch (_) {}
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('401') || errStr.contains('expired') || errStr.contains('token')) {
        state = const AsyncValue.data([]);
        return;
      }
      state = AsyncValue.error(e, st);
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
    try {
      await apiService.post('/orders/$orderId/cancel', data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } catch (_) {
      try {
        final updateData = {
          'status': 'cancelled',
          'tracking_note': 'Order cancelled by buyer${reason != null ? ": $reason" : ""}',
        };
        await SupabaseService.client.from('orders').update(updateData).eq('id', orderId);
      } catch (_) {}
    }
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
      if (orderId != null) 'order_id': orderId,
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
    if (token == null || !SupabaseService.isLoggedIn) return [];
    final data = await apiService.get('/orders/seller');
    if (data is List) {
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (_) {
    return [];
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
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/orders/seller');
      if (data is List) {
        final orders = data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(orders);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      // Direct Supabase fallback for seller orders
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          final sellerRes = await SupabaseService.client
              .from('sellers')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();
          if (sellerRes != null && sellerRes['id'] != null) {
            final sellerId = sellerRes['id'] as String;
            final itemsRes = await SupabaseService.client
                .from('order_items')
                .select('order_id')
                .eq('seller_id', sellerId);
            if (itemsRes is List && itemsRes.isNotEmpty) {
              final orderIds = (itemsRes as List).map((i) => i['order_id'] as String).toSet().toList();
              final ordersRes = await SupabaseService.client
                  .from('orders')
                  .select('*, order_items(*)')
                  .inFilter('id', orderIds)
                  .order('created_at', ascending: false);
              if (ordersRes is List) {
                final orders = (ordersRes as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
                state = AsyncValue.data(orders);
                return;
              }
            }
          }
        }
      } catch (_) {}
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('401') || errStr.contains('expired') || errStr.contains('token')) {
        state = const AsyncValue.data([]);
        return;
      }
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
    try {
      await apiService.put('/orders/$orderId/status', data: data);
    } catch (_) {
      try {
        final updateData = <String, dynamic>{'status': newStatus};
        if (trackingNote != null) updateData['tracking_note'] = trackingNote;
        await SupabaseService.client.from('orders').update(updateData).eq('id', orderId);
      } catch (_) {}
    }
    await fetch();
  }
}

final sellerOrdersNotifierProvider =
    StateNotifierProvider<SellerOrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return SellerOrdersNotifier();
});
