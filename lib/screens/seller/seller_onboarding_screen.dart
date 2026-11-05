import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'create_store_screen.dart';

class OnboardingStep {
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String heroImage;
  final List<String> bulletPoints;

  const OnboardingStep({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.heroImage,
    required this.bulletPoints,
  });
}

class SellerOnboardingScreen extends StatefulWidget {
  const SellerOnboardingScreen({super.key});

  @override
  State<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends State<SellerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      badge: '0% COMMISSION • 100% ARTISAN DIRECT',
      title: 'Keep 100% of Every Sale Directly via UPI',
      subtitle:
          'No middlemen and zero platform deductions. Buyers pay you directly through Google Pay, PhonePe, Paytm or BHIM straight to your account.',
      icon: Icons.currency_rupee_rounded,
      iconBgColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2A7B54),
      heroImage: 'assets/images/backgrounds/craft-studio.jpg',
      bulletPoints: [
        '0% platform commission on every handcrafted creation',
        'Instant payment directly to your personal UPI ID / Bank',
        'Counter QR code for in-person workshop sales',
      ],
    ),
    OnboardingStep(
      badge: 'YOUR DIGITAL DUKAAN',
      title: 'Launch Your Branded Artisan Storefront',
      subtitle:
          'Get a public digital storefront with a custom permanent link (sheesh.app/store/your-name). Showcase your workshop photos, logo & heritage story.',
      icon: Icons.storefront_rounded,
      iconBgColor: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
      heroImage: 'assets/images/backgrounds/pottery-clay.jpg',
      bulletPoints: [
        'Upload your own workshop banner and custom store avatar',
        'Tell your generational Moradabad craft lineage to buyers',
        'Custom permanent link to share on WhatsApp and Instagram',
      ],
    ),
    OnboardingStep(
      badge: 'NATIONWIDE REACH & TRUST',
      title: 'Connect with Art Lovers Across India',
      subtitle:
          'List authentic Moradabad brassware, pottery, zardozi lehengas, or handmade jewelry. Receive instant WhatsApp inquiries directly from buyers.',
      icon: Icons.verified_user_rounded,
      iconBgColor: Color(0xFFFCE4EC),
      iconColor: Color(0xFFC2185B),
      heroImage: 'assets/images/backgrounds/moradabad-brass.jpg',
      bulletPoints: [
        'Verified Moradabad Enterprise badge for immediate buyer trust',
        'Direct WhatsApp chat button on your public storefront',
        'Dedicated artisan helpline & women entrepreneur cell support',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToCreateStore();
    }
  }

  void _goToCreateStore() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CreateStoreScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Navigation Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF261017)),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A1629).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF5A1629), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Sheesh Artisan Program',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5A1629),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _goToCreateStore,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A6B7E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main PageView Slides ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Visual Card
                        Center(
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFEEDCD4)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  step.heroImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: step.iconBgColor,
                                    child: Center(
                                      child: Icon(step.icon, size: 70, color: step.iconColor),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.15),
                                        Colors.black.withValues(alpha: 0.55),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(step.icon, color: step.iconColor, size: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 22),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: step.iconBgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: step.iconColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            step.badge,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: step.iconColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Title
                        Text(
                          step.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF261017),
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          step.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF6D5262),
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bullet Highlights
                        ...step.bulletPoints.map(
                          (bp) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2A7B54),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    bp,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF261017),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Bottom Navigation & Dots Indicator ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? const Color(0xFF5A1629) : const Color(0xFFEEDCD4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A1629),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _onNext,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Create Store Profile 🚀' : 'Next Step →',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (isLast) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Takes less than 2 minutes • No paperwork required',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF8A6B7E)),
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

