import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Fetches list of reviews for a given product ID from GET /reviews/product/{id}
final productReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, productId) async {
  try {
    final data = await apiService.get('/reviews/product/$productId');
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  } catch (_) {
    return [];
  }
});
