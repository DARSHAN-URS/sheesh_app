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
  bool get isSeller => (profile?['is_seller'] == true) || (sellerProfile != null);
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

  String get city {
    final raw = profile?['city'] as String?;
    if (raw == null || raw.trim().isEmpty) return 'Moradabad, UP';
    final trimmed = raw.trim();
    // If a full street address was accidentally stored into city, clean it for display
    if (trimmed.length > 22 ||
        trimmed.toLowerCase().contains('road') ||
        trimmed.toLowerCase().contains('pura') ||
        trimmed.toLowerCase().contains('gali') ||
        trimmed.toLowerCase().contains('street') ||
        trimmed.toLowerCase().contains('mandi') ||
        trimmed.toLowerCase().contains('colony') ||
        trimmed.toLowerCase().contains('nagar')) {
      if (trimmed.toLowerCase().contains('moradabad')) {
        return 'Moradabad, UP';
      }
      final parts = trimmed.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]}, ${parts.last}';
      } else if (parts.isNotEmpty) {
        return parts.last;
      }
    }
    return trimmed;
  }

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
  final Ref? _ref;
  AuthNotifier([this._ref]) : super(const AuthState(isLoading: true)) {
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

      // If backend join returned no seller, query Supabase sellers table directly
      if (seller == null) {
        try {
          final sRes = await SupabaseService.client
              .from('sellers')
              .select('*')
              .eq('user_id', user.id)
              .maybeSingle();
          if (sRes != null && sRes is Map<String, dynamic>) {
            final sMap = Map<String, dynamic>.from(sRes);
            if (!sMap.containsKey('users')) {
              sMap['users'] = {'full_name': profile['full_name'] ?? user.userMetadata?['full_name']};
            }
            seller = Seller.fromJson(sMap);
            profile['is_seller'] = true;
          }
        } catch (_) {}
      } else {
        profile['is_seller'] = true;
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
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('401') || errStr.contains('expired') || errStr.contains('token')) {
        try {
          await SupabaseService.signOut();
        } catch (_) {}
        state = const AuthState();
        return;
      }
      // Fallback: load directly from Supabase DB (users + sellers tables)
      try {
        final userRes = await SupabaseService.client
            .from('users')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        final sellerRes = await SupabaseService.client
            .from('sellers')
            .select('*')
            .eq('user_id', user.id)
            .maybeSingle();

        final profile = userRes != null
            ? Map<String, dynamic>.from(userRes)
            : <String, dynamic>{
                'id': user.id,
                'email': user.email,
                'full_name': user.userMetadata?['full_name'] ?? 'User',
              };

        Seller? seller;
        if (sellerRes != null && sellerRes is Map<String, dynamic>) {
          final sMap = Map<String, dynamic>.from(sellerRes);
          if (!sMap.containsKey('users')) {
            sMap['users'] = {'full_name': profile['full_name']};
          }
          seller = Seller.fromJson(sMap);
          profile['is_seller'] = true;
        }

        state = state.copyWith(
          supabaseUser: user,
          profile: profile,
          sellerProfile: seller,
          isLoading: false,
          clearError: true,
        );
        return;
      } catch (_) {}
      // Graceful local offline fallback: use Supabase user metadata
      state = state.copyWith(
        supabaseUser: user,
        profile: <String, dynamic>{
          'id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? 'User',
        },
        isLoading: false,
        clearError: true,
      );
    }
  }

  // ─── Profile Refresh ───────────────────────────────────────────────────────

  Future<void> refreshProfile() async {
    final user = SupabaseService.currentUser ?? state.supabaseUser;
    if (user != null) {
      await _loadProfile(user);
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
    if (_ref != null) {
      _ref!.read(isSellerModeProvider.notifier).state = false;
    }
    state = const AuthState();
  }

  /// Permanently delete user account and wipe personal data (Google Play Store compliance)
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await apiService.delete('/auth/me');
    } catch (_) {
      try {
        final uid = state.supabaseUser?.id;
        if (uid != null) {
          await SupabaseService.client.from('users').delete().eq('id', uid);
        }
      } catch (_) {}
    }
    await signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await SupabaseService.client.auth.resetPasswordForEmail(email);
  }

  Future<void> becomeSeller({
    String? ownerName,
    required String storeName,
    required String tagline,
    required String bio,
    required String location,
    required String categoryId,
    required String phoneNumber,
    required String craftStory,
    String? upiId,
    String? gstNumber,
    String? panNumber,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final currentUserId = state.supabaseUser?.id ?? 'user_current';
    final effectiveOwnerName = (ownerName != null && ownerName.trim().isNotEmpty)
        ? ownerName.trim()
        : state.fullName;
    final fallbackAvatar = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? avatarUrl
        : (state.avatarUrl ?? 'assets/images/sheesh_logo.png');
    final fallbackCover = (coverUrl != null && coverUrl.isNotEmpty)
        ? coverUrl
        : 'assets/images/backgrounds/craft-studio.jpg';

    if (ownerName != null && ownerName.trim().isNotEmpty) {
      String cleanCity = location?.trim() ?? 'Moradabad, UP';
      if (cleanCity.toLowerCase().contains('moradabad')) {
        cleanCity = 'Moradabad, UP';
      } else if (cleanCity.contains(',')) {
        final parts = cleanCity.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          cleanCity = '${parts[parts.length - 2]}, ${parts.last}';
        }
      }
      updateProfile(fullName: ownerName.trim(), city: cleanCity).catchError((_) {});
    }

    // 1. Prepare local Seller entity immediately so UI never fails
    Seller activeSeller = Seller(
      id: state.sellerProfile?.id.isNotEmpty == true && state.sellerProfile!.id != 'seller_current'
          ? state.sellerProfile!.id
          : 'seller_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId,
      name: effectiveOwnerName,
      storeName: storeName,
      tagline: tagline,
      bio: bio,
      avatarUrl: fallbackAvatar,
      coverUrl: fallbackCover,
      location: location,
      categoryId: categoryId,
      rating: 5.0,
      reviewsCount: 0,
      productsCount: 0,
      ordersCompleted: 0,
      isVerified: true,
      isFeatured: false,
      memberSince: '2025',
      responseTime: 'Within 2 hours',
      phoneNumber: phoneNumber,
      craftStory: craftStory,
      upiId: upiId,
      gstNumber: gstNumber,
      panNumber: panNumber,
      subscriptionPlan: 'free',
      weeklyViews: 120,
    );

    // 2. Try Railway Backend API
    final body = <String, dynamic>{
      'store_name': storeName,
      'tagline': tagline,
      'bio': bio,
      'location': location,
      'category_id': categoryId,
      'phone_number': phoneNumber,
      'craft_story': craftStory,
    };
    if (upiId != null && upiId.isNotEmpty) body['upi_id'] = upiId;
    if (gstNumber != null && gstNumber.isNotEmpty) body['gst_number'] = gstNumber;
    if (panNumber != null && panNumber.isNotEmpty) body['pan_number'] = panNumber;
    if (avatarUrl != null && avatarUrl.isNotEmpty) body['avatar_url'] = avatarUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) body['cover_url'] = coverUrl;

    try {
      final result = await apiService.post('/auth/become-seller', data: body);
      final sellerMap = (result is Map && result.containsKey('seller')) ? result['seller'] : result;
      if (sellerMap is Map<String, dynamic>) {
        final merged = Map<String, dynamic>.from(sellerMap);
        if (!merged.containsKey('users')) merged['users'] = {'full_name': state.fullName};
        activeSeller = Seller.fromJson(merged);
      }
    } catch (_) {
      // 3. Fallback: Direct Supabase Upsert
      if (state.supabaseUser != null) {
        try {
          final upsertData = <String, dynamic>{
            'user_id': state.supabaseUser!.id,
            'store_name': storeName,
            'tagline': tagline,
            'bio': bio,
            'location': location,
            'category_id': categoryId,
            'phone_number': phoneNumber,
            'craft_story': craftStory,
            'subscription_plan': 'free',
            'is_featured': false,
          };
          if (upiId != null && upiId.isNotEmpty) upsertData['upi_id'] = upiId;
          if (gstNumber != null && gstNumber.isNotEmpty) upsertData['gst_number'] = gstNumber;
          if (panNumber != null && panNumber.isNotEmpty) upsertData['pan_number'] = panNumber;
          if (avatarUrl != null && avatarUrl.isNotEmpty) upsertData['avatar_url'] = avatarUrl;
          if (coverUrl != null && coverUrl.isNotEmpty) upsertData['cover_url'] = coverUrl;

          final sbRes = await SupabaseService.client
              .from('sellers')
              .upsert(upsertData, onConflict: 'user_id')
              .select()
              .single();

          if (sbRes is Map<String, dynamic>) {
            final merged = Map<String, dynamic>.from(sbRes);
            if (!merged.containsKey('users')) merged['users'] = {'full_name': state.fullName};
            activeSeller = Seller.fromJson(merged);
          }

          await SupabaseService.client
              .from('users')
              .update({'is_seller': true})
              .eq('id', state.supabaseUser!.id)
              .catchError((_) {});
        } catch (_) {}
      }
    }

    final updatedProfile = Map<String, dynamic>.from(state.profile ?? {});
    updatedProfile['is_seller'] = true;
    state = state.copyWith(
      sellerProfile: activeSeller,
      profile: updatedProfile,
      isLoading: false,
      clearError: true,
    );
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
    String? ownerName,
    String? storeName,
    String? tagline,
    String? bio,
    String? location,
    String? craftStory,
    String? avatarUrl,
    String? coverUrl,
    String? upiId,
    String? gstNumber,
    String? panNumber,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final cur = state.sellerProfile;
    final currentUserId = state.supabaseUser?.id ?? cur?.userId ?? 'user_current';
    final effectiveOwnerName = (ownerName != null && ownerName.trim().isNotEmpty)
        ? ownerName.trim()
        : (cur?.name ?? state.fullName);

    if (ownerName != null && ownerName.trim().isNotEmpty) {
      String cleanCity = location?.trim() ?? 'Moradabad, UP';
      if (cleanCity.toLowerCase().contains('moradabad')) {
        cleanCity = 'Moradabad, UP';
      } else if (cleanCity.contains(',')) {
        final parts = cleanCity.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          cleanCity = '${parts[parts.length - 2]}, ${parts.last}';
        }
      }
      updateProfile(fullName: ownerName.trim(), city: cleanCity).catchError((_) {});
    }

    // 1. Synthesize updated seller model immediately so UI is always updated instantly
    Seller activeSeller = Seller(
      id: cur?.id.isNotEmpty == true && cur!.id != 'seller_current'
          ? cur.id
          : 'seller_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId,
      name: effectiveOwnerName,
      storeName: storeName ?? cur?.storeName ?? 'My Sheesh Store',
      tagline: tagline ?? cur?.tagline ?? 'Handcrafted with Love in Moradabad',
      bio: bio ?? cur?.bio ?? 'Local Moradabad artisan',
      avatarUrl: avatarUrl ?? cur?.avatarUrl ?? (state.avatarUrl ?? 'assets/images/sheesh_logo.png'),
      coverUrl: coverUrl ?? cur?.coverUrl ?? 'assets/images/backgrounds/craft-studio.jpg',
      location: location ?? cur?.location ?? 'Moradabad, UP',
      categoryId: cur?.categoryId ?? 'brass',
      rating: cur?.rating ?? 5.0,
      reviewsCount: cur?.reviewsCount ?? 0,
      productsCount: cur?.productsCount ?? 0,
      ordersCompleted: cur?.ordersCompleted ?? 0,
      isVerified: cur?.isVerified ?? true,
      isFeatured: cur?.isFeatured ?? false,
      memberSince: cur?.memberSince ?? '2025',
      responseTime: cur?.responseTime ?? 'Within 2 hours',
      phoneNumber: phoneNumber ?? (cur?.phoneNumber.isNotEmpty == true ? cur!.phoneNumber : null) ?? (state.profile?['phone'] as String?) ?? state.supabaseUser?.phone ?? '',
      craftStory: craftStory ?? cur?.craftStory ?? 'Traditional Moradabad crafts.',
      upiId: upiId ?? cur?.upiId,
      gstNumber: gstNumber ?? cur?.gstNumber,
      panNumber: panNumber ?? cur?.panNumber,
      subscriptionPlan: cur?.subscriptionPlan ?? 'free',
      weeklyViews: cur?.weeklyViews ?? 0,
    );

    final body = <String, dynamic>{};
    if (storeName != null && storeName.isNotEmpty) body['store_name'] = storeName;
    if (tagline != null && tagline.isNotEmpty) body['tagline'] = tagline;
    if (bio != null && bio.isNotEmpty) body['bio'] = bio;
    if (location != null && location.isNotEmpty) body['location'] = location;
    if (craftStory != null && craftStory.isNotEmpty) body['craft_story'] = craftStory;
    if (phoneNumber != null && phoneNumber.isNotEmpty) body['phone_number'] = phoneNumber;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (coverUrl != null) body['cover_url'] = coverUrl;
    if (upiId != null) body['upi_id'] = upiId;
    if (gstNumber != null) body['gst_number'] = gstNumber;
    if (panNumber != null) body['pan_number'] = panNumber;

    // 2. Try PUT /sellers/me on Railway backend
    try {
      final updated = await apiService.put('/sellers/me', data: body);
      if (updated is Map<String, dynamic>) {
        final merged = Map<String, dynamic>.from(updated);
        if (!merged.containsKey('users')) merged['users'] = {'full_name': state.fullName};
        activeSeller = Seller.fromJson(merged);
      }
    } catch (_) {
      // 3. Fallback: try POST /auth/become-seller
      final becomeBody = <String, dynamic>{
        'store_name': activeSeller.storeName,
        'tagline': activeSeller.tagline,
        'bio': activeSeller.bio,
        'location': activeSeller.location,
        'category_id': activeSeller.categoryId,
        'phone_number': activeSeller.phoneNumber,
        'craft_story': activeSeller.craftStory,
      };
      if (activeSeller.upiId != null) becomeBody['upi_id'] = activeSeller.upiId;
      if (activeSeller.gstNumber != null) becomeBody['gst_number'] = activeSeller.gstNumber;
      if (activeSeller.panNumber != null) becomeBody['pan_number'] = activeSeller.panNumber;
      if (activeSeller.avatarUrl.isNotEmpty) becomeBody['avatar_url'] = activeSeller.avatarUrl;
      if (activeSeller.coverUrl.isNotEmpty) becomeBody['cover_url'] = activeSeller.coverUrl;

      try {
        final res = await apiService.post('/auth/become-seller', data: becomeBody);
        final sMap = (res is Map && res.containsKey('seller')) ? res['seller'] : res;
        if (sMap is Map<String, dynamic>) {
          final merged = Map<String, dynamic>.from(sMap);
          if (!merged.containsKey('users')) merged['users'] = {'full_name': state.fullName};
          activeSeller = Seller.fromJson(merged);
        }
      } catch (_) {
        // 4. Fallback: Direct Supabase Upsert
        if (state.supabaseUser != null) {
          try {
            final upsertData = <String, dynamic>{
              'user_id': state.supabaseUser!.id,
              'store_name': activeSeller.storeName,
              'tagline': activeSeller.tagline,
              'bio': activeSeller.bio,
              'location': activeSeller.location,
              'category_id': activeSeller.categoryId,
              'phone_number': activeSeller.phoneNumber,
              'craft_story': activeSeller.craftStory,
            };
            if (activeSeller.upiId != null) upsertData['upi_id'] = activeSeller.upiId;
            if (activeSeller.gstNumber != null) upsertData['gst_number'] = activeSeller.gstNumber;
            if (activeSeller.panNumber != null) upsertData['pan_number'] = activeSeller.panNumber;
            if (activeSeller.avatarUrl.isNotEmpty) upsertData['avatar_url'] = activeSeller.avatarUrl;
            if (activeSeller.coverUrl.isNotEmpty) upsertData['cover_url'] = activeSeller.coverUrl;

            final sbRes = await SupabaseService.client
                .from('sellers')
                .upsert(upsertData, onConflict: 'user_id')
                .select()
                .single();
            if (sbRes is Map<String, dynamic>) {
              final merged = Map<String, dynamic>.from(sbRes);
              if (!merged.containsKey('users')) merged['users'] = {'full_name': state.fullName};
              activeSeller = Seller.fromJson(merged);
            }
            await SupabaseService.client
                .from('users')
                .update({'is_seller': true})
                .eq('id', state.supabaseUser!.id)
                .catchError((_) {});
          } catch (_) {}
        }
      }
    }

    final updatedProfile = Map<String, dynamic>.from(state.profile ?? {});
    updatedProfile['is_seller'] = true;
    state = state.copyWith(
      sellerProfile: activeSeller,
      profile: updatedProfile,
      isLoading: false,
      clearError: true,
    );
  }

  Future<void> upgradeSubscription({required String plan}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await apiService.post('/sellers/me/subscription', data: {'plan': plan});
      if (res is Map<String, dynamic>) {
        final userObj = {'full_name': state.fullName};
        final merged = Map<String, dynamic>.from(res);
        if (!merged.containsKey('users')) merged['users'] = userObj;
        final updatedSeller = Seller.fromJson(merged);
        state = state.copyWith(sellerProfile: updatedSeller, isLoading: false, clearError: true);
      } else {
        if (state.sellerProfile != null) {
          final updatedSeller = state.sellerProfile!.copyWith(
            subscriptionPlan: plan,
            isFeatured: plan == 'plan_399',
          );
          state = state.copyWith(sellerProfile: updatedSeller, isLoading: false, clearError: true);
        }
      }
    } catch (e) {
      if (state.sellerProfile != null) {
        final updatedSeller = state.sellerProfile!.copyWith(
          subscriptionPlan: plan,
          isFeatured: plan == 'plan_399',
        );
        state = state.copyWith(sellerProfile: updatedSeller, isLoading: false, clearError: true);
        return;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// App mode provider: true = seller mode, false = buyer mode
final isSellerModeProvider = StateProvider<bool>((ref) => false);
