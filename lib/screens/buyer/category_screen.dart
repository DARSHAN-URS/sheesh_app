import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import 'seller_storefront_screen.dart';
import 'artisan_snap_map_screen.dart';

/// Helper class to represent a local store with simulated hyperlocal distance
class LocalStoreItem {
  final Seller seller;
  final double distanceKm;
  final String clusterArea;
  final List<Product> postedProducts;

  const LocalStoreItem({
    required this.seller,
    required this.distanceKm,
    required this.clusterArea,
    required this.postedProducts,
  });
}

enum PriceRangeFilter {
  all('All Prices', null, null),
  under500('Under ₹500', 0, 500),
  from500to1500('₹500 - ₹1.5k', 500, 1500),
  from1500to5000('₹1.5k - ₹5k', 1500, 5000),
  above5000('Above ₹5k', 5000, 999999);

  final String label;
  final double? min;
  final double? max;
  const PriceRangeFilter(this.label, this.min, this.max);
}

class CategoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const CategoryScreen({super.key, this.categoryId});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String? _selectedCategory;
  double? _selectedDistanceKm; // null = Any distance, or 2.0, 5.0, 10.0, 25.0, 50.0
  String _userLocation = 'Peetal Mandi, Moradabad';
  bool _isGpsLocation = true;
  String _sortBy = 'distance'; // distance, rating, popular
  double? _minRating; // null = all, 4.5, 4.0, 3.5
  PriceRangeFilter _selectedPrice = PriceRangeFilter.all;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedDistanceKm != null) count++;
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) count++;
    if (_minRating != null) count++;
    if (_selectedPrice != PriceRangeFilter.all) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryId;
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(allSellersProvider);
      ref.invalidate(featuredSellersProvider);
      ref.invalidate(productsProvider);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Hyperlocal distances calculated based on selected user location
  double _getStoreDistance(Seller seller) {
    final loc = seller.location.toLowerCase();
    final userLoc = _userLocation.toLowerCase();

    // If seller and user are in the same neighborhood
    if (userLoc.contains('peetal mandi') && loc.contains('peetal mandi')) return 0.5;
    if (userLoc.contains('civil lines') && loc.contains('civil lines')) return 0.6;
    if (userLoc.contains('mandi chowk') && loc.contains('mandi chowk')) return 0.7;
    if (userLoc.contains('kanth road') && loc.contains('kanth road')) return 0.9;
    if (loc.contains('moradabad') || loc.contains('peetal') || loc.contains('pura') || loc.contains('mandi')) {
      final hash = seller.id.hashCode.abs();
      return (0.8 + (hash % 35) / 10.0); // 0.8 to 4.2 km (all within local Moradabad)
    }

    final hash = seller.id.hashCode.abs();
    return 1.2 + (hash % 60) / 10.0;
  }

  String _getClusterArea(Seller seller) {
    final loc = seller.location.toLowerCase();
    if (loc.contains('peetal mandi')) return 'Peetal Mandi';
    if (loc.contains('civil lines')) return 'Civil Lines';
    if (loc.contains('mandi chowk')) return 'Mandi Chowk';
    if (loc.contains('bazaar ganj') || loc.contains('bazar ganj')) return 'Bazaar Ganj';
    if (loc.contains('kanth road')) return 'Kanth Road';
    if (loc.contains('mughal pura') || loc.contains('mughalpura')) return 'Mughal Pura';
    if (seller.location.isNotEmpty && seller.location != 'Moradabad, UP') {
      return seller.location.split(',').first.trim();
    }
    return 'Moradabad Central';
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final allProducts = ref.watch(productsProvider).value ?? [];
    final sellersList = ref.watch(allSellersProvider).value ?? [];
    final featuredSellers = ref.watch(featuredSellersProvider).value ?? [];
    final auth = ref.watch(authProvider);

    // Combine all available sellers from database + current user's seller profile
    final Set<String> seenIds = {};
    final List<Seller> allSellers = [];

    // 1. Current user's seller profile if active
    if (auth.isSeller && auth.sellerProfile != null && auth.sellerProfile!.storeName.isNotEmpty) {
      allSellers.add(auth.sellerProfile!);
      seenIds.add(auth.sellerProfile!.id);
    }

    // 2. All registered stores from backend/database
    for (final s in sellersList) {
      if (!seenIds.contains(s.id) && s.storeName.isNotEmpty) {
        allSellers.add(s);
        seenIds.add(s.id);
      }
    }

    // 3. Any additional featured sellers
    for (final s in featuredSellers) {
      if (!seenIds.contains(s.id) && s.storeName.isNotEmpty) {
        allSellers.add(s);
        seenIds.add(s.id);
      }
    }

    // Build LocalStoreItem list with filters
    List<LocalStoreItem> localStores = allSellers.map((seller) {
      final distance = _getStoreDistance(seller);
      final cluster = _getClusterArea(seller);
      final productsForSeller = allProducts.where((p) => p.sellerId == seller.id).toList();

      return LocalStoreItem(
        seller: seller,
        distanceKm: distance,
        clusterArea: cluster,
        postedProducts: productsForSeller,
      );
    }).where((item) {
      // 1. Distance filter (null = Any Distance)
      if (_selectedDistanceKm != null && item.distanceKm > _selectedDistanceKm!) {
        return false;
      }

      // 2. Type / Craft Category filter
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        final targetCat = _selectedCategory!.toLowerCase();
        bool matches(String? c) {
          if (c == null) return false;
          final cl = c.toLowerCase();
          if (cl == targetCat) return true;
          if (cl.startsWith(targetCat) || targetCat.startsWith(cl)) return true;
          return false;
        }
        final matchesCat = matches(item.seller.categoryId) ||
            item.postedProducts.any((p) => matches(p.categoryId));
        if (!matchesCat) return false;
      }

      // 3. Minimum Rating filter
      if (_minRating != null && item.seller.rating < _minRating!) {
        return false;
      }

      // 4. Price Range filter
      if (_selectedPrice != PriceRangeFilter.all) {
        final min = _selectedPrice.min ?? 0;
        final max = _selectedPrice.max ?? 999999;
        if (item.postedProducts.isNotEmpty) {
          final hasProductInRange = item.postedProducts.any((p) => p.price >= min && p.price <= max);
          if (!hasProductInRange) return false;
        }
      }

      // 5. Search query (matches store name, artisan name, location, or crafts)
      if (_searchQuery.isNotEmpty) {
        final matchStore = item.seller.storeName.toLowerCase().contains(_searchQuery);
        final matchName = item.seller.name.toLowerCase().contains(_searchQuery);
        final matchLocation = item.clusterArea.toLowerCase().contains(_searchQuery);
        final matchTagline = item.seller.tagline.toLowerCase().contains(_searchQuery);
        final matchProducts = item.postedProducts.any(
          (p) => p.name.toLowerCase().contains(_searchQuery) ||
              p.tags.any((t) => t.toLowerCase().contains(_searchQuery)),
        );
        if (!matchStore && !matchName && !matchLocation && !matchTagline && !matchProducts) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    if (_sortBy == 'distance') {
      localStores.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (_sortBy == 'rating') {
      localStores.sort((a, b) => b.seller.rating.compareTo(a.seller.rating));
    } else if (_sortBy == 'popular') {
      localStores.sort((a, b) => b.seller.ordersCompleted.compareTo(a.seller.ordersCompleted));
    }

    Category? currentCat = _selectedCategory != null
        ? categories.where((c) => c.id == _selectedCategory).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SheeshAppBar(
        showBackButton: widget.categoryId != null,
        title: currentCat != null ? '${currentCat.icon} ${currentCat.name} Stores' : null,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Blinkit / Amazon Search Bar with Location & Filters ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Blinkit / Amazon Location Header & Top-Right Snap Map Button ──
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _openLocationPicker(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFD64438)),
                                const SizedBox(width: 4),
                                Text(
                                  'Deliver to ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    _userLocation,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textPrimary),
                                if (_isGpsLocation) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'GPS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2A7B54),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── Top-Right Corner Snapchat Map Section ──
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ArtisanSnapMapScreen(
                                initialStores: localStores,
                                userLocation: _userLocation,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5A1629), Color(0xFF882038)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5A1629).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🗺️', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                'Map',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Amazon & Blinkit Search Bar with Integrated Filters Button ──
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF8F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _activeFiltersCount > 0 ? const Color(0xFF5A1629) : AppColors.border,
                        width: _activeFiltersCount > 0 ? 1.2 : 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search_rounded, color: AppColors.primary, size: 21),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'Search stores, crafts, peetal, zardozi...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: AppColors.textLight,
                                fontSize: 12.5,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 17),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _searchCtrl.clear(),
                          ),
                        const SizedBox(width: 6),
                        // Vertical Divider
                        Container(
                          height: 22,
                          width: 1,
                          color: AppColors.border,
                        ),
                        // Integrated Filter Button on Search Bar itself!
                        InkWell(
                          onTap: () => _openComprehensiveFilterSheet(context, categories),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 19,
                                      color: _activeFiltersCount > 0
                                          ? const Color(0xFFD64438)
                                          : const Color(0xFF5A1629),
                                    ),
                                    if (_activeFiltersCount > 0)
                                      Positioned(
                                        top: -7,
                                        right: -7,
                                        child: Container(
                                          padding: const EdgeInsets.all(3.5),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD64438),
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                          child: Center(
                                            child: Text(
                                              '$_activeFiltersCount',
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Filters',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _activeFiltersCount > 0
                                        ? const Color(0xFFD64438)
                                        : const Color(0xFF5A1629),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Horizontal Quick-Filter Pills Row (Blinkit & Amazon style) ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Master Filter Pill
                        _buildFilterPill(
                          label: _activeFiltersCount > 0 ? 'Filters ($_activeFiltersCount)' : 'Filters',
                          icon: Icons.tune_rounded,
                          isActive: _activeFiltersCount > 0,
                          onTap: () => _openComprehensiveFilterSheet(context, categories),
                        ),
                        const SizedBox(width: 8),

                        // 1. Location / Distance Filter Pill
                        _buildFilterPill(
                          label: _selectedDistanceKm != null ? '< ${_selectedDistanceKm!.toInt()} km' : 'Distance',
                          icon: Icons.near_me_rounded,
                          isActive: _selectedDistanceKm != null,
                          onTap: () => _openDistancePickerSheet(context),
                          onClear: _selectedDistanceKm != null ? () => setState(() => _selectedDistanceKm = null) : null,
                        ),
                        const SizedBox(width: 8),

                        // 2. Ratings Filter Pill
                        _buildFilterPill(
                          label: _minRating != null ? '${_minRating}+ ★' : 'Rating',
                          icon: Icons.star_rounded,
                          isActive: _minRating != null,
                          onTap: () => _openRatingPickerSheet(context),
                          onClear: _minRating != null ? () => setState(() => _minRating = null) : null,
                        ),
                        const SizedBox(width: 8),

                        // 3. Categories Filter Pill
                        _buildFilterPill(
                          label: currentCat != null ? '${currentCat.icon} ${currentCat.name}' : 'Category',
                          icon: Icons.category_rounded,
                          isActive: _selectedCategory != null,
                          onTap: () => _openCategoryPickerSheet(context, categories),
                          onClear: _selectedCategory != null ? () => setState(() => _selectedCategory = null) : null,
                        ),
                        const SizedBox(width: 8),

                        // 4. Price Filter Pill
                        _buildFilterPill(
                          label: _selectedPrice != PriceRangeFilter.all ? _selectedPrice.label : 'Price',
                          icon: Icons.currency_rupee_rounded,
                          isActive: _selectedPrice != PriceRangeFilter.all,
                          onTap: () => _openPricePickerSheet(context),
                          onClear: _selectedPrice != PriceRangeFilter.all ? () => setState(() => _selectedPrice = PriceRangeFilter.all) : null,
                        ),

                        // Reset All Button
                        if (_activeFiltersCount > 0 || _searchQuery.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDistanceKm = null;
                                _selectedCategory = null;
                                _minRating = null;
                                _selectedPrice = PriceRangeFilter.all;
                                _searchCtrl.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD64438).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFD64438).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.close_rounded, size: 14, color: Color(0xFFD64438)),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Clear All',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD64438),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stores Count Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${localStores.length} stores found near $_userLocation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Stores List Section ──
          if (localStores.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.blush,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_outlined, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Stores Matching Filters',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try expanding your distance range, changing your location, or selecting another craft type.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedDistanceKm = null;
                            _selectedCategory = null;
                            _minRating = null;
                            _selectedPrice = PriceRangeFilter.all;
                            _searchCtrl.clear();
                          });
                        },
                        child: const Text('Reset All Filters'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = localStores[index];
                    return _buildLocalStoreCard(context, item)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: (index * 60).ms)
                        .slideY(begin: 0.05, end: 0);
                  },
                  childCount: localStores.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5A1629) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF5A1629) : const Color(0xFFDED2CB),
            width: 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF5A1629).withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? Colors.white : const Color(0xFF5A1629),
            ),
            const SizedBox(width: 4.5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            if (isActive && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: isActive ? Colors.white70 : AppColors.textLight,
              ),
          ],
        ),
      ),
    );
  }

  /// 1. Distance & Location Filter Sheet
  void _openDistancePickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.near_me_rounded, color: Color(0xFF5A1629), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Distance & Location',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedDistanceKm = null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset', style: TextStyle(color: Color(0xFFD64438), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            // Current Location Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF3EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8D6CB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFD64438)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Address: $_userLocation',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _openLocationPicker(context);
                    },
                    child: Text(
                      'Change',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A1629),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Select Maximum Distance Range:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                {'label': 'All Distances', 'km': null},
                {'label': '< 2 km', 'km': 2.0},
                {'label': '< 5 km', 'km': 5.0},
                {'label': '< 10 km', 'km': 10.0},
                {'label': '< 25 km', 'km': 25.0},
                {'label': '< 50 km', 'km': 50.0},
              ].map((opt) {
                final km = opt['km'] as double?;
                final isSel = _selectedDistanceKm == km;
                return ChoiceChip(
                  label: Text(opt['label'] as String),
                  selected: isSel,
                  selectedColor: const Color(0xFF5A1629),
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? Colors.white : AppColors.textPrimary,
                  ),
                  side: BorderSide(color: isSel ? const Color(0xFF5A1629) : AppColors.border),
                  onSelected: (_) {
                    setState(() => _selectedDistanceKm = km);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Ratings Filter Sheet
  void _openRatingPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Customer Ratings',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _minRating = null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset', style: TextStyle(color: Color(0xFFD64438), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...[
              {'label': 'All Ratings', 'value': null, 'desc': 'Show all verified stores'},
              {'label': '4.5 & above ★', 'value': 4.5, 'desc': 'Top-rated master artisans'},
              {'label': '4.0 & above ★', 'value': 4.0, 'desc': 'Highly recommended stores'},
              {'label': '3.5 & above ★', 'value': 3.5, 'desc': 'Good artisan workshops'},
            ].map((opt) {
              final val = opt['value'] as double?;
              final isSel = _minRating == val;
              return ListTile(
                onTap: () {
                  setState(() => _minRating = val);
                  Navigator.pop(ctx);
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF5A1629) : const Color(0xFFFAF3EC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: isSel ? Colors.white : const Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
                title: Text(
                  opt['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isSel ? const Color(0xFF5A1629) : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  opt['desc'] as String,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                trailing: isSel
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF5A1629))
                    : const Icon(Icons.radio_button_unchecked, color: AppColors.border),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 3. Category Filter Sheet
  void _openCategoryPickerSheet(BuildContext context, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category_rounded, color: Color(0xFF5A1629), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Craft Categories',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCategory = null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset', style: TextStyle(color: Color(0xFFD64438), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('All Crafts'),
                  selected: _selectedCategory == null,
                  selectedColor: const Color(0xFF5A1629),
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.w500,
                    color: _selectedCategory == null ? Colors.white : AppColors.textPrimary,
                  ),
                  side: BorderSide(color: _selectedCategory == null ? const Color(0xFF5A1629) : AppColors.border),
                  onSelected: (_) {
                    setState(() => _selectedCategory = null);
                    Navigator.pop(ctx);
                  },
                ),
                ...categories.map((cat) {
                  final isSel = _selectedCategory == cat.id;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(cat.name),
                      ],
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFF5A1629),
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : AppColors.textPrimary,
                    ),
                    side: BorderSide(color: isSel ? const Color(0xFF5A1629) : AppColors.border),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat.id);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Price Filter Sheet
  void _openPricePickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_rupee_rounded, color: Color(0xFF2A7B54), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Price Range',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedPrice = PriceRangeFilter.all);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset', style: TextStyle(color: Color(0xFFD64438), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...PriceRangeFilter.values.map((opt) {
              final isSel = _selectedPrice == opt;
              String desc = 'Show items of any price';
              if (opt == PriceRangeFilter.under500) desc = 'Budget friendly everyday artisan crafts';
              if (opt == PriceRangeFilter.from500to1500) desc = 'Popular handcrafted gifts & home items';
              if (opt == PriceRangeFilter.from1500to5000) desc = 'Premium brassware & silk wearables';
              if (opt == PriceRangeFilter.above5000) desc = 'Luxury master craftsman heirlooms';

              return ListTile(
                onTap: () {
                  setState(() => _selectedPrice = opt);
                  Navigator.pop(ctx);
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF5A1629) : const Color(0xFFE8F8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_rupee_rounded,
                    color: isSel ? Colors.white : const Color(0xFF2A7B54),
                    size: 16,
                  ),
                ),
                title: Text(
                  opt.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isSel ? const Color(0xFF5A1629) : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                trailing: isSel
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF5A1629))
                    : const Icon(Icons.radio_button_unchecked, color: AppColors.border),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 5. Full Amazon & Blinkit Style Multi-Filter Modal Sheet
  void _openComprehensiveFilterSheet(BuildContext context, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Modal Handle
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: Color(0xFF5A1629), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Filters & Sort',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDistanceKm = null;
                            _selectedCategory = null;
                            _minRating = null;
                            _selectedPrice = PriceRangeFilter.all;
                            _sortBy = 'distance';
                          });
                          setModalState(() {});
                        },
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFD64438),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Scrollable Filter Sections
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Location & Range
                        Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF5A1629)),
                            const SizedBox(width: 6),
                            Text(
                              'Location & Distance Range',
                              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openLocationPicker(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Delivery address: ',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                                Text(
                                  _userLocation,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF5A1629)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_location_alt_outlined, size: 14, color: Color(0xFF5A1629)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            {'label': 'All Distances', 'km': null},
                            {'label': '< 2 km', 'km': 2.0},
                            {'label': '< 5 km', 'km': 5.0},
                            {'label': '< 10 km', 'km': 10.0},
                            {'label': '< 25 km', 'km': 25.0},
                            {'label': '< 50 km', 'km': 50.0},
                          ].map((opt) {
                            final km = opt['km'] as double?;
                            final isSel = _selectedDistanceKm == km;
                            return ChoiceChip(
                              label: Text(opt['label'] as String),
                              selected: isSel,
                              selectedColor: const Color(0xFF5A1629),
                              backgroundColor: Colors.white,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                              side: BorderSide(color: isSel ? const Color(0xFF5A1629) : AppColors.border),
                              onSelected: (_) {
                                setState(() => _selectedDistanceKm = km);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),

                        // Section 2: Ratings
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            Text(
                              'Customer Ratings',
                              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            {'label': 'All Ratings', 'val': null},
                            {'label': '4.5+ ★', 'val': 4.5},
                            {'label': '4.0+ ★', 'val': 4.0},
                            {'label': '3.5+ ★', 'val': 3.5},
                          ].map((opt) {
                            final val = opt['val'] as double?;
                            final isSel = _minRating == val;
                            return ChoiceChip(
                              label: Text(opt['label'] as String),
                              selected: isSel,
                              selectedColor: const Color(0xFF5A1629),
                              backgroundColor: Colors.white,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                              side: BorderSide(color: isSel ? const Color(0xFF5A1629) : AppColors.border),
                              onSelected: (_) {
                                setState(() => _minRating = val);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),

                        // Section 3: Categories
                        Row(
                          children: [
                            const Icon(Icons.category_rounded, size: 16, color: Color(0xFF5A1629)),
                            const SizedBox(width: 6),
                            Text(
                              'Craft Categories',
                              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All Crafts'),
                              selected: _selectedCategory == null,
                              selectedColor: const Color(0xFF5A1629),
                              backgroundColor: Colors.white,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.w500,
                                color: _selectedCategory == null ? Colors.white : AppColors.textPrimary,
                              ),
                              side: BorderSide(color: _selectedCategory == null ? const Color(0xFF5A1629) : AppColors.border),
                              onSelected: (_) {
                                setState(() => _selectedCategory = null);
                                setModalState(() {});
                              },
                            ),
                            ...categories.map((cat) {
                              final isSel = _selectedCategory == cat.id;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(cat.icon, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 4),
                                    Text(cat.name),
                                  ],
                                ),
                                selected: isSel,
                                selectedColor: const Color(0xFF5A1629),
                                backgroundColor: Colors.white,
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? Colors.white : AppColors.textPrimary,
                                ),
                                side: BorderSide(color: isSel ? const Color(0xFF5A1629) : AppColors.border),
                                onSelected: (_) {
                                  setState(() => _selectedCategory = cat.id);
                                  setModalState(() {});
                                },
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),

                        // Section 4: Price
                        Row(
                          children: [
                            const Icon(Icons.currency_rupee_rounded, size: 16, color: Color(0xFF2A7B54)),
                            const SizedBox(width: 6),
                            Text(
                              'Price Range',
                              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PriceRangeFilter.values.map((opt) {
                            final isSel = _selectedPrice == opt;
                            return ChoiceChip(
                              label: Text(opt.label),
                              selected: isSel,
                              selectedColor: const Color(0xFF5A1629),
                              backgroundColor: Colors.white,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                              side: BorderSide(color: isSel ? const Color(0xFF5A1629) : AppColors.border),
                              onSelected: (_) {
                                setState(() => _selectedPrice = opt);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),

                        // Section 5: Sort By
                        Row(
                          children: [
                            const Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF5A1629)),
                            const SizedBox(width: 6),
                            Text(
                              'Sort By',
                              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            {'label': 'Distance (Nearest)', 'val': 'distance'},
                            {'label': 'Highest Rated', 'val': 'rating'},
                            {'label': 'Most Popular', 'val': 'popular'},
                          ].map((opt) {
                            final val = opt['val'] as String;
                            final isSel = _sortBy == val;
                            return ChoiceChip(
                              label: Text(opt['label'] as String),
                              selected: isSel,
                              selectedColor: const Color(0xFF5A1629),
                              backgroundColor: Colors.white,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                              side: BorderSide(color: isSel ? const Color(0xFF5A1629) : AppColors.border),
                              onSelected: (_) {
                                setState(() => _sortBy = val);
                                setModalState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Apply Button Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A1629),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openLocationPicker(BuildContext context) {
    final TextEditingController locCtrl = TextEditingController(text: _userLocation);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Your Location 📍',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Stores and distance will update based on your selected address.',
                  style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Button: Use Current Location (GPS)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5A1629), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFFFAF3EC),
                    ),
                    icon: const Icon(Icons.my_location_rounded, color: Color(0xFF5A1629), size: 18),
                    label: Text(
                      'Use Current Location (GPS)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A1629),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _userLocation = 'Peetal Mandi, Moradabad';
                        _isGpsLocation = true;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📍 Location updated to Current GPS Location!'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR TYPE MANUALLY',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 14),

                // Manual Input TextField
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: locCtrl,
                          autofocus: false,
                          style: GoogleFonts.poppins(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Enter area, colony, or city (e.g. Civil Lines)...',
                            hintStyle: GoogleFonts.lato(fontSize: 12.5, color: AppColors.textLight),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                _userLocation = val.trim();
                                _isGpsLocation = false;
                              });
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (locCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              _userLocation = locCtrl.text.trim();
                              _isGpsLocation = false;
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(
                          'SET',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Quick Moradabad Artisan Areas:',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Peetal Mandi',
                    'Civil Lines',
                    'Mandi Chowk',
                    'Bazaar Ganj',
                    'Kanth Road',
                    'Delhi NCR',
                  ].map((area) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _userLocation = '$area, Moradabad';
                          _isGpsLocation = false;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6EDE4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2D1C3)),
                        ),
                        child: Text(
                          area,
                          style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF5A1629), fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The Hyperlocal Artisan Store Card
  Widget _buildLocalStoreCard(BuildContext context, LocalStoreItem item) {
    final seller = item.seller;
    final products = item.postedProducts;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A1629).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Open the store page to view all their posted items
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SellerStorefrontScreen(sellerId: seller.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Store Cover Image with Hyperlocal Range Badges ──
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
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
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),

                  // Distance Pill (Top-Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A7B54),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${item.distanceKm.toStringAsFixed(1)} km away',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cluster Area (Top-Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '📍 ${item.clusterArea}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Store Identity & Creator Info ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
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
                      const SizedBox(width: 12),

                      // Store Title, Verified Badge & Rating
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    seller.storeName,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (seller.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF2A7B54), size: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'By ${seller.name} • ${seller.location}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                                const SizedBox(width: 3),
                                Text(
                                  seller.rating.toStringAsFixed(1),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  ' (${seller.reviewsCount})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: AppColors.border,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${seller.ordersCompleted}+ orders',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2A7B54),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.circle, color: Color(0xFF2A7B54), size: 5),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Open Now',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2A7B54),
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

                  if (seller.tagline.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '“${seller.tagline}”',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),

                  // ── Posted Items Strip (Thumbnails Preview inside this store) ──
                  Row(
                    children: [
                      Text(
                        'Posted Crafts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blush,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${products.length > 0 ? products.length : seller.productsCount} items',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enter Store',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Thumbnails row of items posted by this store
                  if (products.isNotEmpty)
                    SizedBox(
                      height: 78,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length > 4 ? 4 : products.length,
                        itemBuilder: (ctx, pIdx) {
                          final prod = products[pIdx];
                          return Container(
                            width: 74,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                NetworkImageFallback(
                                  imageUrl: prod.imageUrls.isNotEmpty ? prod.imageUrls.first : '',
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    color: Colors.black.withValues(alpha: 0.65),
                                    child: Text(
                                      '₹${prod.price.toInt()}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Tap to visit storefront and view this artisan’s latest collection.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textLight),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
