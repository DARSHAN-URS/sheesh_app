import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/sheesh_brand_emblem.dart';
import '../../widgets/botanical_leaves_painter.dart';
import '../buyer/buyer_main_screen.dart';
import '../seller/seller_main_screen.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePassword = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated && !auth.isLoading) {
        _navigateToHome(auth);
      }
    });
  }

  void _navigateToHome(AuthState authState) {
    if (!mounted) return;
    if (authState.isSeller) {
      ref.read(isSellerModeProvider.notifier).state = true;
    } else {
      ref.read(isSellerModeProvider.notifier).state = false;
    }
    final dest = authState.isSeller ? const SellerMainScreen() : const BuyerMainScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dest),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Enter a valid email address');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendEmailOtp(email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
      );
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithEmail(email, password);
      if (!mounted) return;
      _navigateToHome(ref.read(authProvider));
    } catch (e) {
      _showSnack('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      // Google OAuth redirects back and triggers ref.listen in build()
    } catch (e) {
      _showSnack('Google sign-in failed: ${e.toString()}');
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: const Color(0xFFD64438),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFFFFFBF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF2DED6)),
          ),
          title: Text(
            'Reset Password',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFF261017),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address and we\'ll send you a password reset link.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6D5262)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6D5262)),
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFFD64438)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEEDCD4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD64438), width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8A6B7E), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64438),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        return;
                      }
                      setState(() => isSending = true);
                      try {
                        await ref.read(authProvider.notifier).sendPasswordReset(email);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reset link sent to $email'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isSending = false);
                        if (mounted) _showSnack('Failed to send reset email: $e');
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Send Reset Link', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes (e.g. Google OAuth redirect callback)
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !next.isLoading) {
        _navigateToHome(next);
      }
    });

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EC),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // ── Background Warm Canvas Gradient ──
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
                width: 160,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7D8CA).withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(90),
                    bottomRight: Radius.circular(130),
                    bottomLeft: Radius.circular(100),
                  ),
                ),
              ),
            ),

            // ── Top-Right Soft Warm Circle ──
            Positioned(
              top: size.height * 0.12,
              right: -35,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF9DDD1).withValues(alpha: 0.50),
                ),
              ),
            ),

            // ── Subtle Bottom Botanical Leaves Flourish (Watermark) ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.32,
              child: Opacity(
                opacity: 0.30,
                child: CustomPaint(
                  size: Size(size.width, size.height * 0.32),
                  painter: const BotanicalLeavesPainter(),
                ),
              ),
            ),

            // ── Main Content Scroll View ──
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Brand Arch Emblem & Tagline ──
                    Center(
                      child: const SheeshBrandEmblem(
                        scale: 0.68,
                        showTagline: true,
                        animateStar: true,
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),
                    ),

                    const SizedBox(height: 24),

                    // ── Welcome Heading ──
                    Text(
                      'Welcome Back 🙏',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF261017),
                        letterSpacing: -0.3,
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Sign in to support women creators & artisan crafts',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFF6D5262),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 26),

                    // ── Form Surface Card ──
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF0DDD4), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A1521).withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Segmented Switcher: Email OTP / Password ──
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8EDE7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _usePassword = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      decoration: BoxDecoration(
                                        color: !_usePassword ? const Color(0xFFD64438) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(13),
                                        boxShadow: !_usePassword
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFD64438).withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        '✉️  Email OTP',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: !_usePassword ? Colors.white : const Color(0xFF6D5262),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _usePassword = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                      decoration: BoxDecoration(
                                        color: _usePassword ? const Color(0xFFD64438) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(13),
                                        boxShadow: _usePassword
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFD64438).withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        '🔑  Password',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _usePassword ? Colors.white : const Color(0xFF6D5262),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 250.ms),

                          const SizedBox(height: 22),

                          // ── Email Input ──
                          _buildLabel('Email Address'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              color: const Color(0xFF261017),
                            ),
                            decoration: _inputDecoration(
                              hint: 'name@example.com',
                              prefix: const Icon(Icons.mail_outline_rounded, color: Color(0xFFD64438), size: 20),
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                          if (!_usePassword) ...[
                            const SizedBox(height: 8),
                            Text(
                              'We\'ll send a 6-digit verification code to your inbox',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF8A6B7E)),
                            ),
                          ] else ...[
                            const SizedBox(height: 18),

                            _buildLabel('Password'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                color: const Color(0xFF261017),
                              ),
                              decoration: _inputDecoration(
                                hint: 'Enter your password',
                                prefix: const Icon(Icons.lock_outline_rounded, color: Color(0xFFD64438), size: 20),
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF8A6B7E),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ).animate().fadeIn(delay: 350.ms),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFD64438),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD64438),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // ── CTA Submit Button ──
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDE4F44), Color(0xFFC4372F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD64438).withValues(alpha: 0.32),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (_usePassword ? _loginWithEmail : _loginWithEmailOtp),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Text(
                                      _usePassword ? 'Sign In' : 'Send OTP',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 22),

                          // ── Divider ──
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFF0DDD4))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'or continue with',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFFA68D96),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFF0DDD4))),
                            ],
                          ).animate().fadeIn(delay: 450.ms),

                          const SizedBox(height: 18),

                          // ── Google Sign-In Button ──
                          GoogleSignInButton(
                            text: 'Continue with Google',
                            isLoading: _isGoogleLoading,
                            onPressed: _isLoading || _isGoogleLoading ? null : _loginWithGoogle,
                          ).animate().fadeIn(delay: 500.ms),
                        ],
                      ),
                    ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08, end: 0, duration: 500.ms),

                    const SizedBox(height: 24),

                    // ── Create Account Link ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New to Sheesh? ',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF6D5262),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: Text(
                            'Create account',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFD64438),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 550.ms),

                    const SizedBox(height: 20),

                    // ── Development Quick Preview ──
                    if (kDebugMode) ...[
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                side: const BorderSide(color: Color(0xFFD64438)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Color(0xFFD64438)),
                              label: Text(
                                'Explore Buyer View (Dev)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD64438),
                                ),
                              ),
                              onPressed: () {
                                ref.read(isSellerModeProvider.notifier).state = false;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BuyerMainScreen()),
                                );
                              },
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A1422),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
                              label: Text(
                                'View Seller Side 🏪 (Dev)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                ref.read(isSellerModeProvider.notifier).state = true;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SellerMainScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF261017),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFA68D96), fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFFFDFB),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEEDCD4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEEDCD4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD64438), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}
