import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/festival_offer.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

final festivalOffersProvider = FutureProvider<List<FestivalOffer>>((ref) async {
  // 1. Try fetching live from Backend API
  try {
    final apiService = ApiService();
    final data = await apiService.get('/banners');
    if (data is List && data.isNotEmpty) {
      return data.map((json) => FestivalOffer.fromJson(json as Map<String, dynamic>)).toList();
    }
  } catch (_) {
    // API call failed or offline, try Supabase directly
  }

  // 2. Try fetching directly from Supabase
  try {
    final client = SupabaseService.client;
    final res = await client
        .from('festival_banners')
        .select('*')
        .eq('is_active', true)
        .order('priority');
    if (res.isNotEmpty) {
      return (res as List).map((json) => FestivalOffer.fromJson(json as Map<String, dynamic>)).toList();
    }
  } catch (_) {
    // Supabase table not created yet or offline
  }

  // 3. Fallback to curated default festival offers
  return FestivalOffer.defaultOffers;
});

