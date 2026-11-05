import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class AddressesNotifier extends StateNotifier<AsyncValue<List<SavedAddress>>> {
  static const int maxAddresses = 5;

  AddressesNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    if (!SupabaseService.isLoggedIn) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final data = await apiService.get('/addresses');
      if (data is List) {
        final list = data.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
        state = AsyncValue.data(list.take(maxAddresses).toList());
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (_) {
      // Keep existing data on transient network error, or empty list
      if (!state.hasValue) {
        state = const AsyncValue.data([]);
      }
    }
  }

  bool get canAddAddress {
    final current = state.valueOrNull ?? [];
    return current.length < maxAddresses;
  }

  int get remainingAddressSlots {
    final current = state.valueOrNull ?? [];
    return (maxAddresses - current.length).clamp(0, maxAddresses);
  }

  Future<SavedAddress?> addAddress({
    required String label,
    required String name,
    required String phone,
    required String street,
    String? landmark,
    required String city,
    String stateName = 'Uttar Pradesh',
    required String postalCode,
    bool isDefault = false,
  }) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.length >= maxAddresses) {
      throw Exception('Maximum $maxAddresses saved addresses reached. Please delete an address first.');
    }

    try {
      final res = await apiService.post('/addresses', data: {
        'label': label,
        'name': name.trim(),
        'phone': phone.trim(),
        'street': street.trim(),
        if (landmark != null && landmark.trim().isNotEmpty) 'landmark': landmark.trim(),
        'city': city.trim(),
        'state': stateName.trim(),
        'postal_code': postalCode.trim(),
        'is_default': isDefault || currentList.isEmpty,
      });

      final newAddr = SavedAddress.fromJson(res as Map<String, dynamic>);
      await fetch();
      return newAddr;
    } catch (e) {
      // Local optimistic fallback if server error
      final fallbackAddr = SavedAddress(
        id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        name: name.trim(),
        phone: phone.trim(),
        street: street.trim(),
        landmark: landmark?.trim(),
        city: city.trim(),
        state: stateName.trim(),
        postalCode: postalCode.trim(),
        isDefault: isDefault || currentList.isEmpty,
      );
      final updated = [fallbackAddr, ...currentList].take(maxAddresses).toList();
      state = AsyncValue.data(updated);
      return fallbackAddr;
    }
  }

  Future<SavedAddress?> updateAddress({
    required String id,
    required String label,
    required String name,
    required String phone,
    required String street,
    String? landmark,
    required String city,
    String stateName = 'Uttar Pradesh',
    required String postalCode,
    bool isDefault = false,
  }) async {
    try {
      final res = await apiService.put('/addresses/$id', data: {
        'label': label,
        'name': name.trim(),
        'phone': phone.trim(),
        'street': street.trim(),
        'landmark': landmark?.trim(),
        'city': city.trim(),
        'state': stateName.trim(),
        'postal_code': postalCode.trim(),
        'is_default': isDefault,
      });

      final updatedAddr = SavedAddress.fromJson(res as Map<String, dynamic>);
      await fetch();
      return updatedAddr;
    } catch (e) {
      final currentList = state.valueOrNull ?? [];
      final updatedList = currentList.map((a) {
        if (a.id == id) {
          return a.copyWith(
            label: label,
            name: name.trim(),
            phone: phone.trim(),
            street: street.trim(),
            landmark: landmark?.trim(),
            city: city.trim(),
            state: stateName.trim(),
            postalCode: postalCode.trim(),
            isDefault: isDefault,
          );
        }
        return isDefault ? a.copyWith(isDefault: false) : a;
      }).toList();
      state = AsyncValue.data(updatedList);
      return null;
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      await apiService.patch('/addresses/$addressId/default');
      await fetch();
    } catch (_) {
      final currentList = state.valueOrNull ?? [];
      final updated = currentList.map((a) => a.copyWith(isDefault: a.id == addressId)).toList();
      state = AsyncValue.data(updated);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await apiService.delete('/addresses/$addressId');
      await fetch();
    } catch (_) {
      final currentList = state.valueOrNull ?? [];
      final filtered = currentList.where((a) => a.id != addressId).toList();
      if (filtered.isNotEmpty && !filtered.any((a) => a.isDefault)) {
        filtered[0] = filtered[0].copyWith(isDefault: true);
      }
      state = AsyncValue.data(filtered);
    }
  }
}

final addressesProvider = StateNotifierProvider<AddressesNotifier, AsyncValue<List<SavedAddress>>>((ref) {
  return AddressesNotifier();
});

/// Currently selected delivery address in checkout
final selectedAddressProvider = StateProvider<SavedAddress?>((ref) => null);
