import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  CartNotifier() : super(const AsyncValue.loading()) {
    fetchCart();
  }

  Future<void> fetchCart() async {
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/cart') as List<dynamic>;
      final items = data.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToCart(
    String productId, {
    int quantity = 1,
    String? selectedSize,
    String? selectedColor,
  }) async {
    try {
      final data = <String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
      };
      if (selectedSize != null) data['selected_size'] = selectedSize;
      if (selectedColor != null) data['selected_color'] = selectedColor;
      await apiService.post('/cart/add', data: data);
      await fetchCart(); // Refresh cart
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      await apiService.put('/cart/$itemId', data: {'quantity': quantity});
      // Optimistic update
      state.whenData((items) {
        if (quantity <= 0) {
          state = AsyncValue.data(items.where((i) => i.id != itemId).toList());
        } else {
          state = AsyncValue.data(
            items.map((i) => i.id == itemId ? (i..quantity = quantity) : i).toList(),
          );
        }
      });
    } catch (e) {
      await fetchCart(); // Revert to server state on error
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await apiService.delete('/cart/$itemId');
      state.whenData((items) {
        state = AsyncValue.data(items.where((i) => i.id != itemId).toList());
      });
    } catch (e) {
      await fetchCart();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    await apiService.delete('/cart');
    state = const AsyncValue.data([]);
  }

  // ─── Computed totals ──────────────────────────────────────────────────────

  double get subtotal => state.value?.fold(0.0, (sum, i) => sum! + i.totalPrice) ?? 0.0;
  double get deliveryFee => (state.value?.isEmpty ?? true) ? 0.0 : (subtotal > 999 ? 0.0 : 49.0);
  double get discount => subtotal > 2000 ? 150.0 : 0.0;
  double get total => subtotal + deliveryFee - discount;
  int get itemCount => state.value?.fold(0, (sum, i) => sum! + i.quantity) ?? 0;
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  return CartNotifier();
});

// ─── Wishlist ─────────────────────────────────────────────────────────────────

class WishlistNotifier extends StateNotifier<Set<String>> {
  WishlistNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiService.get('/wishlist') as List<dynamic>;
      final ids = data.map((e) => (e as Map<String, dynamic>)['product_id'] as String).toSet();
      state = ids;
    } catch (_) {
      // Ignore — user might not be logged in yet
    }
  }

  Future<void> toggle(String productId) async {
    final isWishlisted = state.contains(productId);
    // Optimistic update
    if (isWishlisted) {
      state = Set.from(state)..remove(productId);
    } else {
      state = Set.from(state)..add(productId);
    }

    try {
      if (isWishlisted) {
        await apiService.delete('/wishlist/$productId');
      } else {
        await apiService.post('/wishlist/$productId');
      }
    } catch (_) {
      // Revert on error
      if (isWishlisted) {
        state = Set.from(state)..add(productId);
      } else {
        state = Set.from(state)..remove(productId);
      }
    }
  }

  bool isWishlisted(String productId) => state.contains(productId);
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  return WishlistNotifier();
});
