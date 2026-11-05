import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sheesh_brand_emblem.dart';
import '../../widgets/botanical_leaves_painter.dart';
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF3EC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    Future.delayed(const Duration(milliseconds: 2400), _tryNavigate);
    // Fallback: never stay stuck on splash screen for more than 4.5 seconds
    Future.delayed(const Duration(milliseconds: 4500), () {
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
    Widget dest;
    if (auth.isAuthenticated) {
      if (auth.isSeller) {
        ref.read(isSellerModeProvider.notifier).state = true;
        dest = const SellerMainScreen();
      } else {
        dest = const BuyerMainScreen();
      }
    } else {
      dest = const LoginScreen();
    }
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

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EC),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // ── Background Warm Gradient & Atmosphere ──
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFAF3EC),
                      Color(0xFFFFFBF7),
                      Color(0xFFFAF1E8),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // ── Top-Left Warm Organic Shape ──
            Positioned(
              top: -30,
              left: -35,
              child: Container(
                width: 170,
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7D8CA).withValues(alpha: 0.60),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(90),
                    bottomRight: Radius.circular(130),
                    bottomLeft: Radius.circular(100),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 900.ms),

            // ── Top-Right Soft Warm Circle ──
            Positioned(
              top: size.height * 0.16,
              right: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF9DDD1).withValues(alpha: 0.55),
                ),
              ),
            ).animate().fadeIn(duration: 900.ms),

            // ── Botanical Foliage Leaves at Bottom ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.44,
              child: CustomPaint(
                size: Size(size.width, size.height * 0.44),
                painter: const BotanicalLeavesPainter(),
              ),
            )
                .animate()
                .fadeIn(duration: 900.ms, curve: Curves.easeOut)
                .slideY(begin: 0.08, end: 0, duration: 900.ms, curve: Curves.easeOutCubic),

            // ── Center Brand Emblem & Typography ──
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.06),
                child: const SheeshBrandEmblem(
                  scale: 1.0,
                  showTagline: true,
                  animateStar: true,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 800.ms)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
