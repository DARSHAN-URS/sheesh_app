/// App-wide constants and configuration
class AppConfig {
  // ── API ───────────────────────────────────────────────────────
  // Always connects to the live Railway backend
  static const String railwayApiUrl = 'https://sheesh-production-b745.up.railway.app';

  // ── Supabase ──────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tyfvtsrdrdznvowqdfdd.supabase.co',
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
