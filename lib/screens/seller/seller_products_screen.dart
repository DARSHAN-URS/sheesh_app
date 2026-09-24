import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import 'add_product_screen.dart';

class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final sellerId = auth.sellerProfile?.id ?? '';

    final productsAsync = sellerId.isNotEmpty
        ? ref.watch(sellerProductsProvider(sellerId))
        : const AsyncValue.data(<Product>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SheeshAppBar(
        showBackButton: false,
        title: 'My Listed Creations',
        showCart: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          if (sellerId.isNotEmpty) {
            ref.invalidate(sellerProductsProvider(sellerId));
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (sellerId.isNotEmpty) {
            ref.invalidate(sellerProductsProvider(sellerId));
          }
        },
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Unable to load your products', style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(sellerProductsProvider(sellerId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (products) => products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textLight),
                      const SizedBox(height: 16),
                      Text(
                        'No products listed yet',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "+ Add Product" to publish your first handcrafted piece.',
                        style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final updated = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => AddProductScreen(productToEdit: product),
                              ),
                            );
                            if (updated == true && sellerId.isNotEmpty) {
                              ref.invalidate(sellerProductsProvider(sellerId));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: NetworkImageFallback(
                                      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${product.price.toInt()} • ⭐ ${product.rating} (${product.reviewsCount})',
                                        style: GoogleFonts.lato(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            product.inStock ? 'In Stock ✓' : 'Out of Stock ✕',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: product.inStock ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Stock Switch & Menu
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: product.inStock,
                                        activeThumbColor: AppColors.primary,
                                        onChanged: (val) async {
                                          try {
                                            await apiService.put('/products/${product.id}', data: {'in_stock': val});
                                            if (sellerId.isNotEmpty) {
                                              ref.invalidate(sellerProductsProvider(sellerId));
                                            }
                                          } catch (_) {}
                                        },
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                      padding: EdgeInsets.zero,
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          final updated = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => AddProductScreen(productToEdit: product),
                                            ),
                                          );
                                          if (updated == true && sellerId.isNotEmpty) {
                                            ref.invalidate(sellerProductsProvider(sellerId));
                                          }
                                        } else if (value == 'delete') {
                                          _confirmDeleteProduct(context, ref, product, sellerId);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text('Edit Details'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: AppColors.error)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, Product product, String sellerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Product?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to remove "${product.name}" from your catalog?',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiService.delete('/products/${product.id}');
                if (sellerId.isNotEmpty) {
                  ref.invalidate(sellerProductsProvider(sellerId));
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
