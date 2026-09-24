import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/seller.dart';
import '../../providers/products_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/reviews_provider.dart';
import '../../widgets/network_image_fallback.dart';
import '../../widgets/gradient_button.dart';
import 'seller_storefront_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import '../../utils/whatsapp_helper.dart';
import '../../utils/delivery_estimate.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  String? _selectedSize = 'M';
  int _quantity = 1;

  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'Free Size'];

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider).value ?? [];
    final productFromList = allProducts.where((p) => p.id == widget.productId).firstOrNull;
    final productDetail = ref.watch(productDetailProvider(widget.productId)).value;
    final Product? product = productDetail ?? productFromList;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final Seller? seller = ref.watch(sellerDetailProvider(product.sellerId)).value;
    final isFav = ref.watch(wishlistProvider).contains(product.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Sliver App Bar with Image
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.primary : AppColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => ref.read(wishlistProvider.notifier).toggle(product.id),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product link copied! Share this artisan creation.'),
                            backgroundColor: AppColors.primaryDark,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'product_image_${product.id}',
                        child: NetworkImageFallback(
                          imageUrl: product.imageUrls[_selectedImageIndex.clamp(0, product.imageUrls.length - 1)],
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Gradient Overlay for visibility
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Multi-image indicators if multiple images
                      if (product.imageUrls.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.imageUrls.length,
                              (idx) => GestureDetector(
                                onTap: () => setState(() => _selectedImageIndex = idx),
                                child: Container(
                                  width: _selectedImageIndex == idx ? 20 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _selectedImageIndex == idx ? AppColors.gold : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Product Info & Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handmade & Verified Tags
                      Row(
                        children: [
                          if (product.isHandmade)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '100% Handcrafted',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 13, color: AppColors.goldDark),
                                const SizedBox(width: 4),
                                Text(
                                  product.sellerLocation,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.goldDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Product Title
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Price & Discount Row
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          if (product.originalPrice != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              '₹${product.originalPrice!.toInt()}',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.discountPercentage}% OFF',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      Text(
                        'Inclusive of all local taxes • Free Moradabad delivery on orders over ₹999',
                        style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 12),

                      // Dynamic Delivery Estimation Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: AppColors.accentTeal, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated Delivery: ${DeliveryEstimate.getEstimate()}',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  Text(
                                    DeliveryEstimate.getDispatchCountdown(),
                                    style: GoogleFonts.lato(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Seller Profile Spotlight Card
                      if (seller != null) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SellerStorefrontScreen(sellerId: seller.id),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.goldGradient,
                                  ),
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: NetworkImageFallback(
                                        imageUrl: seller.avatarUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            seller.storeName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                                        ],
                                      ),
                                      Text(
                                        'Crafted by ${seller.name} • ${seller.responseTime}',
                                        style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Visit Store →',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // WhatsApp Artisan Direct Inquiry
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.07),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF128C7E), size: 18),
                            label: Text(
                              'Chat with Artisan on WhatsApp 💬',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF128C7E),
                              ),
                            ),
                            onPressed: () {
                              WhatsAppHelper.openArtisanChat(
                                phoneNumber: seller.phoneNumber,
                                artisanName: seller.name,
                                productName: product.name,
                                productPrice: product.price,
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Craft Heritage & Material Highlight
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F3EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.brush_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Material & Technique',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.materialOrTechnique,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  product.deliveryTime,
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Size Selector (if suits/clothing)
                      if (product.categoryId == 'suits') ...[
                        Text(
                          'Select Size',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _sizes.map((size) {
                            final isSel = _selectedSize == size;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSize = size),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? AppColors.primary : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  size,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Quantity Selector
                      Row(
                        children: [
                          Text(
                            'Quantity:',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                ),
                                Text(
                                  '$_quantity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'About this Handcrafted Piece',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reviews Summary (live from API)
                      Builder(
                        builder: (context) {
                          final reviewsAsync = ref.watch(productReviewsProvider(product.id));
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Buyer Reviews',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${product.rating} (${product.reviewsCount})',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                reviewsAsync.when(
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                    ),
                                  ),
                                  error: (err, st) => Text(
                                    'Could not load reviews.',
                                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  data: (reviews) {
                                    if (reviews.isEmpty) {
                                      return Column(
                                        children: [
                                          const Icon(Icons.rate_review_outlined, color: AppColors.border, size: 36),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No reviews yet — be the first!',
                                            style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      );
                                    }
                                    final display = reviews.take(3).toList();
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: display.map((r) {
                                        final userName = (r['users']?['full_name'] as String?) ?? 'Anonymous';
                                        final city = (r['users']?['city'] as String?) ?? '';
                                        final rating = (r['rating'] as num?)?.toInt() ?? 5;
                                        final comment = (r['comment'] as String?) ?? '';
                                        final title = (r['title'] as String?) ?? '';
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    userName,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.goldDark,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: List.generate(5, (i) => Icon(
                                                      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                                      color: AppColors.gold,
                                                      size: 13,
                                                    )),
                                                  ),
                                                ],
                                              ),
                                              if (city.isNotEmpty)
                                                Text(
                                                  city,
                                                  style: GoogleFonts.lato(fontSize: 10, color: AppColors.textSecondary),
                                                ),
                                              if (title.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  title,
                                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                                ),
                                              ],
                                              if (comment.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Text(
                                                  '"$comment"',
                                                  style: GoogleFonts.lato(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary, height: 1.4),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Floating Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  // Add to Cart button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ref.read(cartProvider.notifier).addToCart(
                          product.id,
                          quantity: _quantity,
                          selectedSize: product.categoryId == 'suits' ? _selectedSize : null,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $_quantity x ${product.name} to your cart! ✨'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'VIEW CART',
                              textColor: AppColors.goldLight,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Add to Cart',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Buy Now button
                  Expanded(
                    flex: 1,
                    child: GradientButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addToCart(
                          product.id,
                          quantity: _quantity,
                          selectedSize: product.categoryId == 'suits' ? _selectedSize : null,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                      },
                      text: 'Buy Now ⚡',
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
