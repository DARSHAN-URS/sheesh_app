/// App-wide constants and configuration
class AppConfig {
  // ── API ───────────────────────────────────────────────────────
  static const String railwayApiUrl = String.fromEnvironment(
    'RAILWAY_API_URL',
    defaultValue: 'http://localhost:8000', // Change to Railway URL after deploy
  );

  // ── Supabase ──────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  // ── Razorpay ──────────────────────────────────────────────────
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_YOUR_KEY',
  );

  // ── App ───────────────────────────────────────────────────────
  static const String appName = 'Sheesh';
  static const String appTagline = 'She always could.';
  static const String defaultCity = 'Moradabad, UP';

  // Delivery thresholds
  static const double freeDeliveryThreshold = 999.0;
  static const double deliveryFee = 49.0;
  static const double bulkDiscountThreshold = 2000.0;
  static const double bulkDiscountAmount = 150.0;
}
