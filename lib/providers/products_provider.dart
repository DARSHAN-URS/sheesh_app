import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/seller.dart';
import '../services/api_service.dart';

// ─── Categories ───────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final data = await apiService.get('/categories') as List<dynamic>;
  return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
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
  final data = await apiService.get('/products/featured') as List<dynamic>;
  return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
});

// Single product detail
final productDetailProvider = FutureProvider.family<Product?, String>((ref, id) async {
  try {
    final data = await apiService.get('/products/$id');
    return Product.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

// ─── Sellers ──────────────────────────────────────────────────────────────────

final featuredSellersProvider = FutureProvider<List<Seller>>((ref) async {
  final data = await apiService.get('/sellers', params: {'is_featured': true}) as List<dynamic>;
  return data.map((e) => Seller.fromJson(e as Map<String, dynamic>)).toList();
});

final sellerDetailProvider = FutureProvider.family<Seller?, String>((ref, id) async {
  try {
    final data = await apiService.get('/sellers/$id');
    return Seller.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

final sellerProductsProvider = FutureProvider.family<List<Product>, String>((ref, sellerId) async {
  final data = await apiService.get('/sellers/$sellerId/products') as List<dynamic>;
  return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
});

// ─── Search ───────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final data = await apiService.get('/products', params: {'search': query}) as Map<String, dynamic>;
  final list = data['data'] as List<dynamic>;
  return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
});
