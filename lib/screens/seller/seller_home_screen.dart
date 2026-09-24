import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import '../../data/mock_data.dart';
import 'add_product_screen.dart';
import 'seller_orders_screen.dart';

class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final seller = auth.sellerProfile ?? MockData.mockSellers.first;

    final rawOrders = ref.watch(sellerOrdersProvider).value ?? [];
    final sellerOrders = rawOrders.isNotEmpty ? rawOrders : MockData.mockSellerOrders;
    final realSellerId = auth.sellerProfile?.id ?? seller.id;
    final rawProducts = ref.watch(sellerProductsProvider(realSellerId)).value ?? [];
    final sellerProducts = rawProducts.isNotEmpty ? rawProducts : MockData.getProductsForSeller(realSellerId);

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
          if (realSellerId.isNotEmpty) {
            ref.invalidate(sellerProductsProvider(realSellerId));
          }
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

              // Store Analytics & Weekly Sales Chart
              _buildAnalyticsSection(),

              const SizedBox(height: 24),

              // Top Performing Crafts
              _buildTopCraftsSection(),

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
                      'View All (${sellerOrders.length})',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (sellerOrders.isNotEmpty)
                Column(
                  children: sellerOrders.take(3).map((order) {
                    final statusColor = order.status == OrderStatus.delivered
                        ? AppColors.success
                        : (order.status == OrderStatus.shipped
                            ? AppColors.primary
                            : AppColors.goldDark);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order.customerName,
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      order.orderNumber,
                                      style: GoogleFonts.lato(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.status.displayName,
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${order.items.length} item(s): ${order.items.first.productName}',
                            style: GoogleFonts.lato(fontSize: 12, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '₹${order.totalAmount.toInt()}',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: AppColors.textLight)),
                              const SizedBox(width: 8),
                              Text(
                                order.paymentMethod,
                                style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textLight),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        order.deliveryAddress,
                                        style: GoogleFonts.lato(fontSize: 11, color: AppColors.textLight),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
                                  );
                                },
                                child: Text(
                                  'Manage →',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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

  Widget _buildAnalyticsSection() {
    final dailySales = (MockData.mockAnalytics['daily_sales'] as List<dynamic>?) ?? [];
    const maxAmount = 12000.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Store Revenue',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '7-day artisan sales tracker',
                    style: GoogleFonts.lato(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '+18.4% this week',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹48,650',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 8),
              Text(
                '• 32 orders dispatched',
                style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Daily Sales Bar Chart
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailySales.map((item) {
                final day = item['day'] as String;
                final amount = (item['amount'] as num).toDouble();
                final isPeak = day == 'Sat';
                final barHeight = ((amount / maxAmount) * 75).clamp(16.0, 75.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPeak)
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.goldDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Peak',
                              style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Text(
                            '₹${(amount / 1000).toStringAsFixed(1)}k',
                            style: GoogleFonts.lato(fontSize: 8, color: AppColors.textLight),
                          ),
                        const SizedBox(height: 3),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: isPeak
                                ? AppColors.goldGradient
                                : const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [AppColors.primaryLight, AppColors.primary],
                                  ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            boxShadow: isPeak
                                ? [
                                    BoxShadow(
                                      color: AppColors.goldDark.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
                            color: isPeak ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 24),

          // Key Highlights Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(icon: Icons.verified_outlined, color: AppColors.success, label: 'Fulfillment', value: '99.4%'),
              Container(height: 24, width: 1, color: AppColors.border),
              _buildMiniStat(icon: Icons.repeat_rounded, color: const Color(0xFF8E44AD), label: 'Repeat Buyers', value: '42%'),
              Container(height: 24, width: 1, color: AppColors.border),
              _buildMiniStat(icon: Icons.receipt_long_outlined, color: AppColors.primary, label: 'Avg Order', value: '₹2,840'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        Text(label, style: GoogleFonts.lato(fontSize: 10, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildTopCraftsSection() {
    final topCrafts = (MockData.mockAnalytics['top_crafts'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Top Performing Crafts',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                'By units sold',
                style: GoogleFonts.lato(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...topCrafts.asMap().entries.map((entry) {
            final index = entry.key;
            final craft = entry.value as Map<String, dynamic>;
            final rankColors = [AppColors.goldDark, const Color(0xFF7F8C8D), const Color(0xFFCD7F32)];
            final rankBadges = ['🥇 #1', '🥈 #2', '🥉 #3'];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: rankColors[index].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rankBadges[index],
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: rankColors[index]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          craft['name'] as String,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${craft['sales_count']} sold this month',
                          style: GoogleFonts.lato(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(craft['revenue'] as num).toInt()}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
