import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

/// Fetches list of reviews for a given product ID with dual-layer fallback
final productReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, productId) async {
  // 1. Try FastAPI backend
  try {
    final data = await apiService.get('/reviews/product/$productId');
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
  } catch (_) {}

  // 2. Direct Supabase fallback with joined user details
  try {
    final res = await SupabaseService.client
        .from('reviews')
        .select('*, users(full_name, avatar_url, city)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    if (res is List) {
      return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  } catch (_) {
    // 3. Simple select if foreign key join is blocked
    try {
      final res = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      if (res is List) {
        return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
  }

  return [];
});

/// Submit a product review with dual-layer fallback
Future<bool> submitProductReview({
  required String productId,
  required int rating,
  String? orderId,
  String title = '',
  String comment = '',
}) async {
  final payload = {
    'product_id': productId,
    if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
    'rating': rating,
    'title': title,
    'comment': comment,
  };

  // 1. Try FastAPI
  try {
    await apiService.post('/reviews', data: payload);
    return true;
  } catch (_) {}

  // 2. Fallback to Supabase
  try {
    final user = SupabaseService.currentUser;
    if (user != null) {
      payload['user_id'] = user.id;
      await SupabaseService.client
          .from('reviews')
          .upsert(payload, onConflict: 'product_id, user_id');
      return true;
    }
  } catch (_) {}

  return false;
}
