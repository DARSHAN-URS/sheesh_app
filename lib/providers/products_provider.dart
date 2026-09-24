import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/seller.dart';
import '../services/api_service.dart';
import '../data/mock_data.dart';

// ─── Categories ───────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    final data = await apiService.get('/categories') as List<dynamic>;
    final list = data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    return list.isNotEmpty ? list : MockData.mockCategories;
  } catch (_) {
    return MockData.mockCategories;
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

  List<Product> _filterMockProducts(ProductsFilter f) {
    var list = MockData.mockProducts;
    if (f.categoryId != null && f.categoryId!.isNotEmpty) {
      list = list.where((p) => p.categoryId == f.categoryId).toList();
    }
    if (f.sellerId != null && f.sellerId!.isNotEmpty) {
      list = list.where((p) => p.sellerId == f.sellerId).toList();
    }
    if (f.isFeatured == true) {
      list = list.where((p) => p.isFeatured).toList();
    }
    if (f.search != null && f.search!.isNotEmpty) {
      final q = f.search!.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    return list;
  }

  Future<void> load({ProductsFilter? filter}) async {
    if (filter != null) _filter = filter;
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/products', params: _filter.toQueryParams());
      final list = (data['data'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
      } else {
        state = AsyncValue.data(_filterMockProducts(_filter));
      }
    } catch (e, st) {
      final fallback = _filterMockProducts(_filter);
      if (fallback.isNotEmpty) {
        state = AsyncValue.data(fallback);
      } else {
        state = AsyncValue.error(e, st);
      }
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
    final data = await apiService.get('/products/featured') as List<dynamic>;
    final list = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    return list.isNotEmpty ? list : MockData.mockProducts.where((p) => p.isFeatured).toList();
  } catch (_) {
    return MockData.mockProducts.where((p) => p.isFeatured).toList();
  }
});

// Single product detail
final productDetailProvider = FutureProvider.family<Product?, String>((ref, id) async {
  try {
    final data = await apiService.get('/products/$id');
    return Product.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    try {
      return MockData.mockProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return MockData.mockProducts.isNotEmpty ? MockData.mockProducts.first : null;
    }
  }
});

// ─── Sellers ──────────────────────────────────────────────────────────────────

final featuredSellersProvider = FutureProvider<List<Seller>>((ref) async {
  try {
    final data = await apiService.get('/sellers', params: {'is_featured': true}) as List<dynamic>;
    final list = data.map((e) => Seller.fromJson(e as Map<String, dynamic>)).toList();
    return list.isNotEmpty ? list : MockData.mockSellers;
  } catch (_) {
    return MockData.mockSellers;
  }
});

final sellerDetailProvider = FutureProvider.family<Seller?, String>((ref, id) async {
  try {
    final data = await apiService.get('/sellers/$id');
    return Seller.fromJson(data as Map<String, dynamic>);
  } catch (_) {
    try {
      return MockData.mockSellers.firstWhere((s) => s.id == id);
    } catch (_) {
      return MockData.mockSellers.isNotEmpty ? MockData.mockSellers.first : null;
    }
  }
});

final sellerProductsProvider = FutureProvider.family<List<Product>, String>((ref, sellerId) async {
  if (sellerId.isEmpty) return MockData.mockProducts.take(4).toList();
  try {
    final data = await apiService.get('/sellers/$sellerId/products');
    if (data is List && data.isNotEmpty) {
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
    return MockData.getProductsForSeller(sellerId);
  } catch (_) {
    return MockData.getProductsForSeller(sellerId);
  }
});

// ─── Search ───────────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  try {
    final data = await apiService.get('/products', params: {'search': query}) as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    if (list.isNotEmpty) return list;
  } catch (_) {}

  final q = query.toLowerCase();
  return MockData.mockProducts
      .where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q)))
      .toList();
});
