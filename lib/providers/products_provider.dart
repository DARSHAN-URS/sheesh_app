import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/seller.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import 'cart_provider.dart';

// ─── Categories ───────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    final data = await apiService.get('/categories') as List<dynamic>;
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    try {
      final res = await SupabaseService.client.from('categories').select('*').eq('is_active', true).order('sort_order');
      if (res is List) {
        return (res as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
});

// ─── Products ─────────────────────────────────────────────────────────────────

class ProductsFilter {
  final String? categoryId;
  final String? search;
  final String? sellerId;
  final bool? isFeatured;
  final int page;
  final int pageSize;

  const ProductsFilter({
    this.categoryId,
    this.search,
    this.sellerId,
    this.isFeatured,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (categoryId != null) params['category_id'] = categoryId;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (sellerId != null) params['seller_id'] = sellerId;
    if (isFeatured != null) params['is_featured'] = isFeatured;
    return params;
  }
}

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  ProductsFilter _filter = const ProductsFilter();

  Future<void> load({ProductsFilter? filter}) async {
    if (filter != null) _filter = filter;
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/products', params: _filter.toQueryParams());
      final list = (data['data'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      // Fallback: direct Supabase select
      try {
        dynamic query = SupabaseService.client
            .from('products')
            .select('*, product_images(url, sort_order), sellers(id, store_name, location, is_verified, phone_number, upi_id, users(full_name, avatar_url, phone))');
        if (_filter.categoryId != null) {
          query = query.eq('category_id', _filter.categoryId!);
        }
        if (_filter.search != null && _filter.search!.isNotEmpty) {
          query = query.ilike('name', '%${_filter.search}%');
        }
        final res = await query.order('created_at', ascending: false).limit(_filter.pageSize);
        if (res is List) {
          final list = (res as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          state = AsyncValue.data(list);
          return;
        }
      } catch (_) {}
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setFilter({
    String? categoryId,
    String? search,
    bool clearFilters = false,
  }) async {
    _filter = clearFilters
        ? const ProductsFilter()
        : ProductsFilter(
            categoryId: categoryId ?? _filter.categoryId,
            search: search ?? _filter.search,
          );
    await load();
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier();
});

// Featured products for home screen carousel
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final data = await apiService.get('/products/featured');
    if (data is List) {
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  // Direct Supabase fallback
  try {
    final res = await SupabaseService.client
        .from('products')
        .select('*, product_images(url, sort_order), sellers(id, store_name, location, is_verified, phone_number, upi_id, users(full_name, avatar_url, phone))')
        .eq('is_featured', true)
        .limit(10);
    if (res is List && res.isNotEmpty) {
      return (res as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  // Fallback to active catalog
  final all = ref.watch(productsProvider).valueOrNull ?? [];
  return all.take(10).toList();
});

// Single product detail
final productDetailProvider = FutureProvider.family<Product?, String>((ref, id) async {
  if (id.isEmpty) return null;
  try {
    final data = await apiService.get('/products/$id');
    return Product.fromJson(data as Map<String, dynamic>);
  } catch (_) {}

  // Direct Supabase fallback
  try {
    final res = await SupabaseService.client
        .from('products')
        .select('*, product_images(url, sort_order), sellers(id, store_name, location, is_verified, phone_number, upi_id, users(full_name, avatar_url, phone))')
        .eq('id', id)
        .maybeSingle();
    if (res != null) {
      return Product.fromJson(res);
    }
  } catch (_) {}

  // Secondary fallback: check productsProvider cache
  final all = ref.watch(productsProvider).valueOrNull ?? [];
  return all.where((p) => p.id == id).firstOrNull;
});

// ─── Sellers ──────────────────────────────────────────────────────────────────

/// Provides all registered artisan storefronts from backend or Supabase
final allSellersProvider = FutureProvider<List<Seller>>((ref) async {
  try {
    final data = await apiService.get('/sellers');
    if (data is List) {
      final list = data.map((e) => Seller.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isNotEmpty) return list;
    }
  } catch (_) {}

  // Direct Supabase fallback: query sellers table directly
  try {
    final res = await SupabaseService.client
        .from('sellers')
        .select('*, users(full_name, avatar_url, phone)')
        .order('rating', ascending: false);
    if (res is List) {
      return (res as List).map((e) => Seller.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  return [];
});

final featuredSellersProvider = FutureProvider<List<Seller>>((ref) async {
  try {
    final data = await apiService.get('/sellers', params: {'is_featured': true}) as List<dynamic>;
    final list = data.map((e) => Seller.fromJson(e as Map<String, dynamic>)).toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}

  // Direct Supabase fallback
  try {
    final res = await SupabaseService.client
        .from('sellers')
        .select('*, users(full_name, avatar_url, phone)')
        .eq('is_featured', true)
        .order('rating', ascending: false);
    if (res is List && (res as List).isNotEmpty) {
      return (res as List).map((e) => Seller.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  // Fallback to all sellers so explore & home never appear empty
  return await ref.watch(allSellersProvider.future);
});

final sellerDetailProvider = FutureProvider.family<Seller?, String>((ref, id) async {
  if (id.isEmpty) return null;
  try {
    final data = await apiService.get('/sellers/$id');
    return Seller.fromJson(data as Map<String, dynamic>);
  } catch (_) {}

  // Direct Supabase fallback
  try {
    final res = await SupabaseService.client
        .from('sellers')
        .select('*, users(full_name, avatar_url, phone)')
        .eq('id', id)
        .maybeSingle();
    if (res != null) {
      return Seller.fromJson(res);
    }
  } catch (_) {}

  // Check allSellersProvider cache
  final all = ref.watch(allSellersProvider).valueOrNull ?? [];
  return all.where((s) => s.id == id).firstOrNull;
});

final sellerProductsProvider = FutureProvider.family<List<Product>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return [];
  try {
    final data = await apiService.get('/sellers/$sellerId/products');
    if (data is List) {
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  // Direct Supabase fallback
  try {
    final res = await SupabaseService.client
        .from('products')
        .select('*, product_images(url, sort_order), sellers(id, store_name, location, is_verified, phone_number, upi_id, users(full_name, avatar_url, phone))')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    if (res is List) {
      return (res as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  return [];
});

// ─── Search ───────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return [];
  try {
    final data = await apiService.get('/products', params: {'search': query}) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {}

  // Direct Supabase fallback
  try {
    final res = await SupabaseService.client
        .from('products')
        .select('*, product_images(url, sort_order), sellers(store_name, location, is_verified)')
        .ilike('name', '%$query%')
        .limit(30);
    if (res is List && res.isNotEmpty) {
      return (res as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (_) {}

  // In-memory fallback
  final all = ref.watch(productsProvider).valueOrNull ?? [];
  return all.where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.description.toLowerCase().contains(query.toLowerCase())).toList();
});

// ─── Artisan of the Week ──────────────────────────────────────────────────────

final artisanOfTheWeekProvider = FutureProvider<Seller?>((ref) async {
  try {
    final data = await apiService.get('/sellers/artisan-of-the-week');
    if (data is Map<String, dynamic>) {
      return Seller.fromJson(data);
    }
  } catch (_) {}

  // Fallback: pick the top seller from live featured sellers
  try {
    final sellers = await ref.watch(featuredSellersProvider.future);
    if (sellers.isNotEmpty) {
      final sorted = List<Seller>.from(sellers)
        ..sort((a, b) => (b.reviewsCount + (b.weeklyViews)).compareTo(a.reviewsCount + (a.weeklyViews)));
      return sorted.first;
    }
  } catch (_) {}

  return null;
});

// ─── Personalized Products (Previous Searches & Likings) ──────────────────────

class PersonalizedState {
  final List<Product> products;
  final String reason;

  const PersonalizedState({
    required this.products,
    required this.reason,
  });
}

final personalizedProductsProvider = FutureProvider<PersonalizedState>((ref) async {
  final allProductsAsync = ref.watch(productsProvider);
  final allProducts = allProductsAsync.value ?? [];
  if (allProducts.isEmpty) {
    return const PersonalizedState(products: [], reason: 'Curated for you');
  }

  final wishlist = ref.watch(wishlistProvider);
  final prefs = await SharedPreferences.getInstance();
  final recentSearches = prefs.getStringList('sheesh_recent_searches') ?? [];

  List<Product> matched = [];
  String reason = 'Curated for you';

  // 1. Try matching by recent searches
  if (recentSearches.isNotEmpty) {
    for (final rawSearch in recentSearches) {
      final topSearch = rawSearch.toLowerCase().trim();
      final searchTerms = topSearch.split(RegExp(r'\s+')).where((s) => s.length > 2).toList();
      if (searchTerms.isEmpty) continue;

      final searchMatched = allProducts.where((p) {
        final text = '${p.name} ${p.description} ${p.categoryId} ${p.tags.join(" ")}'.toLowerCase();
        return searchTerms.any((term) => text.contains(term));
      }).toList();

      if (searchMatched.isNotEmpty) {
        matched = searchMatched;
        reason = 'Inspired by your search for "$rawSearch"';
        break;
      }
    }
  }

  // 2. If no search match, try matching by wishlist / likings
  if (matched.isEmpty && wishlist.isNotEmpty) {
    final likedProducts = allProducts.where((p) => wishlist.contains(p.id)).toList();
    final likedCategories = likedProducts.map((p) => p.categoryId).toSet();
    final likedTags = likedProducts.expand((p) => p.tags).map((t) => t.toLowerCase()).toSet();

    matched = allProducts.where((p) {
      if (wishlist.contains(p.id)) return false; // Suggest new things, not already saved
      if (likedCategories.contains(p.categoryId)) return true;
      return p.tags.any((t) => likedTags.contains(t.toLowerCase()));
    }).toList();

    if (matched.isNotEmpty) {
      reason = 'Based on your saved artisan crafts';
    }
  }

  // 3. Fallback: diverse random selection across categories
  if (matched.isEmpty) {
    matched = List<Product>.from(allProducts);
    reason = 'Recommended artisan creations for you';
  }

  // Randomize / shuffle the matched items so buyer gets a fresh discovery each time
  final randomized = List<Product>.from(matched)..shuffle();
  final finalProducts = randomized.take(6).toList();

  return PersonalizedState(
    products: finalProducts,
    reason: reason,
  );
});
