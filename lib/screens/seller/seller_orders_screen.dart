import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/sheesh_app_bar.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SheeshAppBar(
        showBackButton: false,
        title: 'Incoming Customer Orders',
        showCart: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(sellerOrdersNotifierProvider.notifier).fetch(),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load orders', style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.read(sellerOrdersNotifierProvider.notifier).fetch(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (orders) => orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textLight),
                      const SizedBox(height: 16),
                      Text('No customer orders yet', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Orders placed in Moradabad will be notified here.', style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildSellerOrderCard(context, ref, order);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSellerOrderCard(BuildContext context, WidgetRef ref, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate),
              style: GoogleFonts.lato(fontSize: 11, color: AppColors.textLight),
            ),

            const Divider(height: 20),

            // Customer Info
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${order.customerName} (${order.customerPhone})',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Items mini summary
            ...order.items.map((it) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${it.quantity}x ${it.productName}',
                      style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${it.totalPrice.toInt()}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 20),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Total: ₹${order.totalAmount.toInt()}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  'Mode: ${order.paymentMethod.toUpperCase()}',
                  style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            if (order.trackingNote != null && order.trackingNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 15, color: AppColors.accentTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tracking / Note: ${order.trackingNote}',
                        style: GoogleFonts.lato(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Status Update Flow Actions
            Row(
              children: [
                if (order.status == OrderStatus.placed) ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        await ref.read(sellerOrdersNotifierProvider.notifier).updateStatus(order.id, 'confirmed');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order Confirmed! Packing notification sent to buyer.')),
                          );
                        }
                      },
                      child: const Text('Accept & Confirm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ] else if (order.status == OrderStatus.confirmed) ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        await ref.read(sellerOrdersNotifierProvider.notifier).updateStatus(order.id, 'packed');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Marked as Packed with love!')),
                          );
                        }
                      },
                      child: const Text('Mark as Packed 📦', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ] else if (order.status == OrderStatus.packed) ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _showDispatchDialog(context, ref, order),
                      child: const Text('Handover for Delivery 🚚', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ] else if (order.status == OrderStatus.shipped) ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        await ref.read(sellerOrdersNotifierProvider.notifier).updateStatus(order.id, 'delivered');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order Delivered successfully! Payment credited.')),
                          );
                        }
                      },
                      child: const Text('Mark as Delivered ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Order Completed & Settled ✓',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDispatchDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    final trackingCtrl = TextEditingController(text: 'Moradabad Express Courier');
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.accentTeal),
              const SizedBox(width: 8),
              Text(
                'Handover Order',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter courier details or delivery notes for Order #${order.orderNumber}:',
                style: GoogleFonts.lato(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: trackingCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Courier / Tracking Info',
                  hintText: 'e.g. Delhivery AWB 948102, Van Delivery',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.qr_code_2_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isUpdating
                  ? null
                  : () async {
                      setState(() => isUpdating = true);
                      final note = trackingCtrl.text.trim();
                      try {
                        await ref.read(sellerOrdersNotifierProvider.notifier).updateStatus(
                          order.id,
                          'shipped',
                          trackingNote: note.isNotEmpty ? note : 'Dispatched with local Moradabad delivery',
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order dispatched! Courier tracking updated.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isUpdating = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update status: $e')),
                          );
                        }
                      }
                    },
              child: isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Dispatch 🚚',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
