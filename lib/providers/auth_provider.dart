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

  /// Full name resolved from database profile, Google user metadata, or email fallback
  String get fullName {
    final profileName = profile?['full_name'] as String?;
    if (profileName != null && profileName.trim().isNotEmpty && profileName != 'User') {
      return profileName.trim();
    }
    final meta = supabaseUser?.userMetadata;
    final metaName = (meta?['full_name'] as String?) ?? (meta?['name'] as String?);
    if (metaName != null && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }
    final email = supabaseUser?.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'User';
  }

  /// Avatar URL resolved from database profile or Google account picture
  String? get avatarUrl {
    final profileAvatar = profile?['avatar_url'] as String?;
    if (profileAvatar != null && profileAvatar.trim().isNotEmpty) {
      return profileAvatar.trim();
    }
    final meta = supabaseUser?.userMetadata;
    final metaAvatar = (meta?['avatar_url'] as String?) ?? (meta?['picture'] as String?);
    if (metaAvatar != null && metaAvatar.trim().isNotEmpty) {
      return metaAvatar.trim();
    }
    return null;
  }

  /// Whether current account is authenticated via Google OAuth
  bool get isGoogleUser {
    final appMeta = supabaseUser?.appMetadata;
    final provider = appMeta?['provider'] as String?;
    if (provider == 'google') return true;
    final providers = appMeta?['providers'];
    if (providers is List && providers.contains('google')) return true;
    final meta = supabaseUser?.userMetadata;
    if (meta == null) return false;
    return meta['iss']?.toString().contains('google') == true ||
        meta['picture'] != null;
  }

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
      final profile = Map<String, dynamic>.from(data as Map<String, dynamic>);
      final sellersData = profile['sellers'];
      Seller? seller;
      if (sellersData != null && sellersData is List && sellersData.isNotEmpty) {
        seller = Seller.fromJson(sellersData[0] as Map<String, dynamic>);
      }

      // Check if Google metadata has profile information that needs syncing to database
      final meta = user.userMetadata ?? {};
      final googleName = (meta['full_name'] as String?) ?? (meta['name'] as String?);
      final googleAvatar = (meta['avatar_url'] as String?) ?? (meta['picture'] as String?);

      bool shouldSync = false;
      final updateData = <String, dynamic>{};
      if (googleName != null && googleName.isNotEmpty &&
          (profile['full_name'] == null || profile['full_name'] == '' || profile['full_name'] == 'User')) {
        updateData['full_name'] = googleName;
        profile['full_name'] = googleName;
        shouldSync = true;
      }
      if (googleAvatar != null && googleAvatar.isNotEmpty &&
          (profile['avatar_url'] == null || profile['avatar_url'] == '')) {
        updateData['avatar_url'] = googleAvatar;
        profile['avatar_url'] = googleAvatar;
        shouldSync = true;
      }

      if (shouldSync) {
        // Asynchronously update backend users table so Google info is permanently stored
        apiService.put('/auth/profile', data: updateData).catchError((_) {});
      }

      state = state.copyWith(
        supabaseUser: user,
        profile: profile,
        sellerProfile: seller,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('expired')) {
        try {
          await SupabaseService.signOut();
        } catch (_) {}
        state = const AuthState();
        return;
      }
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

  /// Send OTP to user's email address
  Future<void> sendEmailOtp(String email, {String? fullName}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = (fullName != null && fullName.isNotEmpty) ? {'full_name': fullName} : null;
      await SupabaseService.sendEmailOtp(email, data: data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Verify 6-digit email OTP
  Future<void> verifyEmailOtp(String email, String token, {String? fullName}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.verifyEmailOtp(email: email, token: token);
      if (fullName != null && fullName.isNotEmpty) {
        await updateProfile(fullName: fullName).catchError((_) {});
      }
      // Profile loaded via auth state listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Send OTP to phone number [Legacy]
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

  /// Verify phone OTP [Legacy]
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

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.signInWithGoogle();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AuthState();
  }

  Future<void> sendPasswordReset(String email) async {
    await SupabaseService.client.auth.resetPasswordForEmail(email);
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

  Future<void> updateProfile({
    String? fullName,
    String? city,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final body = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) body['full_name'] = fullName;
      if (city != null && city.isNotEmpty) body['city'] = city;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      final updated = await apiService.put('/auth/profile', data: body);
      final updatedProfile = Map<String, dynamic>.from(state.profile ?? {})
        ..addAll(updated as Map<String, dynamic>);
      state = state.copyWith(profile: updatedProfile, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateSellerProfile({
    String? storeName,
    String? tagline,
    String? bio,
    String? location,
    String? craftStory,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final body = <String, dynamic>{};
      if (storeName != null && storeName.isNotEmpty) body['store_name'] = storeName;
      if (tagline != null && tagline.isNotEmpty) body['tagline'] = tagline;
      if (bio != null && bio.isNotEmpty) body['bio'] = bio;
      if (location != null && location.isNotEmpty) body['location'] = location;
      if (craftStory != null && craftStory.isNotEmpty) body['craft_story'] = craftStory;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      if (coverUrl != null) body['cover_url'] = coverUrl;

      final updated = await apiService.put('/sellers/me', data: body);
      if (updated is Map<String, dynamic>) {
        // If users object not in response, copy from old seller
        final userObj = {'full_name': state.fullName};
        final merged = Map<String, dynamic>.from(updated);
        if (!merged.containsKey('users')) merged['users'] = userObj;
        final updatedSeller = Seller.fromJson(merged);
        state = state.copyWith(sellerProfile: updatedSeller, isLoading: false, clearError: true);
      } else {
        state = state.copyWith(isLoading: false, clearError: true);
      }
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
