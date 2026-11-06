import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/network_image_fallback.dart';
import '../../widgets/product_card.dart';
import '../../utils/whatsapp_helper.dart';
import '../../utils/share_helper.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import 'store_map_screen.dart';

class SellerStorefrontScreen extends ConsumerStatefulWidget {
  final String sellerId;

  const SellerStorefrontScreen({super.key, required this.sellerId});

  @override
  ConsumerState<SellerStorefrontScreen> createState() => _SellerStorefrontScreenState();
}

class _SellerStorefrontScreenState extends ConsumerState<SellerStorefrontScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.sellerId.isNotEmpty && !widget.sellerId.startsWith('seller_current')) {
      apiService.post('/sellers/${widget.sellerId}/view').catchError((_) {});
      SupabaseService.client.rpc('increment_seller_views', params: {'p_seller_id': widget.sellerId}).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _contactArtisanViaWhatsApp(BuildContext context, Seller seller) async {
    String phone = seller.phoneNumber.trim();
    final auth = ref.read(authProvider);

    // If currently logged-in user is viewing their own store, use their active phone
    if (phone.isEmpty && auth.sellerProfile != null &&
        (auth.sellerProfile!.id == seller.id || auth.sellerProfile!.userId == seller.userId)) {
      phone = auth.sellerProfile!.phoneNumber.isNotEmpty
          ? auth.sellerProfile!.phoneNumber
          : (auth.supabaseUser?.phone ?? '');
    }

    // Direct database lookup if phone_number was not populated in memory
    if (phone.isEmpty && seller.id.isNotEmpty) {
      try {
        final res = await SupabaseService.client
            .from('sellers')
            .select('phone_number, users(phone)')
            .eq('id', seller.id)
            .maybeSingle();
        if (res != null) {
          final sPhone = res['phone_number'] as String?;
          final uPhone = (res['users'] as Map?)?['phone'] as String?;
          if (sPhone != null && sPhone.isNotEmpty) {
            phone = sPhone;
          } else if (uPhone != null && uPhone.isNotEmpty) {
            phone = uPhone;
          }
        }
      } catch (_) {}
    }

    if (context.mounted) {
      await WhatsAppHelper.openArtisanChat(
        context: context,
        phoneNumber: phone,
        artisanName: seller.storeName.isNotEmpty ? seller.storeName : seller.name,
      );
    }
  }

  Future<void> _callArtisan(BuildContext context, Seller seller) async {
    String phone = seller.phoneNumber.trim();
    final auth = ref.read(authProvider);

    if (phone.isEmpty && auth.sellerProfile != null &&
        (auth.sellerProfile!.id == seller.id || auth.sellerProfile!.userId == seller.userId)) {
      phone = auth.sellerProfile!.phoneNumber.isNotEmpty
          ? auth.sellerProfile!.phoneNumber
          : (auth.supabaseUser?.phone ?? '');
    }

    if (phone.isEmpty && seller.id.isNotEmpty) {
      try {
        final res = await SupabaseService.client
            .from('sellers')
            .select('phone_number, users(phone)')
            .eq('id', seller.id)
            .maybeSingle();
        if (res != null) {
          final sPhone = res['phone_number'] as String?;
          final uPhone = (res['users'] as Map?)?['phone'] as String?;
          if (sPhone != null && sPhone.isNotEmpty) {
            phone = sPhone;
          } else if (uPhone != null && uPhone.isNotEmpty) {
            phone = uPhone;
          }
        }
      } catch (_) {}
    }

    if (context.mounted) {
      await WhatsAppHelper.makeArtisanCall(
        context: context,
        phoneNumber: phone,
        artisanName: seller.storeName.isNotEmpty ? seller.storeName : seller.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSellers = ref.watch(allSellersProvider).value ?? [];
    final sellerFromAll = allSellers.where((s) => s.id == widget.sellerId).firstOrNull;
    final featuredSellers = ref.watch(featuredSellersProvider).value ?? [];
    final sellerFromFeatured = featuredSellers.where((s) => s.id == widget.sellerId).firstOrNull;
    final sellerDetail = ref.watch(sellerDetailProvider(widget.sellerId)).value;
    final Seller? seller = sellerDetail ?? sellerFromFeatured ?? sellerFromAll;

    if (seller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Storefront')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final allProducts = ref.watch(productsProvider).value ?? [];
    final productsForSeller = allProducts.where((p) => p.sellerId == widget.sellerId).toList();
    final sellerProductsAsync = ref.watch(sellerProductsProvider(widget.sellerId)).value;
    final List<Product> sellerProducts = (sellerProductsAsync != null && sellerProductsAsync.isNotEmpty)
        ? sellerProductsAsync
        : productsForSeller;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primaryDark,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: () => ShareHelper.shareStore(context, seller),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageFallback(
                      imageUrl: seller.coverUrl,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.goldGradient,
                            ),
                            child: ClipOval(
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: NetworkImageFallback(
                                  imageUrl: seller.avatarUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        seller.storeName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, color: AppColors.goldLight, size: 18),
                                  ],
                                ),
                                Text(
                                  'by ${seller.name} • 📍 ${seller.location}',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
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
            ),

            // Store Info & Stats
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.tagline,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('⭐ ${seller.rating}', '${seller.reviewsCount} reviews'),
                          Container(width: 1, height: 28, color: AppColors.border),
                          _buildStatItem('📦 ${seller.ordersCompleted}+', 'Delivered'),
                          Container(width: 1, height: 28, color: AppColors.border),
                          _buildStatItem('⚡ ${seller.responseTime}', 'Response'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Contact & WhatsApp Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            label: Text(
                              'WhatsApp Artisan',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _contactArtisanViaWhatsApp(context, seller),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                          label: Text(
                            'Call',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          onPressed: () => _callArtisan(context, seller),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            side: const BorderSide(color: AppColors.goldDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.pin_drop_rounded, size: 16, color: AppColors.goldDark),
                          label: Text(
                            'Map',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldDark),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoreMapScreen(highlightSellerId: seller.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'Creations (${sellerProducts.length})'),
                    const Tab(text: 'Artisan Story & Heritage'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Products Grid
            sellerProducts.isEmpty
                ? const Center(child: Text('No products currently listed.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sellerProducts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return ProductCard(product: sellerProducts[index]);
                    },
                  ),

            // Tab 2: Story & Heritage
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (seller.bio.trim().isNotEmpty) ...[
                    Text(
                      'About the Creator',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      seller.bio,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (seller.craftStory.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                'Artisan Heritage & Craft Story',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            seller.craftStory,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (seller.upiId != null && seller.upiId!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A7B54).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2A7B54), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accepts Direct UPI Payments',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'UPI ID: ${seller.upiId}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '0% FEE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2A7B54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Store verification badge
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Verified Local Business • Member since ${seller.memberSince}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.lato(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
