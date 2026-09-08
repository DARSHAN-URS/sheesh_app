import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import 'add_product_screen.dart';
import 'seller_orders_screen.dart';

class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({super.key});

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

    final sellerOrders = ref.watch(sellerOrdersProvider).value ?? [];
    final sellerProducts = ref.watch(sellerProductsProvider(seller.id)).value ?? [];

    final totalRevenue = sellerOrders
        .where((o) => o.paymentStatus == 'paid')
        .fold<double>(0.0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SheeshAppBar(
        showBackButton: false,
        showCart: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sellerOrdersProvider);
          ref.invalidate(sellerProductsProvider(seller.id));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seller Welcome Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.darkCardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: NetworkImageFallback(imageUrl: seller.avatarUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    seller.storeName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: AppColors.goldLight, size: 16),
                                ],
                              ),
                              Text(
                                'Namaste, ${seller.name}! 🙏',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              Text(
                                '📍 ${seller.location}',
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Revenue (Paid Orders)',
                                style: GoogleFonts.lato(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                              Text(
                                '₹${totalRevenue.toInt()}',
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.goldLight),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.success),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '${sellerOrders.length} orders total',
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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

              // Quick Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Orders',
                      value: '${sellerOrders.length}',
                      subtitle: 'Customer orders',
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'My Creations',
                      value: '${sellerProducts.length}',
                      subtitle: 'Active listings',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Customer Rating',
                      value: '⭐ ${seller.rating}',
                      subtitle: '${seller.reviewsCount} reviews',
                      icon: Icons.star_outline_rounded,
                      color: AppColors.accentTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Response Time',
                      value: seller.responseTime,
                      subtitle: 'Artisan reply',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF8E44AD),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Action Buttons
              Text(
                'Storefront Management',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: Text(
                        'Add New Craft',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddProductScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.goldDark, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.goldDark),
                      label: Text(
                        'Share Store',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.goldDark),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Store link copied: sheesh.in/@${seller.storeName.toLowerCase().replaceAll(' ', '')} 🌟'),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Customer Orders Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Customer Orders',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),

              if (sellerOrders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sellerOrders.first.customerName,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sellerOrders.first.status.displayName,
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sellerOrders.first.items.length} items • ₹${sellerOrders.first.totalAmount.toInt()} • ${sellerOrders.first.paymentMethod}',
                        style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '📍 ${sellerOrders.first.deliveryAddress}',
                              style: GoogleFonts.lato(fontSize: 11, color: AppColors.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
                              );
                            },
                            child: const Text('Update Status →', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No customer orders yet. Share your storefront link to get orders!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.lato(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
