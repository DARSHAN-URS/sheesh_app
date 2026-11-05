import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../screens/buyer/cart_screen.dart';
import '../screens/buyer/search_screen.dart';
import '../screens/seller/seller_onboarding_screen.dart';
import 'sheesh_brand_emblem.dart';

/// The official header badge for Sheesh, displaying the updated app icon
/// with the deep wine gradient, white arch frame, coral star sparkle, and "Sheश".
class HeaderLogoBadge extends StatelessWidget {
  final double size;

  const HeaderLogoBadge({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A1629).withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.asset(
          'assets/images/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/sheesh_logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildVectorBadge(size),
          ),
        ),
      ),
    );
  }

  Widget _buildVectorBadge(double s) {
    return Container(
      width: s,
      height: s,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6E1B31), Color(0xFF45101E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White Arch
          Positioned(
            top: s * 0.12,
            child: SizedBox(
              width: s * 0.72,
              height: s * 0.65,
              child: const CustomPaint(
                painter: SheeshArchPainter(
                  strokeColor: Colors.white,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
          // Top Coral Star Sparkle
          Positioned(
            top: s * 0.18,
            child: SizedBox(
              width: s * 0.18,
              height: s * 0.24,
              child: const CustomPaint(
                painter: StarSparklePainter(
                  color: Color(0xFFD64438),
                ),
              ),
            ),
          ),
          // Wordmark: She in white, श in coral
          Positioned(
            bottom: s * 0.18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'She',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: s * 0.28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'श',
                  style: GoogleFonts.rozhaOne(
                    fontSize: s * 0.28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD64438),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SheeshAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final String? title;
  final bool showSearch;
  final bool showRoleToggle;
  final bool showCart;

  const SheeshAppBar({
    super.key,
    this.showBackButton = false,
    this.title,
    this.showSearch = true,
    this.showRoleToggle = true,
    this.showCart = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSellerMode = ref.watch(isSellerModeProvider);
    final cartItems = ref.watch(cartProvider).value ?? [];
    final cartCount = cartItems.fold<int>(0, (sum, i) => sum + i.quantity);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            )
          else ...[
            // Updated Brand Logo & Wordmark Header
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  const HeaderLogoBadge(size: 38),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'She',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF261017),
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'श',
                            style: GoogleFonts.rozhaOne(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD64438),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'WOMEN CREATE, COMMUNITIES GROW.',
                        style: GoogleFonts.montserrat(
                          fontSize: 8.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: const Color(0xFFD64438),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (title != null) ...[
            if (showBackButton) const SizedBox(width: 4),
            if (!showBackButton) const SizedBox(width: 8),
            Expanded(
              child: Text(
                title!,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),

          // Role Switcher Button — toggle between Buyer and Seller Storefront view
          if (showRoleToggle)
            InkWell(
              onTap: () {
                final auth = ref.read(authProvider);
                if (!isSellerMode) {
                  // If user is accessing the seller side for the 1st time, prompt onboarding & details
                  if (!auth.isSeller && auth.sellerProfile == null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SellerOnboardingScreen()),
                    );
                    return;
                  }
                  ref.read(isSellerModeProvider.notifier).state = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✨ Switched to Seller Storefront View'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ref.read(isSellerModeProvider.notifier).state = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🛍️ Switched to Buyer Shopping View'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSellerMode ? AppColors.goldGradient : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isSellerMode ? AppColors.gold : AppColors.primary).withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSellerMode ? Icons.storefront_rounded : Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSellerMode ? 'Seller Mode' : 'Buyer Mode',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (showSearch) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.search_rounded, size: 22, color: AppColors.textPrimary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
            ),
          ],

          if (showCart && !isSellerMode) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.textPrimary),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
