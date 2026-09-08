import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

/// Wrapper around Supabase client — centralizes auth and DB operations
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;

  /// Initialize Supabase — call this in main()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  /// Current session JWT token for backend API calls
  static String? get accessToken => auth.currentSession?.accessToken;

  /// Current authenticated user
  static User? get currentUser => auth.currentUser;

  /// Is user logged in
  static bool get isLoggedIn => auth.currentSession != null;

  // ─── Auth Methods ─────────────────────────────────────────────────────────

  /// Sign up with email + password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  /// Sign in with email + password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Send OTP to phone number (Indian format: +91XXXXXXXXXX)
  static Future<void> sendPhoneOtp(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  /// Verify phone OTP
  static Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Sign in with Google OAuth via Supabase
  static Future<bool> signInWithGoogle() async {
    return client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.sheesh://login-callback',
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Stream of auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ─── Storage ──────────────────────────────────────────────────────────────

  /// Upload file to Supabase Storage, returns public URL
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await client.storage.from(bucket).uploadBinary(
      path,
      uint8Bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
