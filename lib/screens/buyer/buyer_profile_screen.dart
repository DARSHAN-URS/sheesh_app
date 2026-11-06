import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'order_tracking_screen.dart';
import 'store_map_screen.dart';
import 'dart:io';
import '../auth/login_screen.dart';
import '../../models/seller.dart';
import '../seller/create_store_screen.dart';
import '../seller/seller_onboarding_screen.dart';
import '../seller/edit_store_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/network_image_fallback.dart';
import '../../widgets/store_photo_picker_sheet.dart';
import '../../providers/addresses_provider.dart';
import '../../widgets/addresses_manager_sheet.dart';
import '../../services/storage_service.dart';
import '../../utils/share_helper.dart';
import '../legal/privacy_policy_screen.dart';

/// Provider to allow child screens (like Profile) to switch tabs in BuyerMainScreen
final buyerTabIndexProvider = StateProvider<int>((ref) => 0);

class BuyerProfileScreen extends ConsumerWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final orders = ref.watch(ordersProvider).value ?? [];
    final wishlist = ref.watch(wishlistProvider);
    final cartItems = ref.watch(cartProvider).value ?? [];
    final addresses = ref.watch(addressesProvider).valueOrNull ?? [];

    final userName = auth.isAuthenticated
        ? (auth.fullName.isNotEmpty ? auth.fullName : 'Valued Shopper')
        : 'Welcome to Sheesh';
    final userEmail = auth.isAuthenticated
        ? (auth.supabaseUser?.email ?? 'Shopper Account')
        : 'Sign in to sync orders & saved artisan pieces';
    final userPhone = auth.isAuthenticated
        ? (auth.supabaseUser?.phone ?? auth.profile?['phone'] ?? '')
        : '';
    final userCity = auth.city;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SheeshAppBar(
        showBackButton: false,
        title: 'My Profile & Account',
        showCart: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // ─── User Profile Card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Interactive Avatar with Camera Edit Badge
                      GestureDetector(
                        onTap: () => _showMediaAvatarPicker(context, ref, auth),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.22),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                                    ? NetworkImageFallback(
                                        imageUrl: auth.avatarUrl!,
                                        width: 68,
                                        height: 68,
                                        fit: BoxFit.cover,
                                        fallbackIcon: Center(
                                          child: Text(
                                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                            style: GoogleFonts.poppins(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                          style: GoogleFonts.poppins(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 16, color: AppColors.primary),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (userPhone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                userPhone,
                                style: GoogleFonts.lato(fontSize: 11, color: AppColors.textLight),
                              ),
                            ],
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => AddressesManagerSheet.show(context: context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.goldDark.withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: AppColors.goldDark),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        userCity,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.goldDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: AppColors.goldDark),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),

                  // Edit Profile or Sign In Button
                  if (auth.isAuthenticated)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showEditProfileSheet(context, ref, auth),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: Text(
                          'Sign In or Register 🚀',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Quick Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        count: '${orders.length}',
                        label: 'Orders',
                        icon: Icons.local_shipping_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrdersScreen(showBackButton: true),
                            ),
                          );
                        },
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _buildStatItem(
                        context,
                        count: '${wishlist.length}',
                        label: 'Wishlist',
                        icon: Icons.favorite_border_rounded,
                        onTap: () {
                          ref.read(cartSubTabProvider.notifier).state = 1;
                          ref.read(buyerTabIndexProvider.notifier).state = 2;
                        },
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _buildStatItem(
                        context,
                        count: '${cartItems.length}',
                        label: 'Cart Bag',
                        icon: Icons.shopping_bag_outlined,
                        onTap: () {
                          ref.read(cartSubTabProvider.notifier).state = 0;
                          ref.read(buyerTabIndexProvider.notifier).state = 2;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Artisan Seller Store Profile Card ──────────────────────────────
            if (auth.isSeller)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFDF5), Color(0xFFFFF8E7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.goldDark.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🏪 ARTISAN STORE PROFILE',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Independent from buyer profile',
                          style: GoogleFonts.lato(fontSize: 10, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Store Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: (auth.sellerProfile?.avatarUrl.isNotEmpty ?? false)
                                ? Image.network(
                                    auth.sellerProfile!.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.sellerProfile?.storeName ??
                                    (auth.fullName.isNotEmpty && auth.fullName != 'User'
                                        ? "${auth.fullName}'s Store"
                                        : 'My Artisan Store'),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                auth.sellerProfile?.tagline.isNotEmpty == true
                                    ? auth.sellerProfile!.tagline
                                    : 'Handcrafted Creations',
                                style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldDark,
                              side: const BorderSide(color: AppColors.goldDark),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Text(
                              'Edit Store Profile',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _showEditStoreModal(context, ref, auth.sellerProfile!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.storefront_rounded, size: 16),
                            label: Text(
                              'Store Mode 🏪',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              ref.read(isSellerModeProvider.notifier).state = true;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🌸', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Are you a Moradabad Artisan?',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Open your artisan storefront and sell directly to customers with 0% commission.',
                            style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SellerOnboardingScreen()),
                        );
                      },
                      child: Text(
                        'Become a Seller 🚀',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ─── Account Settings Section ────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                  _buildMenuTile(
                    icon: Icons.explore_rounded,
                    title: 'Moradabad Artisan Map 📍',
                    subtitle: 'Explore stores & workshops in Peetal Mandi, Civil Lines & Sambhal Rd',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StoreMapScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.map_outlined,
                    title: 'Live Order Tracking 🚚',
                    subtitle: 'Track courier GPS transit, live ETA & delivery OTP',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrderTrackingScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'My Orders History',
                    subtitle: orders.isNotEmpty
                        ? '${orders.length} order(s) placed • Tap to view all orders'
                        : 'View past and active orders',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrdersScreen(showBackButton: true),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Saved Creations (Wishlist)',
                    subtitle: '${wishlist.length} item(s) saved in your wishlist',
                    onTap: () {
                      ref.read(cartSubTabProvider.notifier).state = 1;
                      ref.read(buyerTabIndexProvider.notifier).state = 2;
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Addresses (${addresses.length}/5)',
                    subtitle: addresses.isNotEmpty
                        ? addresses.first.formattedAddress
                        : 'Manage up to 5 delivery destinations with PIN code',
                    onTap: () => AddressesManagerSheet.show(context: context),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Artisan Helpdesk & Support',
                    subtitle: 'Customer care & WhatsApp assistance',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support helpline: +91 98765 43210 (Mon-Sat 9 AM - 7 PM)'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.share_rounded,
                    title: 'Share Sheesh App 📲',
                    subtitle: 'Invite friends & family to discover Moradabad artisans',
                    onTap: () => ShareHelper.shareApp(context),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy & Terms 🛡️',
                    subtitle: 'Data protection, user rights & Google Play compliance',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Sheesh Moradabad',
                    subtitle: 'Supporting local Peetal Mandi artisans & heritage',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 20),

            // ─── Sign Out & Delete Account Section ─────────────────────────────
            if (auth.isAuthenticated)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => _confirmSignOut(context, ref),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                        ),
                        title: Text(
                          'Sign Out',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        subtitle: Text(
                          'Safely log out of your Sheesh account',
                          style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                      ListTile(
                        onTap: () => _confirmDeleteAccount(context, ref),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.black54, size: 20),
                        ),
                        title: Text(
                          'Delete Account 🗑️',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Permanently erase your account and personal data',
                          style: GoogleFonts.lato(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                'Sheesh v1.0.0 • Handcrafted in Moradabad',
                style: GoogleFonts.lato(fontSize: 11, color: AppColors.textLight),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String count,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
    );
  }

  Future<void> _pickAvatarFromMedia(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final cloudUrl = await StorageService.uploadImage(
          file: File(image.path),
          folder: 'avatars',
        );
        await ref.read(authProvider.notifier).updateProfile(avatarUrl: cloudUrl);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile picture updated from media! ✓',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF2A7B54),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access media: $e')),
        );
      }
    }
  }

  void _showMediaAvatarPicker(BuildContext context, WidgetRef ref, AuthState auth, {void Function(String newPath)? onAvatarChanged}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change Profile Picture',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Choose a photo from your device media or take a new one',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // Gallery Option
            ListTile(
              onTap: () async {
                Navigator.pop(sheetCtx);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (image != null) {
                  final cloudUrl = await StorageService.uploadImage(
                    file: File(image.path),
                    folder: 'avatars',
                  );
                  if (onAvatarChanged != null) {
                    onAvatarChanged(cloudUrl);
                  } else {
                    await ref.read(authProvider.notifier).updateProfile(avatarUrl: cloudUrl);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile picture updated from gallery! ✓',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF2A7B54),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
              ),
              title: Text(
                'Choose from Gallery / Photos',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'Pick an existing photo from your media',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ),

            const Divider(height: 12, color: AppColors.border),

            // Camera Option
            ListTile(
              onTap: () async {
                Navigator.pop(sheetCtx);
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (image != null) {
                  final cloudUrl = await StorageService.uploadImage(
                    file: File(image.path),
                    folder: 'avatars',
                  );
                  if (onAvatarChanged != null) {
                    onAvatarChanged(cloudUrl);
                  } else {
                    await ref.read(authProvider.notifier).updateProfile(avatarUrl: cloudUrl);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile picture captured from camera! ✓',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: const Color(0xFF2A7B54),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD64438).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD64438), size: 22),
              ),
              title: Text(
                'Take Photo with Camera',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'Snap a new profile picture now',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ),

            // Sheesh Curated Avatar Option
            const Divider(height: 12, color: AppColors.border),
            ListTile(
              onTap: () {
                Navigator.pop(sheetCtx);
                StorePhotoPickerSheet.show(
                  context: context,
                  type: StorePhotoType.avatar,
                  currentUrl: auth.avatarUrl,
                  onSelected: (newUrl) async {
                    if (onAvatarChanged != null) {
                      onAvatarChanged(newUrl);
                    } else {
                      await ref.read(authProvider.notifier).updateProfile(avatarUrl: newUrl);
                    }
                  },
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC89B3C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC89B3C), size: 22),
              ),
              title: Text(
                'Choose Sheesh Artisan Avatar',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'Pick curated heritage portraits or Sheesh emblems',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ),

            // Remove photo if present
            if (auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty) ...[
              const Divider(height: 12, color: AppColors.border),
              ListTile(
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  if (onAvatarChanged != null) {
                    onAvatarChanged('');
                  } else {
                    await ref.read(authProvider.notifier).updateProfile(avatarUrl: '');
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile photo removed.')),
                    );
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                ),
                title: Text(
                  'Remove Profile Photo',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                ),
                subtitle: Text(
                  'Revert to initials avatar',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, AuthState auth) {
    final nameCtrl = TextEditingController(text: auth.fullName == 'User' ? '' : auth.fullName);
    final cityCtrl = TextEditingController(text: auth.city == 'Moradabad, UP' ? '' : auth.city);
    String? currentAvatar = auth.avatarUrl;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile 🛍️',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Update your personal details & profile photo',
                              style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Profile Photo Media Picker Widget (No URL link needed)
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showMediaAvatarPicker(
                              context,
                              ref,
                              auth,
                              onAvatarChanged: (newPath) {
                                setModalState(() => currentAvatar = newPath);
                              },
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.20),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: currentAvatar != null && currentAvatar!.isNotEmpty
                                      ? NetworkImageFallback(
                                          imageUrl: currentAvatar!,
                                          width: 78,
                                          height: 78,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(
                                            nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : 'U',
                                            style: GoogleFonts.poppins(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            _showMediaAvatarPicker(
                              context,
                              ref,
                              auth,
                              onAvatarChanged: (newPath) {
                                setModalState(() => currentAvatar = newPath);
                              },
                            );
                          },
                          icon: const Icon(Icons.photo_library_outlined, size: 15, color: AppColors.primary),
                          label: Text(
                            'Change Photo from Media',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: GoogleFonts.lato(fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: cityCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Shipping City (e.g. Moradabad, UP)',
                      labelStyle: GoogleFonts.lato(fontSize: 13),
                      prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              try {
                                await ref.read(authProvider.notifier).updateProfile(
                                      fullName: nameCtrl.text.trim(),
                                      avatarUrl: currentAvatar,
                                      city: cityCtrl.text.trim(),
                                    );
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated successfully! ✓'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update profile: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                  if (auth.isSeller && auth.sellerProfile != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.storefront_outlined, size: 16, color: AppColors.goldDark),
                        label: Text(
                          'Want to edit your Store Profile instead? Tap here',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.goldDark),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _showEditStoreModal(context, ref, auth.sellerProfile!);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditStoreModal(BuildContext context, WidgetRef ref, Seller seller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditStoreProfileScreen(seller: seller),
      ),
    );
  }

  void _showAddressDialog(BuildContext context, AuthState auth) {
    AddressesManagerSheet.show(context: context);
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.spa_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('About Sheesh', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Sheesh connects discerning buyers across India directly with the historic brass artisans, zardozi needleworkers, and traditional designers of Moradabad, Uttar Pradesh.\n\nEvery order directly supports our artisan community with zero intermediaries.',
          style: GoogleFonts.lato(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text('Delete Account?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.error)),
          ],
        ),
        content: Text(
          'This action is permanent.\n\nAll your personal data, saved delivery addresses, wishlist items, and account settings will be erased immediately in compliance with data privacy policies.\n\nAre you sure you wish to delete your account?',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your account and personal data have been permanently deleted.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              }
            },
            child: Text('Delete Permanently', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBecomeSellerModal(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoreScreen()),
    );
  }
}
