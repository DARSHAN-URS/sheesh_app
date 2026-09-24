import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<String> _recentSearches = [];

  // Filter & Sort state
  String _sortBy = 'featured'; // 'featured', 'price_asc', 'price_desc', 'rating_desc'
  double _maxPrice = 15000;
  bool _handmadeOnly = false;
  String? _selectedCategoryFilter;

  final List<String> _popularTags = [
    'Zardozi Suits',
    'Brass Urli',
    'Kundan Choker',
    'Desi Ghee Bakes',
    'Bridal Henna',
    'Moradabad Peetal',
    'Chikankari',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('sheesh_recent_searches') ?? [];
    });
  }

  Future<void> _addRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_recentSearches);
    updated.remove(clean);
    updated.insert(0, clean);
    if (updated.length > 8) updated.removeLast();
    await prefs.setStringList('sheesh_recent_searches', updated);
    setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sheesh_recent_searches');
    setState(() => _recentSearches = []);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  Text('Sort & Filter Creations', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _sortBy = 'featured';
                        _maxPrice = 15000;
                        _handmadeOnly = false;
                        _selectedCategoryFilter = null;
                      });
                      setState(() {});
                    },
                    child: Text('Reset', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sort By
              Text('Sort By', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSortChip('featured', '✨ Featured', setSheetState),
                  _buildSortChip('price_asc', 'Price: Low → High', setSheetState),
                  _buildSortChip('price_desc', 'Price: High → Low', setSheetState),
                  _buildSortChip('rating_desc', '⭐ Top Rated', setSheetState),
                ],
              ),
              const SizedBox(height: 16),

              // Price Ceiling Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Max Price', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('Up to ₹${_maxPrice.toInt()}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Slider(
                value: _maxPrice,
                min: 500,
                max: 15000,
                divisions: 29,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setSheetState(() => _maxPrice = val);
                  setState(() {});
                },
              ),

              // Handmade only switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Handcrafted by Women Artisans only', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                value: _handmadeOnly,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setSheetState(() => _handmadeOnly = val);
                  setState(() {});
                },
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Apply Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String value, String label, StateSetter setSheetState) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary),
      onSelected: (selected) {
        if (selected) {
          setSheetState(() => _sortBy = value);
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];

    List<Product> results = _query.isEmpty
        ? []
        : allProducts.where((p) {
            final q = _query.toLowerCase();
            final matchesQuery = p.name.toLowerCase().contains(q) ||
                p.sellerName.toLowerCase().contains(q) ||
                p.sellerStore.toLowerCase().contains(q) ||
                p.materialOrTechnique.toLowerCase().contains(q) ||
                p.tags.any((t) => t.toLowerCase().contains(q));

            if (!matchesQuery) return false;
            if (p.price > _maxPrice) return false;
            if (_handmadeOnly && !p.isHandmade) return false;
            if (_selectedCategoryFilter != null && p.categoryId != _selectedCategoryFilter) return false;

            return true;
          }).toList();

    // Sorting
    if (results.isNotEmpty) {
      if (_sortBy == 'price_asc') {
        results.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortBy == 'price_desc') {
        results.sort((a, b) => b.price.compareTo(a.price));
      } else if (_sortBy == 'rating_desc') {
        results.sort((a, b) => b.rating.compareTo(a.rating));
      }
    }

    final hasActiveFilter = _sortBy != 'featured' || _maxPrice < 15000 || _handmadeOnly;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search Moradabad crafts & couture...',
            hintStyle: GoogleFonts.lato(color: AppColors.textLight, fontSize: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            setState(() {
              _query = val.trim();
            });
          },
          onSubmitted: (val) {
            _addRecentSearch(val);
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: hasActiveFilter ? AppColors.primary : AppColors.textSecondary,
                ),
                if (hasActiveFilter)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _query.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Searches
                  if (_recentSearches.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🕒 Recent Searches',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton(
                          onPressed: _clearRecentSearches,
                          child: Text('Clear', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches.map((term) {
                        return ActionChip(
                          avatar: const Icon(Icons.history_rounded, size: 14, color: AppColors.textSecondary),
                          label: Text(term, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onPressed: () {
                            _searchController.text = term;
                            setState(() => _query = term);
                            _addRecentSearch(term);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    '🔥 Popular Searches in Moradabad',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularTags.map((tag) {
                      return GestureDetector(
                        onTap: () {
                          _searchController.text = tag;
                          setState(() => _query = tag);
                          _addRecentSearch(tag);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                tag,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    '✨ Explore by Creator Category',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...categories.map((cat) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(
                        cat.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                      onTap: () {
                        _searchController.text = cat.name;
                        setState(() => _query = cat.name);
                        _addRecentSearch(cat.name);
                      },
                    );
                  }),
                ],
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No creations matching "$_query"',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try searching for brass, suits, Kundan, or seller name',
                        style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Found ${results.length} results for "$_query"',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (hasActiveFilter)
                            Text(
                              'Filtered (${_sortBy.replaceAll('_', ' ')})',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.64,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          return ProductCard(product: results[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
