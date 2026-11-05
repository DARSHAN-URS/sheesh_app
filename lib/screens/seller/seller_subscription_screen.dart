import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../theme/app_theme.dart';
import '../../core/config.dart';
import '../../models/seller.dart';
import '../../providers/auth_provider.dart';
import 'create_store_screen.dart';
import 'seller_main_screen.dart';

class SellerSubscriptionScreen extends ConsumerStatefulWidget {
  final bool isFirstTimeOnboarding;

  const SellerSubscriptionScreen({
    super.key,
    this.isFirstTimeOnboarding = false,
  });

  static Future<void> show(BuildContext context, {bool isFirstTimeOnboarding = false}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SellerSubscriptionScreen(isFirstTimeOnboarding: isFirstTimeOnboarding),
      ),
    );
  }

  @override
  ConsumerState<SellerSubscriptionScreen> createState() => _SellerSubscriptionScreenState();
}

class _SellerSubscriptionScreenState extends ConsumerState<SellerSubscriptionScreen> {
  // Free option is selected by default
  String _selectedPlan = 'free';
  bool _isProcessing = false;
  late Razorpay _razorpay;
  String? _paymentPendingPlan;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final seller = ref.read(authProvider).sellerProfile;
    if (!widget.isFirstTimeOnboarding && seller != null && seller.subscriptionPlan.isNotEmpty) {
      _selectedPlan = seller.subscriptionPlan;
    } else {
      // First option (Free Plan) is selected by default
      _selectedPlan = 'free';
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ─── Razorpay Callbacks ──────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final plan = _paymentPendingPlan ?? _selectedPlan;
    _proceedWithPlan(plan, paymentId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment cancelled or failed (${response.code}). You can retry or continue with the Free Plan.'),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Continue Free',
          textColor: Colors.white,
          onPressed: () => _proceedWithPlan('free'),
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final plan = _paymentPendingPlan ?? _selectedPlan;
    _proceedWithPlan(plan, paymentId: 'wallet_${response.walletName}');
  }

  // ─── Payment Initiation ──────────────────────────────────────────────────

  void _startRazorpayPayment(String planId) {
    setState(() => _isProcessing = true);
    _paymentPendingPlan = planId;

    final auth = ref.read(authProvider);
    final seller = auth.sellerProfile;
    final isPro = planId == 'plan_399';
    final amountInPaise = isPro ? 39900 : 19900;
    final planName = isPro ? 'She-Preneur Pro' : 'Artisan Starter';

    final options = {
      'key': AppConfig.razorpayKeyId,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'Sheesh — Artisan Marketplace',
      'description': '$planName Plan (Monthly Subscription)',
      'prefill': {
        'name': auth.fullName.isNotEmpty ? auth.fullName : (seller?.name ?? 'Artisan'),
        'contact': seller?.phoneNumber.replaceAll('+91', '') ?? '9548269940',
        'email': auth.supabaseUser?.email ?? 'artisan@sheesh.app',
      },
      'theme': {
        'color': isPro ? '#C89B3C' : '#5A1629',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      // Fallback for emulator / environments without native Razorpay checkout
      _showPaymentFallbackDialog(planId, amountInPaise);
    }
  }

  void _showPaymentFallbackDialog(String planId, int amountInPaise) {
    setState(() => _isProcessing = false);
    final isPro = planId == 'plan_399';
    final priceStr = isPro ? '₹399' : '₹199';
    final planName = isPro ? 'She-Preneur Pro' : 'Artisan Starter';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(isPro ? '👑' : '🌟', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Razorpay Gateway ($priceStr)',
              style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Simulate Razorpay payment for $planName?\n\nAmount: $priceStr\nPlatform: 0% Platform Commission guarantee.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _proceedWithPlan('free');
            },
            child: Text('Use Free Plan (₹0)', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPro ? const Color(0xFFC89B3C) : const Color(0xFF5A1629),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _proceedWithPlan(planId, paymentId: 'rzp_sim_${DateTime.now().millisecondsSinceEpoch}');
            },
            child: Text('Simulate Success ✓', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Plan Activation & Routing to Storefront Redesign ────────────────────

  Future<void> _proceedWithPlan(String planId, {String? paymentId}) async {
    setState(() => _isProcessing = true);

    try {
      await ref.read(authProvider.notifier).upgradeSubscription(plan: planId);
      if (!mounted) return;

      final updatedSeller = ref.read(authProvider).sellerProfile;

      String message;
      if (planId == 'plan_399') {
        message = '👑 She-Preneur Pro Active! Unlimited listings & redesign unlocked.';
      } else if (planId == 'plan_199') {
        message = '🌟 Artisan Starter Active! Up to 10 listings & custom storefront unlocked.';
      } else {
        message = 'Free Plan active! You can list up to 2 creations.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate directly into seller dashboard
      ref.read(isSellerModeProvider.notifier).state = true;
      if (widget.isFirstTimeOnboarding) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const SellerMainScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update plan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onBottomActionPressed() {
    if (_selectedPlan == 'free') {
      _proceedWithPlan('free');
    } else {
      _startRazorpayPayment(_selectedPlan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final seller = auth.sellerProfile;
    final currentPlan = seller?.subscriptionPlan ?? 'free';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isFirstTimeOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF261017)),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          widget.isFirstTimeOnboarding ? 'Choose Your Artisan Plan' : 'Artisan Subscription Plans',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF261017),
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isFirstTimeOnboarding)
            TextButton(
              onPressed: () => _proceedWithPlan('free'),
              child: Text(
                'Skip',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8A6B7E),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome / Context Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5A1629), Color(0xFF380C18)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5A1629).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('✨', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isFirstTimeOnboarding
                              ? 'Your Storefront is Created!'
                              : 'Grow Your Artisan Business',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.isFirstTimeOnboarding
                              ? 'Pick a plan to customize your storefront and list your creations.'
                              : 'Current Tier: ${seller?.planDisplayName ?? "Free Plan (₹0)"}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFFEEDCD4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Select a Plan for Your Digital Dukaan',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF261017),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Option 1 (Free) is selected by default. Choose ₹199 or ₹399 to unlock storefront redesign & Razorpay checkout.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6D5262)),
            ),

            const SizedBox(height: 16),

            // ── OPTION 1: Free Plan (₹0) — SELECTED BY DEFAULT ──
            _buildSelectablePlanCard(
              planId: 'free',
              name: 'Free Artisan Plan',
              price: '₹0',
              period: 'Lifetime free',
              badge: 'DEFAULT SELECTION • 0% COMMISSION',
              badgeColor: const Color(0xFF5A1629),
              isSelected: _selectedPlan == 'free',
              isCurrent: currentPlan == 'free' && !widget.isFirstTimeOnboarding,
              features: [
                'List up to 2 products',
                'Standard storefront template',
                'Direct buyer UPI payments (0% platform commission)',
                'Basic order management & WhatsApp chat',
              ],
              disabledFeatures: [
                'Custom brand colors, cover banner & avatar',
                'Home page She-Preneurs spotlight',
              ],
            ),

            const SizedBox(height: 14),

            // ── OPTION 2: ₹199 Plan ──
            _buildSelectablePlanCard(
              planId: 'plan_199',
              name: 'Artisan Starter',
              price: '₹199',
              period: 'per month',
              badge: 'POPULAR CHOICE • RAZORPAY 🌟',
              badgeColor: const Color(0xFF2A7B54),
              isSelected: _selectedPlan == 'plan_199',
              isCurrent: (currentPlan == 'plan_199' || currentPlan == '199') && !widget.isFirstTimeOnboarding,
              features: [
                'List up to 10 handcrafted products',
                'Full storefront redesign (Cover banner, Avatar & 9 Brand Colors)',
                'Permanent custom store link (sheesh.app/store/your-name)',
                'Custom craft story & workshop heritage section',
                'Direct buyer UPI payments (0% platform commission)',
              ],
              disabledFeatures: [
                'Home page She-Preneurs spotlight',
              ],
            ),

            const SizedBox(height: 14),

            // ── OPTION 3: ₹399 Plan ──
            _buildSelectablePlanCard(
              planId: 'plan_399',
              name: 'She-Preneur Pro',
              price: '₹399',
              period: 'per month',
              badge: '👑 FEATURED SHE-PRENEUR • RAZORPAY',
              badgeColor: const Color(0xFFC89B3C),
              isSelected: _selectedPlan == 'plan_399',
              isCurrent: (currentPlan == 'plan_399' || currentPlan == '399') && !widget.isFirstTimeOnboarding,
              highlightBorder: true,
              features: [
                'Unlimited handcrafted product listings',
                'Full storefront redesign (Cover banner, Avatar & Brand colors)',
                '⭐ Featured in "She-Preneurs" on Sheesh Home Page',
                'VIP Gold Verified Artisan Crest',
                'Priority ranking in category and search results',
                'Direct buyer UPI payments (0% platform commission)',
                'Dedicated artisan growth helpline',
              ],
              disabledFeatures: [],
            ),

            const SizedBox(height: 20),

            // Guarantee note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEDCD4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF2A7B54), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '100% of order money goes straight to your UPI. Sheesh charges 0% transaction commission on all plans.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF261017),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Sticky Bottom Action Bar ─────────────────────────────────────────────

  Widget _buildStickyBottomBar() {
    final isFree = _selectedPlan == 'free';
    final is199 = _selectedPlan == 'plan_199';
    final is399 = _selectedPlan == 'plan_399';

    String buttonText;
    String subtext;
    Color buttonColor;
    Color textColor = Colors.white;

    if (isFree) {
      buttonText = 'Continue with Free Plan (₹0) →';
      subtext = '2 product listings • Upgrade anytime';
      buttonColor = const Color(0xFF5A1629);
    } else if (is199) {
      buttonText = 'Pay ₹199 via Razorpay & Redesign 🌟';
      subtext = '10 products + Full Storefront Customization unlocked';
      buttonColor = const Color(0xFF2A7B54);
    } else {
      buttonText = 'Pay ₹399 via Razorpay & Go Pro 👑';
      subtext = 'Unlimited products + Storefront Redesign + Home Page Spotlight';
      buttonColor = const Color(0xFFC89B3C);
      textColor = const Color(0xFF2C1E07);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFree ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
                size: 14,
                color: const Color(0xFF6D5262),
              ),
              const SizedBox(width: 5),
              Text(
                subtext,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D5262),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _isProcessing ? null : _onBottomActionPressed,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      buttonText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Selectable Plan Card Widget ──────────────────────────────────────────

  Widget _buildSelectablePlanCard({
    required String planId,
    required String name,
    required String price,
    required String period,
    required String badge,
    required Color badgeColor,
    required bool isSelected,
    required bool isCurrent,
    required List<String> features,
    required List<String> disabledFeatures,
    bool highlightBorder = false,
  }) {
    final borderColor = isSelected
        ? (planId == 'plan_399'
            ? const Color(0xFFC89B3C)
            : (planId == 'plan_199' ? const Color(0xFF2A7B54) : const Color(0xFF5A1629)))
        : const Color(0xFFEEDCD4);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFDFB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? borderColor.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio selection indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? borderColor : const Color(0xFFBDBDBD),
                      width: 2,
                    ),
                    color: isSelected ? borderColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.montserrat(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: badgeColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE PLAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2A7B54),
                      ),
                    ),
                  )
                else if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SELECTED ✓',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF261017),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: borderColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF8A6B7E)),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 20, color: Color(0xFFF0E4DC)),

            // Enabled Features
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2A7B54), size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF261017),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Disabled Features
            ...disabledFeatures.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFBDBDBD), size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF9E9E9E),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
