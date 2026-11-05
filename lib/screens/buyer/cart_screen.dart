import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/network_image_fallback.dart';
import '../../widgets/gradient_button.dart';
import 'checkout_screen.dart';
import 'product_detail_screen.dart';
import 'buyer_profile_screen.dart';

/// Provider to allow external screens (like Profile) to toggle Cart (0) vs Wishlist (1)
final cartSubTabProvider = StateProvider<int>((ref) => 0);

class CartScreen extends ConsumerStatefulWidget {
  final bool isTab;
  final int? initialTab; // 0 = Bag/Cart, 1 = Wishlist/Saved

  const CartScreen({
    super.key,
    this.isTab = false,
    this.initialTab,
  });

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;
  double _couponDiscount = 0;
  bool _giftPackaging = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cartSubTabProvider.notifier).state = widget.initialTab!;
      });
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'SHEESH100' || code == 'MORADABAD' || code == 'WELCOME') {
      setState(() {
        _couponApplied = true;
        _couponDiscount = 100;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Coupon applied! ₹100 artisan discount deducted.'),
          backgroundColor: Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code. Try "SHEESH100" or "MORADABAD"'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(cartSubTabProvider);
    final cartAsync = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final cart = cartAsync.value ?? [];
    final subtotal = cartNotifier.subtotal;
    final deliveryFee = cartNotifier.deliveryFee;
    final packagingFee = _giftPackaging ? 49.0 : 0.0;
    final baseDiscount = cartNotifier.discount;
    final totalDiscount = baseDiscount + _couponDiscount;
    final total = (subtotal + deliveryFee + packagingFee - totalDiscount).clamp(0.0, double.infinity);
    final cartCount = cartNotifier.itemCount;

    final wishlist = ref.watch(wishlistProvider);
    final allProducts = ref.watch(productsProvider).value ?? [];
    final favProducts = allProducts.where((p) => wishlist.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        automaticallyImplyLeading: !widget.isTab,
        title: Text(
          selectedTab == 0 ? 'My Shopping Bag ($cartCount)' : 'Saved Wishlist (${favProducts.length})',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (selectedTab == 0 && cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              child: Text(
                'Clear Bag',
                style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          if (selectedTab == 1 && favProducts.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined, size: 15, color: Color(0xFF2A7B54)),
              label: Text(
                'Add All',
                style: GoogleFonts.poppins(color: const Color(0xFF2A7B54), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                for (final prod in favProducts) {
                  await ref.read(cartProvider.notifier).addToCart(prod.id, quantity: 1);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All ${favProducts.length} saved creations added to your bag! 🛍️'),
                      backgroundColor: const Color(0xFF2A7B54),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  ref.read(cartSubTabProvider.notifier).state = 0;
                }
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF3EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Tab 0: Bag
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(cartSubTabProvider.notifier).state = 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selectedTab == 0 ? const Color(0xFF5A1629) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF5A1629).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_rounded,
                                size: 16,
                                color: selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'My Bag',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: selectedTab == 0 ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (cartCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 0 ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF5A1629),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$cartCount',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tab 1: Wishlist / Saved Items
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(cartSubTabProvider.notifier).state = 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selectedTab == 1 ? const Color(0xFF5A1629) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF5A1629).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: selectedTab == 1 ? const Color(0xFFD64438) : const Color(0xFFD64438),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Wishlist',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: selectedTab == 1 ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (favProducts.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 1 ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFD64438),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${favProducts.length}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: selectedTab == 0
          ? _buildCartBody(context, cartAsync, cart, subtotal, deliveryFee, packagingFee, totalDiscount, total, favProducts)
          : _buildWishlistBody(context, favProducts),

      // Bottom Checkout Bar (only on Bag tab when cart has items)
      bottomSheet: (selectedTab == 0 && cart.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL PAYABLE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '₹${total.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF5A1629),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                      },
                      text: 'Proceed to Checkout →',
                      height: 50,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // ─── CART BODY ─────────────────────────────────────────────────────────────

  Widget _buildCartBody(
    BuildContext context,
    AsyncValue<List<dynamic>> cartAsync,
    List<dynamic> cart,
    double subtotal,
    double deliveryFee,
    double packagingFee,
    double totalDiscount,
    double total,
    List<Product> favProducts,
  ) {
    return cartAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load bag', style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(cartProvider.notifier).fetchCart(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (_) => cart.isEmpty
          ? _buildEmptyCart(context, favProducts)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Free Shipping Progress
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: subtotal >= 999 ? const Color(0xFFE8F8F0) : const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: subtotal >= 999 ? AppColors.success.withValues(alpha: 0.3) : AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              subtotal >= 999 ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                              color: subtotal >= 999 ? AppColors.success : AppColors.goldDark,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                subtotal >= 999
                                    ? '🎉 You unlocked FREE Express Delivery in Moradabad!'
                                    : 'Add ₹${(999 - subtotal).toInt()} more for FREE Moradabad Delivery',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: subtotal >= 999 ? AppColors.success : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (subtotal / 999.0).clamp(0.0, 1.0),
                            backgroundColor: Colors.black.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              subtotal >= 999 ? AppColors.success : AppColors.accent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cart Items List
                  ...cart.map((item) {
                    final p = item.product;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 84,
                                height: 84,
                                child: NetworkImageFallback(
                                  imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
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
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textLight),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'by ${p.sellerStore} (Moradabad)',
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (item.selectedSize != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Size: ${item.selectedSize}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${item.totalPrice.toInt()}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF5A1629),
                                      ),
                                    ),
                                    // Quantity Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                                            child: const Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Icon(Icons.remove, size: 14),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${item.quantity}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                                            child: const Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Icon(Icons.add, size: 14),
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
                    );
                  }),

                  const SizedBox(height: 16),

                  // Coupon Code Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon (e.g. SHEESH100)',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: GoogleFonts.lato(fontSize: 13, color: AppColors.textLight),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _applyCoupon,
                          child: Text(
                            _couponApplied ? 'APPLIED ✓' : 'APPLY',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _couponApplied ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Heritage Gift Packaging Checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _giftPackaging ? const Color(0xFFFAF3EC) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _giftPackaging ? AppColors.primary : AppColors.border,
                        width: _giftPackaging ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A1629).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF5A1629), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Heritage Gift Packaging (+₹49)',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Handcrafted box with brass seal & gift card note',
                                style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: _giftPackaging,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _giftPackaging = val ?? false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price Details',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Divider(height: 20),
                        _buildPriceRow('Items Subtotal', '₹${subtotal.toInt()}'),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          'Moradabad Delivery Fee',
                          deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toInt()}',
                          isFree: deliveryFee == 0,
                        ),
                        if (_giftPackaging) ...[
                          const SizedBox(height: 8),
                          _buildPriceRow('Heritage Gift Packaging', '₹49'),
                        ],
                        if (totalDiscount > 0) ...[
                          const SizedBox(height: 8),
                          _buildPriceRow('Artisan & Promo Discount', '-₹${totalDiscount.toInt()}', isDiscount: true),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Payable',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '₹${total.toInt()}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF5A1629),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Quick Add from Wishlist Strip (if wishlist has items) ──
                  if (favProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Color(0xFFD64438), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Saved in Your Wishlist (${favProducts.length})',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => ref.read(cartSubTabProvider.notifier).state = 1,
                          child: Text(
                            'View All →',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5A1629),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: favProducts.length,
                        itemBuilder: (ctx, idx) {
                          final prod = favProducts[idx];
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 80,
                                    child: NetworkImageFallback(
                                      imageUrl: prod.imageUrls.isNotEmpty ? prod.imageUrls.first : '',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  prod.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '₹${prod.price.toInt()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5A1629),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 28,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5A1629),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).addToCart(prod.id, quantity: 1);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Added "${prod.name}" to Bag! 🛍️'),
                                          backgroundColor: const Color(0xFF2A7B54),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '+ Add to Bag',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // ─── EMPTY CART VIEW ───────────────────────────────────────────────────────

  Widget _buildEmptyCart(BuildContext context, List<Product> favProducts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFF5A1629).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 68, color: Color(0xFF5A1629)),
          ),
          const SizedBox(height: 18),
          Text(
            'Your Shopping Bag is Empty',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Support Moradabad’s women artisans directly. Discover handcrafted brassware, embroidered zardozi suits & vintage jewellery.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A1629),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.storefront_rounded, size: 16),
                label: Text(
                  'Explore Creations 🛍️',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  ref.read(buyerTabIndexProvider.notifier).state = 1; // switch to Explore tab
                },
              ),
              if (favProducts.isNotEmpty) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD64438),
                    side: const BorderSide(color: Color(0xFFD64438)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.favorite_rounded, size: 16),
                  label: Text(
                    'Wishlist (${favProducts.length})',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () {
                    ref.read(cartSubTabProvider.notifier).state = 1;
                  },
                ),
              ],
            ],
          ),

          // Quick Saved Items preview
          if (favProducts.isNotEmpty) ...[
            const SizedBox(height: 36),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved in Wishlist (${favProducts.length})',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => ref.read(cartSubTabProvider.notifier).state = 1,
                  child: Text('View Wishlist →', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: favProducts.length > 3 ? 3 : favProducts.length,
              itemBuilder: (ctx, idx) {
                final prod = favProducts[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: NetworkImageFallback(
                            imageUrl: prod.imageUrls.isNotEmpty ? prod.imageUrls.first : '',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹${prod.price.toInt()}',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF5A1629)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A1629),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          ref.read(cartProvider.notifier).addToCart(prod.id, quantity: 1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${prod.name}" to your bag! 🛍️'),
                              backgroundColor: const Color(0xFF2A7B54),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text('Add to Bag', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── WISHLIST BODY (SAVED ITEMS & PRODUCTS GRID) ───────────────────────────

  Widget _buildWishlistBody(BuildContext context, List<Product> favProducts) {
    if (favProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFFD64438).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, size: 68, color: Color(0xFFD64438)),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Wishlist is Empty',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart icon on authentic Moradabad brassware, jewellery, and handcrafted apparel to save items here for later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A1629),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: Text(
                  'Explore Artisan Treasures 🏺',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  ref.read(buyerTabIndexProvider.notifier).state = 1; // explore
                },
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${favProducts.length} Artisan Creations Saved',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Instant 0% Commission',
                style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-Column Responsive Product Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: favProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (ctx, index) {
              final prod = favProducts[index];
              return _buildWishlistProductCard(context, prod);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistProductCard(BuildContext context, Product prod) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Wishlist Heart Toggle
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: prod.id)),
                    );
                  },
                  child: NetworkImageFallback(
                    imageUrl: prod.imageUrls.isNotEmpty ? prod.imageUrls.first : '',
                    fit: BoxFit.cover,
                  ),
                ),
                // Discount Badge
                if (prod.originalPrice != null && prod.originalPrice! > prod.price)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64438),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(((prod.originalPrice! - prod.price) / prod.originalPrice!) * 100).toInt()}% OFF',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Remove from Wishlist Heart Button
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () {
                      ref.read(wishlistProvider.notifier).toggle(prod.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "${prod.name}" from Wishlist'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFD64438),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details & Add to Bag
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.sellerStore,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  prod.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${prod.price.toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A1629),
                      ),
                    ),
                    if (prod.originalPrice != null && prod.originalPrice! > prod.price) ...[
                      const SizedBox(width: 5),
                      Text(
                        '₹${prod.originalPrice!.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A1629),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ref.read(cartProvider.notifier).addToCart(prod.id, quantity: 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "${prod.name}" to Bag! 🛍️'),
                          backgroundColor: const Color(0xFF2A7B54),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'VIEW BAG',
                            textColor: Colors.white,
                            onPressed: () {
                              ref.read(cartSubTabProvider.notifier).state = 0;
                            },
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Add to Bag',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isFree || isDiscount ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
