import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/product_card.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const CategoryScreen({super.key, this.categoryId});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String? _selectedCategory;
  String _sortBy = 'popular'; // popular, price_low, price_high, rating

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final allProducts = ref.watch(productsProvider).value ?? [];

    Category? currentCat = _selectedCategory != null
        ? categories.where((c) => c.id == _selectedCategory).firstOrNull
        : null;

    List<Product> products = _selectedCategory == null
        ? List.from(allProducts)
        : allProducts.where((p) => p.categoryId == _selectedCategory).toList();

    // Sorting
    if (_sortBy == 'price_low') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_high') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'rating') {
      products.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SheeshAppBar(
        showBackButton: true,
        title: currentCat != null ? '${currentCat.icon} ${currentCat.name}' : 'All Collections',
      ),
      body: Column(
        children: [
          // Category Selector Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ChoiceChip(
                    label: const Text('✨ All Categories'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = null);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.poppins(
                      color: _selectedCategory == null ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) {
                    final isSel = _selectedCategory == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.icon),
                            const SizedBox(width: 4),
                            Text(cat.name),
                          ],
                        ),
                        selected: isSel,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = selected ? cat.id : null);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: GoogleFonts.poppins(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Subheader with Count & Sort Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} Handcrafted items found',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (val) => setState(() => _sortBy = val),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _sortBy == 'popular'
                              ? 'Popular'
                              : _sortBy == 'price_low'
                                  ? 'Price: Low to High'
                                  : _sortBy == 'price_high'
                                      ? 'Price: High to Low'
                                      : 'Highest Rated',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'popular', child: Text('Most Popular')),
                    const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                    const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                    const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
                  ],
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        Text(
                          'No products found in this category',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      return ProductCard(product: products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
