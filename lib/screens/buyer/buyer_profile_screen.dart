import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import 'cart_screen.dart';
import '../auth/login_screen.dart';
import '../../models/seller.dart';

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

    final userName = auth.fullName.isNotEmpty ? auth.fullName : 'Valued Shopper';
    final userEmail = auth.supabaseUser?.email ?? 'Shopper Account';
    final userPhone = auth.supabaseUser?.phone ?? auth.profile?['phone'] ?? '';
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
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                              ? Image.network(
                                  auth.avatarUrl!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, size: 11, color: AppColors.goldDark),
                                      const SizedBox(width: 4),
                                      Text(
                                        userCity,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.goldDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),

                  // Edit Profile Button
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
                          ref.read(buyerTabIndexProvider.notifier).state = 2;
                        },
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _buildStatItem(
                        context,
                        count: '${wishlist.length}',
                        label: 'Saved',
                        icon: Icons.favorite_border_rounded,
                        onTap: () {
                          ref.read(buyerTabIndexProvider.notifier).state = 2;
                        },
                      ),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _buildStatItem(
                        context,
                        count: '${cartItems.length}',
                        label: 'Cart',
                        icon: Icons.shopping_bag_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
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
                                auth.sellerProfile?.storeName ?? 'My Sheesh Store',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                auth.sellerProfile?.tagline.isNotEmpty == true
                                    ? auth.sellerProfile!.tagline
                                    : 'Handcrafted in Moradabad, UP',
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ref.read(isSellerModeProvider.notifier).state = true;
                          },
                          child: Text(
                            'View Seller Side 🏪',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showBecomeSellerModal(context, ref),
                          child: Text(
                            'Register Store',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
                    icon: Icons.local_shipping_outlined,
                    title: 'My Orders & Tracking',
                    subtitle: 'View live order status & history',
                    onTap: () {
                      ref.read(buyerTabIndexProvider.notifier).state = 2;
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Saved Creations',
                    subtitle: '${wishlist.length} items in wishlist',
                    onTap: () {
                      ref.read(buyerTabIndexProvider.notifier).state = 2;
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                  _buildMenuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Addresses',
                    subtitle: 'Manage saved delivery destinations',
                    onTap: () => _showAddressDialog(context, auth),
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

            // ─── Sign Out Button ─────────────────────────────────────────────
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
                child: ListTile(
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
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, AuthState auth) {
    final nameCtrl = TextEditingController(text: auth.fullName == 'User' ? '' : auth.fullName);
    final avatarCtrl = TextEditingController(text: auth.avatarUrl ?? '');
    final cityCtrl = TextEditingController(text: auth.city == 'Moradabad, UP' ? '' : auth.city);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                              'Edit Buyer Profile 🛍️',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Personal shopping identity (distinct from your store)',
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Buyer Display Name',
                      labelStyle: GoogleFonts.lato(fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: avatarCtrl,
                    decoration: InputDecoration(
                      labelText: 'Personal Profile Photo URL',
                      hintText: 'https://example.com/my-photo.jpg',
                      labelStyle: GoogleFonts.lato(fontSize: 13),
                      prefixIcon: const Icon(Icons.image_outlined, size: 20),
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
                                      avatarUrl: avatarCtrl.text.trim().isNotEmpty
                                          ? avatarCtrl.text.trim()
                                          : null,
                                      city: cityCtrl.text.trim(),
                                    );
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Buyer profile updated successfully! ✓'),
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
                              'Save Buyer Profile',
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
    final storeNameCtrl = TextEditingController(text: seller.storeName);
    final avatarUrlCtrl = TextEditingController(text: seller.avatarUrl);
    final taglineCtrl = TextEditingController(text: seller.tagline);
    final locationCtrl = TextEditingController(text: seller.location);
    final craftStoryCtrl = TextEditingController(text: seller.craftStory.isNotEmpty ? seller.craftStory : seller.bio);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
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
                  'Edit Store Profile 🏪',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Custom branding for your artisan shop (independent from buyer profile)',
                  style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: storeNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Store / Brand Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: avatarUrlCtrl,
                  decoration: InputDecoration(
                    labelText: 'Store Logo / Avatar Image URL',
                    hintText: 'https://example.com/store-logo.jpg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: taglineCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tagline / Motto',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Workshop / Operating Location',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: craftStoryCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Artisan Story / Craft Heritage',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.history_edu_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final sName = storeNameCtrl.text.trim();
                            if (sName.isEmpty) return;
                            setModalState(() => isSaving = true);
                            try {
                              await ref.read(authProvider.notifier).updateSellerProfile(
                                storeName: sName,
                                avatarUrl: avatarUrlCtrl.text.trim(),
                                tagline: taglineCtrl.text.trim(),
                                location: locationCtrl.text.trim(),
                                craftStory: craftStoryCtrl.text.trim(),
                              );
                              if (modalCtx.mounted) Navigator.pop(modalCtx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Store profile updated successfully! ✓'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update: $e'),
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
                            'Save Store Profile',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddressDialog(BuildContext context, AuthState auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Delivery Address',
                  style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.fullName,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Standard Delivery Address\n${auth.city}, Uttar Pradesh',
                          style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Done', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showBecomeSellerModal(BuildContext context, WidgetRef ref) {
    final storeNameCtrl = TextEditingController();
    final taglineCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final craftStoryCtrl = TextEditingController();
    String categoryId = 'brass';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                    Text(
                      'Open Artisan Storefront 🏪',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Join Moradabad’s premier marketplace for authentic crafts.',
                  style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Store Name
                TextField(
                  controller: storeNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Store Name (e.g. Royal Brass Creations)',
                    labelStyle: GoogleFonts.lato(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline
                TextField(
                  controller: taglineCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tagline (e.g. Pure Handcrafted Brassware)',
                    labelStyle: GoogleFonts.lato(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.short_text_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Category dropdown
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: InputDecoration(
                    labelText: 'Primary Craft Category',
                    labelStyle: GoogleFonts.lato(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'brass', child: Text('Brassware & Peetal Mandi')),
                    DropdownMenuItem(value: 'bridal', child: Text('Bridal Wear & Zardozi')),
                    DropdownMenuItem(value: 'jewelry', child: Text('Kundan & Traditional Jewelry')),
                    DropdownMenuItem(value: 'decor', child: Text('Home Decor & Artifacts')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => categoryId = val);
                  },
                ),
                const SizedBox(height: 12),

                // Phone Number
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Business WhatsApp / Contact Number',
                    labelStyle: GoogleFonts.lato(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Craft Story
                TextField(
                  controller: craftStoryCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Artisan Story / Background',
                    labelStyle: GoogleFonts.lato(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (storeNameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a store name')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await ref.read(authProvider.notifier).becomeSeller(
                                    storeName: storeNameCtrl.text.trim(),
                                    tagline: taglineCtrl.text.trim().isNotEmpty
                                        ? taglineCtrl.text.trim()
                                        : 'Handcrafted in Moradabad',
                                    bio: craftStoryCtrl.text.trim().isNotEmpty
                                        ? craftStoryCtrl.text.trim()
                                        : 'Local Moradabad Artisan',
                                    location: 'Moradabad, UP',
                                    categoryId: categoryId,
                                    phoneNumber: phoneCtrl.text.trim().isNotEmpty
                                        ? phoneCtrl.text.trim()
                                        : '+919876543210',
                                    craftStory: craftStoryCtrl.text.trim(),
                                  );

                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Artisan storefront created! Switching to Seller Mode...'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                ref.read(isSellerModeProvider.notifier).state = true;
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to create store: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Launch My Storefront ✨',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
