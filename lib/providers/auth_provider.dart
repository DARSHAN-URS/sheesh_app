import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';

// ─── Auth User State ──────────────────────────────────────────────────────────

class AuthState {
  final User? supabaseUser;
  final Map<String, dynamic>? profile; // from our users table
  final Seller? sellerProfile;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.supabaseUser,
    this.profile,
    this.sellerProfile,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => supabaseUser != null;
  bool get isSeller => profile?['is_seller'] == true;
  bool get isSellerMode => false; // managed by app mode state
  String get fullName => profile?['full_name'] as String? ?? supabaseUser?.email ?? 'User';
  String get city => profile?['city'] as String? ?? 'Moradabad, UP';

  AuthState copyWith({
    User? supabaseUser,
    Map<String, dynamic>? profile,
    Seller? sellerProfile,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      supabaseUser: clearUser ? null : (supabaseUser ?? this.supabaseUser),
      profile: clearUser ? null : (profile ?? this.profile),
      sellerProfile: clearUser ? null : (sellerProfile ?? this.sellerProfile),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      await _loadProfile(user);
    } else {
      state = const AuthState();
    }

    // Listen for auth state changes
    SupabaseService.authStateChanges.listen((authState) async {
      final user = authState.session?.user;
      if (user != null) {
        await _loadProfile(user);
      } else {
        state = const AuthState();
      }
    });
  }

  Future<void> _loadProfile(User user) async {
    state = state.copyWith(supabaseUser: user, isLoading: true);
    try {
      final data = await apiService.get('/auth/me');
      final profile = data as Map<String, dynamic>;
      final sellersData = profile['sellers'];
      Seller? seller;
      if (sellersData != null && sellersData is List && sellersData.isNotEmpty) {
        seller = Seller.fromJson(sellersData[0] as Map<String, dynamic>);
      }
      state = state.copyWith(
        supabaseUser: user,
        profile: profile,
        sellerProfile: seller,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        supabaseUser: user,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ─── Auth Actions ─────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.signInWithEmail(email: email, password: password);
      // Profile loaded via auth state listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> sendPhoneOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.sendPhoneOtp(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyPhoneOtp(String phone, String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.verifyPhoneOtp(phone: phone, token: token);
      // Profile loaded via auth state listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AuthState();
  }

  Future<void> becomeSeller({
    required String storeName,
    required String tagline,
    required String bio,
    required String location,
    required String categoryId,
    required String phoneNumber,
    required String craftStory,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await apiService.post('/auth/become-seller', data: {
        'store_name': storeName,
        'tagline': tagline,
        'bio': bio,
        'location': location,
        'category_id': categoryId,
        'phone_number': phoneNumber,
        'craft_story': craftStory,
      });
      final seller = Seller.fromJson(result['seller'] as Map<String, dynamic>);
      // Update profile to mark is_seller true
      final updatedProfile = Map<String, dynamic>.from(state.profile ?? {});
      updatedProfile['is_seller'] = true;
      state = state.copyWith(
        sellerProfile: seller,
        profile: updatedProfile,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// App mode provider: true = seller mode, false = buyer mode
final isSellerModeProvider = StateProvider<bool>((ref) => false);
