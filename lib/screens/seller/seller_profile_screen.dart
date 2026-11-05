import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import '../../widgets/store_photo_picker_sheet.dart';
import '../../utils/share_helper.dart';
import '../buyer/seller_storefront_screen.dart';
import 'create_store_screen.dart';
import 'seller_onboarding_screen.dart';
import 'seller_subscription_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../auth/login_screen.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  void _changePhoto(BuildContext context, WidgetRef ref, StorePhotoType type, String currentUrl, Seller seller) {
    if (!seller.canCustomizeStorefront) {
      _showCustomizationLockedDialog(context);
      return;
    }
    StorePhotoPickerSheet.show(
      context: context,
      type: type,
      currentUrl: currentUrl,
      onSelected: (newUrl) async {
        try {
          if (type == StorePhotoType.cover) {
            await ref.read(authProvider.notifier).updateSellerProfile(coverUrl: newUrl);
          } else {
            await ref.read(authProvider.notifier).updateSellerProfile(avatarUrl: newUrl);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  type == StorePhotoType.cover
                      ? 'Store cover banner updated! ✓'
                      : 'Store profile avatar updated! ✓',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFF2A7B54),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update: $e')),
            );
          }
        }
      },
    );
  }

  void _showCustomizationLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎨', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Customization Locked',
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Storefront customization (custom cover banners, avatars & brand styling) is an Artisan Starter (₹199) and She-Preneur Pro (₹399) feature.\n\nUpgrade now to give your Digital Dukaan a distinctive brand identity!',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Maybe Later', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A1629),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              SellerSubscriptionScreen.show(context);
            },
            child: Text('View Plans 🚀', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final seller = auth.sellerProfile ??
        Seller(
          id: 'seller_current',
          userId: auth.supabaseUser?.id ?? 'user_current',
          name: auth.fullName.isNotEmpty && auth.fullName != 'User' ? auth.fullName : 'Artisan',
          storeName: auth.fullName.isNotEmpty && auth.fullName != 'User'
              ? "${auth.fullName}'s Store"
              : 'My Artisan Store',
          tagline: 'Handcrafted Creations',
          bio: '',
          craftStory: '',
          location: auth.city.isNotEmpty && auth.city != 'Moradabad, UP' ? auth.city : '',
          categoryId: 'brass',
          avatarUrl: auth.avatarUrl ?? 'assets/images/sheesh_logo.png',
          coverUrl: 'assets/images/backgrounds/craft-studio.jpg',
          rating: 5.0,
          reviewsCount: 0,
          productsCount: 0,
          ordersCompleted: 0,
          isVerified: true,
          isFeatured: false,
          memberSince: '2025',
          responseTime: 'Within 2 hours',
          phoneNumber: auth.supabaseUser?.phone ?? '',
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SheeshAppBar(
        showBackButton: false,
        title: 'Store Settings & Profile',
        showCart: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Store Cover Banner & Interactive Avatar Card ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5A1629).withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Cover Image with Edit Button
                  Stack(
                    children: [
                      SizedBox(
                        height: 125,
                        width: double.infinity,
                        child: NetworkImageFallback(
                          imageUrl: seller.coverUrl.isNotEmpty
                              ? seller.coverUrl
                              : 'assets/images/backgrounds/craft-studio.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 125,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.40),
                            ],
                          ),
                        ),
                      ),
                      // "Edit Cover" Floating Chip
                      Positioned(
                        top: 10,
                        right: 10,
                        child: InkWell(
                          onTap: () => _changePhoto(context, ref, StorePhotoType.cover, seller.coverUrl, seller),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit Cover',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Avatar & Store Details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -32),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _changePhoto(context, ref, StorePhotoType.avatar, seller.avatarUrl, seller),
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: NetworkImageFallback(
                                      imageUrl: seller.avatarUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _changePhoto(context, ref, StorePhotoType.avatar, seller.avatarUrl, seller),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD64438),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Column(
                            children: [
                              Text(
                                seller.storeName,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Managed by ${seller.name} • ${seller.location}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user_rounded, color: Color(0xFF2A7B54), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified Moradabad Enterprise ✓',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2A7B54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Subscription Plan Tile ──
            _buildActionTile(
              context,
              title: 'Subscription: ${seller.planDisplayName}',
              subtitle: seller.isPlan399
                  ? 'Unlimited listings • Featured in She-Preneurs 👑'
                  : (seller.isPlan199
                      ? '10 listings • Storefront customized 🌟'
                      : '2 listings • Free plan (Tap to upgrade) 🚀'),
              icon: Icons.workspace_premium_rounded,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: seller.isPlan399
                      ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFB8860B)])
                      : (seller.isPlan199
                          ? const LinearGradient(colors: [Color(0xFF5A1629), Color(0xFFD64438)])
                          : null),
                  color: seller.isFreePlan ? Colors.grey.shade200 : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  seller.isPlan399
                      ? '👑 PRO'
                      : (seller.isPlan199 ? 'STARTER' : 'UPGRADE 🚀'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: seller.isFreePlan ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
              onTap: () => SellerSubscriptionScreen.show(context),
            ),

            // ── Storefront Visual Branding Options ──
            _buildActionTile(
              context,
              title: 'Change Store Cover Photo',
              subtitle: 'Select from Sheesh artisan workshops or upload your own',
              icon: Icons.panorama_outlined,
              trailing: !seller.canCustomizeStorefront
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64438).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFD64438)),
                          const SizedBox(width: 4),
                          Text(
                            '₹199+',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD64438),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
              onTap: () => _changePhoto(context, ref, StorePhotoType.cover, seller.coverUrl, seller),
            ),

            _buildActionTile(
              context,
              title: 'Change Store Profile Photo',
              subtitle: 'Pick Sheesh brand crests or upload your custom logo',
              icon: Icons.account_box_outlined,
              trailing: !seller.canCustomizeStorefront
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64438).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFD64438)),
                          const SizedBox(width: 4),
                          Text(
                            '₹199+',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD64438),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
              onTap: () => _changePhoto(context, ref, StorePhotoType.avatar, seller.avatarUrl, seller),
            ),

            _buildActionTile(
              context,
              title: auth.sellerProfile != null ? 'Edit Store Details' : 'Register Store Details',
              subtitle: 'Update store name, brand color, category & craft story',
              icon: Icons.edit_note_rounded,
              onTap: () {
                if (auth.sellerProfile != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateStoreScreen(existingSeller: seller),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SellerOnboardingScreen(),
                    ),
                  );
                }
              },
            ),

            _buildActionTile(
              context,
              title: 'Public Storefront Preview',
              subtitle: 'See how Moradabad buyers see your brand',
              icon: Icons.visibility_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SellerStorefrontScreen(sellerId: seller.id)),
                );
              },
            ),

            _buildActionTile(
              context,
              title: 'Share Store & App Link',
              subtitle: 'Copy link & share your artisan storefront with customers',
              icon: Icons.share_rounded,
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.goldDark),
              onTap: () => ShareHelper.shareStore(context, seller),
            ),

            _buildActionTile(
              context,
              title: 'Direct UPI ID & QR Payments',
              subtitle: (seller.upiId != null && seller.upiId!.isNotEmpty)
                  ? 'Active VPA: ${seller.upiId}'
                  : 'Tap to configure your UPI ID for direct 0% fee payments',
              icon: Icons.qr_code_2_rounded,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (seller.upiId != null && seller.upiId!.isNotEmpty)
                      ? const Color(0xFF2A7B54).withValues(alpha: 0.12)
                      : const Color(0xFFD64438).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (seller.upiId != null && seller.upiId!.isNotEmpty) ? 'READY' : 'SETUP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: (seller.upiId != null && seller.upiId!.isNotEmpty)
                        ? const Color(0xFF2A7B54)
                        : const Color(0xFFD64438),
                  ),
                ),
              ),
              onTap: () => _showUpiSettingsDialog(context, ref, seller),
            ),

            _buildActionTile(
              context,
              title: 'GST & Business Registration',
              subtitle: (seller.gstNumber != null && seller.gstNumber!.isNotEmpty)
                  ? 'GSTIN: ${seller.gstNumber}'
                  : ((seller.panNumber != null && seller.panNumber!.isNotEmpty)
                      ? 'PAN: ${seller.panNumber} • Exempt under ₹20L'
                      : 'Optional • Exempt under Sec 23 CGST Act (Turnover < ₹20L)'),
              icon: Icons.receipt_long_outlined,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (seller.gstNumber != null && seller.gstNumber!.isNotEmpty)
                      ? const Color(0xFF2A7B54).withValues(alpha: 0.12)
                      : const Color(0xFFC89B3C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (seller.gstNumber != null && seller.gstNumber!.isNotEmpty)
                      ? 'GST ADDED'
                      : 'OPTIONAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: (seller.gstNumber != null && seller.gstNumber!.isNotEmpty)
                        ? const Color(0xFF2A7B54)
                        : const Color(0xFF966E1E),
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateStoreScreen(existingSeller: seller),
                  ),
                );
              },
            ),

            _buildActionTile(
              context,
              title: 'Store Operating Location',
              subtitle: seller.location,
              icon: Icons.location_on_outlined,
              onTap: () {},
            ),

            _buildActionTile(
              context,
              title: 'Privacy Policy & Terms 🛡️',
              subtitle: 'Data safety, artisan rights & Google Play compliance',
              icon: Icons.shield_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                );
              },
            ),

            _buildActionTile(
              context,
              title: 'Helpline & Artisan Community Support',
              subtitle: 'Moradabad Women Entrepreneurs Cell',
              icon: Icons.support_agent_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Helpline: +91 800-SHEESH-UP')),
                );
              },
            ),

            const SizedBox(height: 24),

            // Switch to buyer mode shortcut
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
              label: Text(
                'Switch to Buyer Shopping Mode 🛍️',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              onPressed: () {
                ref.read(isSellerModeProvider.notifier).state = false;
              },
            ),

            const SizedBox(height: 12),

            // Sign out
            TextButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              label: Text(
                'Sign Out',
                style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _confirmSignOut(context, ref),
            ),

            // Delete Account (Google Play compliance)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.grey, size: 18),
              label: Text(
                'Delete Account 🗑️',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade700, fontSize: 12),
              ),
              onPressed: () => _confirmDeleteAccount(context, ref),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showUpiSettingsDialog(BuildContext context, WidgetRef ref, Seller seller) {
    final upiCtrl = TextEditingController(text: seller.upiId ?? '');
    bool isSaving = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final currentUpi = upiCtrl.text.trim();
            final hasValidUpi = currentUpi.isNotEmpty && currentUpi.contains('@');

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header Handle
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

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2A7B54), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Store UPI & Payment QR',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Receive direct payments with 0% commission',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textLight),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'UPI ID / Virtual Payment Address (VPA)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: upiCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        setModalState(() {
                          errorText = null;
                        });
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. artisan@oksbi or 9548269940@paytm',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textLight),
                        errorText: errorText,
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF2A7B54), size: 20),
                        suffixIcon: currentUpi.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                                tooltip: 'Copy UPI ID',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: currentUpi));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('UPI ID copied to clipboard!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFFAF3EC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Supported Apps Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3EC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEDCD4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF2A7B54), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Supports Google Pay, PhonePe, Paytm, BHIM & all Indian UPI apps.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF6D5262)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Live Store QR Code Preview
                    if (hasValidUpi) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: NetworkImageFallback(
                                  imageUrl:
                                      'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent('upi://pay?pa=$currentUpi&pn=${Uri.encodeComponent(seller.storeName)}&cu=INR')}',
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                seller.storeName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                currentUpi,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scan with any UPI app to pay directly',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: const Color(0xFF2A7B54),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A1629),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final text = upiCtrl.text.trim();
                                if (text.isNotEmpty && !text.contains('@')) {
                                  setModalState(() {
                                    errorText = 'Please enter a valid UPI VPA (must contain "@", e.g. name@okhdfcbank)';
                                  });
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  await ref.read(authProvider.notifier).updateSellerProfile(
                                        upiId: text.isNotEmpty ? text : '',
                                      );
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          text.isNotEmpty
                                              ? 'UPI ID updated! Buyers can now pay you directly ✓'
                                              : 'UPI ID removed.',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: const Color(0xFF2A7B54),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    errorText = 'Failed to save: $e';
                                  });
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : Text(
                                'Save UPI ID',
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary)),
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your artisan store?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
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
              ref.read(isSellerModeProvider.notifier).state = false;
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
          'This action is permanent.\n\nAll your artisan profile information, products, and account settings will be erased immediately in compliance with data privacy policies.\n\nAre you sure you wish to delete your account?',
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
}
