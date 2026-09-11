import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../buyer/buyer_main_screen.dart';
import '../seller/seller_main_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), _tryNavigate);
    // Fallback: never stay stuck on splash screen for more than 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (!_navigated && mounted) {
        _doNavigate(ref.read(authProvider));
      }
    });
  }

  void _tryNavigate() {
    if (_navigated || !mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isLoading) return; // wait for listener
    _doNavigate(auth);
  }

  void _doNavigate(AuthState auth) {
    if (_navigated || !mounted) return;
    _navigated = true;
    final dest = auth.isAuthenticated
        ? (auth.isSeller ? const SellerMainScreen() : const BuyerMainScreen())
        : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => dest,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!next.isLoading && !_navigated) _doNavigate(next);
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -80, left: -80,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/sheesh_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.spa_rounded, size: 52, color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.easeOutBack)
                      .shimmer(delay: 600.ms, duration: 1200.ms, color: AppColors.goldLight),
                  const SizedBox(height: 24),
                  Text(
                    'Sheesh',
                    style: GoogleFonts.poppins(
                      fontSize: 44, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -1,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, duration: 600.ms),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'She always could. ✨',
                      style: GoogleFonts.lato(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.goldLight, letterSpacing: 0.5,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, duration: 600.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Empowering Women Micro-Entrepreneurs in Moradabad',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
                ],
              ),
            ),
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Column(
                children: [
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldLight),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Crafted for Bharat • v1.0.0',
                    style: GoogleFonts.lato(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
