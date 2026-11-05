import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  CartNotifier() : super(const AsyncValue.loading()) {
    fetchCart();
  }

  Future<void> fetchCart() async {
    final token = SupabaseService.accessToken;
    if (token == null || !SupabaseService.isLoggedIn) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/cart');
      if (data is List) {
        final items = data.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(items);
        return;
      } else {
        state = const AsyncValue.data([]);
        return;
      }
    } catch (_) {
      // Fallback: fetch directly from Supabase client
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          final res = await SupabaseService.client
              .from('cart_items')
              .select('*, products(*, product_images(url, sort_order), sellers(id, store_name, upi_id, location, is_verified))')
              .eq('user_id', userId);
          if (res is List) {
            final items = (res as List).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
            state = AsyncValue.data(items);
            return;
          }
        }
      } catch (_) {}
      state = const AsyncValue.data([]);
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
      // Fallback: direct Supabase upsert
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          final existing = await SupabaseService.client
              .from('cart_items')
              .select('id, quantity')
              .eq('user_id', userId)
              .eq('product_id', productId);
          if (existing is List && existing.isNotEmpty) {
            final currentItem = existing.first as Map<String, dynamic>;
            final currentQty = (currentItem['quantity'] as num?)?.toInt() ?? 1;
            await SupabaseService.client
                .from('cart_items')
                .update({'quantity': currentQty + quantity})
                .eq('id', currentItem['id']);
          } else {
            await SupabaseService.client.from('cart_items').insert({
              'user_id': userId,
              'product_id': productId,
              'quantity': quantity,
              if (selectedSize != null) 'selected_size': selectedSize,
              if (selectedColor != null) 'selected_color': selectedColor,
            });
          }
          await fetchCart();
          return;
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      await apiService.put('/cart/$itemId', data: {'quantity': quantity});
    } catch (_) {
      try {
        if (quantity <= 0) {
          await SupabaseService.client.from('cart_items').delete().eq('id', itemId);
        } else {
          await SupabaseService.client.from('cart_items').update({'quantity': quantity}).eq('id', itemId);
        }
      } catch (_) {}
    }
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
  }

  Future<void> removeItem(String itemId) async {
    try {
      await apiService.delete('/cart/$itemId');
    } catch (_) {
      try {
        await SupabaseService.client.from('cart_items').delete().eq('id', itemId);
      } catch (_) {}
    }
    state.whenData((items) {
      state = AsyncValue.data(items.where((i) => i.id != itemId).toList());
    });
  }

  Future<void> removeFromCart(String itemId) => removeItem(itemId);

  Future<void> clearCart() async {
    try {
      await apiService.delete('/cart');
    } catch (_) {
      try {
        final uid = SupabaseService.currentUser?.id;
        if (uid != null) {
          await SupabaseService.client.from('cart_items').delete().eq('user_id', uid);
        }
      } catch (_) {}
    }
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
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          final res = await SupabaseService.client
              .from('wishlists')
              .select('product_id')
              .eq('user_id', userId);
          if (res is List) {
            final ids = res
                .map((e) => (e as Map<String, dynamic>)['product_id'] as String?)
                .where((id) => id != null)
                .cast<String>()
                .toSet();
            state = ids;
          }
        }
      } catch (_) {}
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
      // Direct Supabase fallback
      try {
        final userId = SupabaseService.currentUser?.id;
        if (userId != null) {
          if (isWishlisted) {
            await SupabaseService.client
                .from('wishlists')
                .delete()
                .eq('user_id', userId)
                .eq('product_id', productId);
          } else {
            await SupabaseService.client.from('wishlists').upsert(
              {'user_id': userId, 'product_id': productId},
              onConflict: 'user_id,product_id',
            );
          }
          return;
        }
      } catch (_) {}

      // Revert on complete failure
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
