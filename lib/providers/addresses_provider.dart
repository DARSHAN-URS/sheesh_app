import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class AddressesNotifier extends StateNotifier<AsyncValue<List<SavedAddress>>> {
  AddressesNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    if (!SupabaseService.isLoggedIn) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final data = await apiService.get('/addresses');
      if (data is List) {
        final list = data.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(list);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (_) {
      state = const AsyncValue.data([]);
    }
  }

  Future<SavedAddress?> addAddress({
    required String label,
    required String name,
    required String phone,
    required String street,
    required String city,
    required String postalCode,
    bool isDefault = false,
  }) async {
    try {
      final res = await apiService.post('/addresses', data: {
        'label': label,
        'name': name,
        'phone': phone,
        'street': street,
        'city': city,
        'postal_code': postalCode,
        'is_default': isDefault,
      });
      final newAddr = SavedAddress.fromJson(res as Map<String, dynamic>);
      await fetch();
      return newAddr;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await apiService.delete('/addresses/$addressId');
      await fetch();
    } catch (_) {}
  }
}

final addressesProvider = StateNotifierProvider<AddressesNotifier, AsyncValue<List<SavedAddress>>>((ref) {
  return AddressesNotifier();
});

/// Currently selected delivery address in checkout
final selectedAddressProvider = StateProvider<SavedAddress?>((ref) => null);
