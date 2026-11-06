import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme/app_theme.dart';
import 'core/config.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';

/// Top-level background message handler — MUST be a top-level function (not a closure)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized when this is called
  // No UI updates here — just log or store locally
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // Initialize API service (Dio)
  apiService.initialize();

  // Register FCM background message handler BEFORE app launches
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Push Notification Service safely (Firebase Core + FCM + local notifications)
  await notificationService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  ErrorWidget.builder = (FlutterErrorDetails details) {
    final errStr = details.exceptionAsString().toLowerCase();
    final isAuthError = errStr.contains('expired') ||
        errStr.contains('token') ||
        errStr.contains('401') ||
        errStr.contains('unauthorized');

    if (isAuthError) {
      // Clean up stale session credentials
      Supabase.instance.client.auth.signOut().catchError((_) {});
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isAuthError ? const Color(0xFFC89B3C) : AppColors.primary).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAuthError ? Icons.lock_clock_rounded : Icons.info_outline_rounded,
                    color: isAuthError ? const Color(0xFF8A6516) : AppColors.primary,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isAuthError ? 'Session Expired' : 'Screen Notice',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isAuthError
                      ? 'Your artisan session has timed out. Please sign in again to sync your orders and store.'
                      : 'A temporary display glitch occurred. Tap below to refresh your view.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(isAuthError ? Icons.login_rounded : Icons.refresh_rounded, size: 18),
                  label: Text(
                    isAuthError ? 'Sign In Again' : 'Reload Screen',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Navigate cleanly to SplashScreen to reload state
                    runApp(const ProviderScope(child: SheeshApp()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: SheeshApp(),
    ),
  );
}

class SheeshApp extends ConsumerWidget {
  const SheeshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sheesh — She always could.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
