import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import '../buyer/seller_storefront_screen.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final seller = auth.sellerProfile ??
        const Seller(
          id: 'seller_current',
          userId: 'user_current',
          name: 'Artisan',
          storeName: 'My Sheesh Store',
          tagline: 'Handcrafted with Love in Moradabad',
          bio: 'Moradabad local artisan',
          craftStory: 'Traditional Moradabad crafts passed down generations.',
          location: 'Moradabad, UP',
          categoryId: 'brass',
          avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
          coverUrl: 'https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?w=800',
          rating: 5.0,
          reviewsCount: 0,
          productsCount: 0,
          ordersCompleted: 0,
          isVerified: true,
          isFeatured: false,
          memberSince: '2025',
          responseTime: 'Within 2 hours',
          phoneNumber: '+919876543210',
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
            // Store Avatar & Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: NetworkImageFallback(imageUrl: seller.avatarUrl),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    seller.storeName,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Managed by ${seller.name}',
                    style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Moradabad Enterprise ✓',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Storefront Actions
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
              title: 'Payout Bank Account & UPI',
              subtitle: 'State Bank of India (***4819) • Primary',
              icon: Icons.account_balance_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bank account verified for instant daily payouts.')),
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primary),
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
                style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
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
        title: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
      ),
    );
  }
}
