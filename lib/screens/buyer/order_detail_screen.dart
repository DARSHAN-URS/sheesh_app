import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'order_tracking_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late OrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return const Color(0xFF2A7B54);
      case OrderStatus.shipped:
        return const Color(0xFF5A1629);
      case OrderStatus.confirmed:
      case OrderStatus.packed:
        return const Color(0xFFC89B3C);
      case OrderStatus.cancelled:
        return const Color(0xFFD64438);
      case OrderStatus.placed:
      default:
        return const Color(0xFF6D5262);
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Icons.verified_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.packed:
        return Icons.inventory_2_rounded;
      case OrderStatus.confirmed:
        return Icons.handshake_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
      case OrderStatus.placed:
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch orders to get live updates if status changed
    final ordersAsync = ref.watch(ordersProvider);
    final liveOrder = ordersAsync.valueOrNull?.where((o) => o.id == _order.id).firstOrNull;
    if (liveOrder != null) {
      _order = liveOrder;
    }

    final statusColor = _getStatusColor(_order.status);
    final statusIcon = _getStatusIcon(_order.status);
    final estimatedDeliveryDate = _order.orderDate.add(const Duration(days: 3));
    final awbNumber = 'SH-EXP-${_order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SheeshAppBar(
        showBackButton: true,
        title: 'Order #${_order.orderNumber}',
        showCart: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Hero Order Status Card ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _order.status.displayName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _order.status == OrderStatus.delivered
                                  ? 'Delivered safely to ${_order.customerName}'
                                  : _order.status == OrderStatus.cancelled
                                      ? 'Order has been cancelled'
                                      : 'Estimated delivery by ${DateFormat('EEEE, d MMM').format(estimatedDeliveryDate)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _order.status == OrderStatus.delivered
                                    ? const Color(0xFF2A7B54)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),

                  // Courier Partner & AWB tracking pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF3EC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF0DDD4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.airport_shuttle_outlined, size: 16, color: Color(0xFF5A1629)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Partner: Sheesh Local Express • AWB: $awbNumber',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: awbNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('AWB tracking number copied!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                  if (_order.trackingNote != null && _order.trackingNote!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC89B3C).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFC89B3C)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _order.trackingNote!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B4E15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_order.status != OrderStatus.delivered && _order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C1E07), Color(0xFF4A340F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF261017), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELIVERY VERIFICATION OTP',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFFE2C48D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share with courier/artisan upon receiving parcel:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _order.deliveryOtp,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: const Color(0xFF261017),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Live Order Tracking Button ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A1629),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  'Open Dedicated Live Tracking Page 🚚 →',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(order: _order),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // ─── Live Tracking Timeline ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Live Order Tracking',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_order.status == OrderStatus.cancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD64438).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_rounded, color: Color(0xFFD64438), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Cancelled',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD64438),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'If payment was deducted via Razorpay/UPI, full refund will be credited in 2-3 business days.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildTrackingStep(
                      stepNumber: 1,
                      title: 'Order Placed',
                      subtitle: 'Order received by Sheesh platform',
                      timestamp: DateFormat('dd MMM, hh:mm a').format(_order.orderDate),
                      isDone: true,
                      isCurrent: _order.status == OrderStatus.placed,
                      isLast: false,
                    ),
                    _buildTrackingStep(
                      stepNumber: 2,
                      title: 'Confirmed by Artisan',
                      subtitle: 'Moradabad workshop accepted & confirmed order',
                      timestamp: _order.status.stepIndex >= 1
                          ? DateFormat('dd MMM, hh:mm a').format(_order.orderDate.add(const Duration(hours: 3)))
                          : 'Pending confirmation',
                      isDone: _order.status.stepIndex >= 1,
                      isCurrent: _order.status == OrderStatus.confirmed,
                      isLast: false,
                    ),
                    _buildTrackingStep(
                      stepNumber: 3,
                      title: 'Packed with Love',
                      subtitle: 'Craft inspected & safely packed in gift box',
                      timestamp: _order.status.stepIndex >= 2
                          ? DateFormat('dd MMM, hh:mm a').format(_order.orderDate.add(const Duration(hours: 12)))
                          : 'Awaiting packing',
                      isDone: _order.status.stepIndex >= 2,
                      isCurrent: _order.status == OrderStatus.packed,
                      isLast: false,
                    ),
                    _buildTrackingStep(
                      stepNumber: 4,
                      title: 'Out for Delivery',
                      subtitle: 'Dispatched via local Moradabad delivery executive',
                      timestamp: _order.status.stepIndex >= 3
                          ? DateFormat('dd MMM, hh:mm a').format(_order.orderDate.add(const Duration(days: 1, hours: 4)))
                          : 'Scheduled for dispatch',
                      isDone: _order.status.stepIndex >= 3,
                      isCurrent: _order.status == OrderStatus.shipped,
                      isLast: false,
                    ),
                    _buildTrackingStep(
                      stepNumber: 5,
                      title: 'Delivered',
                      subtitle: 'Handed over with Artisan Certificate of Authenticity',
                      timestamp: _order.status == OrderStatus.delivered
                          ? DateFormat('dd MMM, hh:mm a').format(_order.orderDate.add(const Duration(days: 2)))
                          : 'Expected by ${DateFormat('dd MMM').format(estimatedDeliveryDate)}',
                      isDone: _order.status == OrderStatus.delivered,
                      isCurrent: _order.status == OrderStatus.delivered,
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),

            if (_order.status != OrderStatus.delivered && _order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C1E07), Color(0xFF4A340F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF261017), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELIVERY VERIFICATION OTP',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFFE2C48D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share with courier/artisan upon receiving parcel:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _order.deliveryOtp,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: const Color(0xFF261017),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Live Order Tracking Button ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A1629),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  'Open Dedicated Live Tracking Page 🚚 →',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(order: _order),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // ─── Items in This Order ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                        'Items in this Order (${_order.items.length})',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Tap item to view',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  ..._order.items.map((item) {
                    return InkWell(
                      onTap: () {
                        if (item.productId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(productId: item.productId),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: NetworkImageFallback(
                                  imageUrl: item.productImage ?? '',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (item.selectedSize != null) ...[
                                        const SizedBox(width: 8),
                                        Text('• ${item.selectedSize}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textLight)),
                                      ],
                                      if (item.selectedColor != null) ...[
                                        const SizedBox(width: 8),
                                        Text('• ${item.selectedColor}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textLight)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${item.unitPrice.toInt()} each',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toInt()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5A1629),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ─── Delivery Destination & Contact ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Address & Contact',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _order.customerName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _order.customerPhone,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          launchUrl(Uri.parse('tel:${_order.customerPhone}'));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A7B54).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.call, size: 11, color: Color(0xFF2A7B54)),
                              const SizedBox(width: 4),
                              Text(
                                'Call',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2A7B54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _order.deliveryAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDark, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ─── Payment & Price Summary ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                        'Payment & Price Summary',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _order.paymentStatus == 'paid'
                              ? const Color(0xFF2A7B54).withValues(alpha: 0.12)
                              : const Color(0xFFC89B3C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _order.paymentStatus == 'paid' ? 'PAID ✓' : 'PAYMENT DUE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _order.paymentStatus == 'paid' ? const Color(0xFF2A7B54) : const Color(0xFFC89B3C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildPriceRow('Items Subtotal', '₹${_order.subtotal.toInt()}'),
                  if (_order.discount > 0)
                    _buildPriceRow('Artisan Discount', '-₹${_order.discount.toInt()}', isHighlight: true),
                  _buildPriceRow(
                    'Delivery Fee',
                    _order.deliveryFee == 0 ? 'FREE' : '₹${_order.deliveryFee.toInt()}',
                  ),
                  _buildPriceRow('Craft Care & Packaging', 'FREE'),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid / Payable',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '₹${_order.totalAmount.toInt()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5A1629),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF3EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF5A1629)),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Mode: ${_order.paymentMethod.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_order.razorpayPaymentId != null)
                          Text(
                            'ID: ${_order.razorpayPaymentId!.substring(0, 8)}...',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textLight),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── 1-Click Buy Again / Reorder Shortcut ─────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(
                  'Buy Again / Reorder Items 🛍️',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  for (final item in _order.items) {
                    ref.read(cartProvider.notifier).addToCart(
                      item.productId,
                      quantity: item.quantity,
                      selectedSize: item.selectedSize,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${_order.items.length} items from Order #${_order.orderNumber} to your bag!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'VIEW BAG',
                        textColor: AppColors.goldLight,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ─── Actions & Support ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_outlined, size: 16),
                    label: Text(
                      'Tax Invoice',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showInvoiceSheet(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: Text(
                      'Help on WhatsApp',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _openSupportChat,
                  ),
                ),
              ],
            ),

            if (_order.status == OrderStatus.placed || _order.status == OrderStatus.confirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD64438),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: Text(
                    'Cancel this Order',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => _confirmCancelOrder(context),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required String timestamp,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline column (Dot & Line)
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? const Color(0xFF5A1629) : Colors.white,
                border: Border.all(
                  color: isDone ? const Color(0xFF5A1629) : const Color(0xFFE0D0CC),
                  width: isCurrent ? 2.5 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFF5A1629).withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '$stepNumber',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8A6B7E),
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isDone ? const Color(0xFF5A1629) : const Color(0xFFEFE6E2),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Right details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.w600,
                        color: isDone ? AppColors.textPrimary : AppColors.textLight,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isCurrent ? const Color(0xFF5A1629) : AppColors.textLight,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDone ? AppColors.textSecondary : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isHighlight ? const Color(0xFF2A7B54) : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _openSupportChat() async {
    const supportPhone = '918007433744';
    final message = 'Namaste Sheesh Artisan Support 🙏! I need assistance with my Order #${_order.orderNumber}. (Total: ₹${_order.totalAmount.toInt()})';
    final uri = Uri.parse('https://wa.me/$supportPhone?text=${Uri.encodeComponent(message)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _confirmCancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to cancel Order #${_order.orderNumber}? Handcrafted preparations will be stopped.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD64438)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(ordersProvider.notifier).cancelOrder(_order.id, reason: 'Buyer requested cancellation');
                if (mounted) {
                  setState(() {
                    _order.status = OrderStatus.cancelled;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order has been cancelled.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel order: $e')),
                  );
                }
              }
            },
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInvoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sheesh Artisan Invoice', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Original Tax Receipt • Moradabad, UP', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _invoiceMeta('Invoice No:', 'INV-${_order.orderNumber}'),
                    _invoiceMeta('Date:', DateFormat('dd MMMM yyyy, hh:mm a').format(_order.orderDate)),
                    _invoiceMeta('Billed To:', _order.customerName),
                    _invoiceMeta('Phone:', _order.customerPhone),
                    _invoiceMeta('Delivery Address:', _order.deliveryAddress),
                    _invoiceMeta('Payment Method:', _order.paymentMethod.toUpperCase()),
                    _invoiceMeta('Payment Status:', _order.paymentStatus.toUpperCase()),
                    const Divider(height: 20),
                    Text('Itemized Breakdown:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ..._order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item.productName} (x${item.quantity})', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                              ),
                              Text('₹${item.totalPrice.toInt()}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    _invoiceMeta('Subtotal:', '₹${_order.subtotal.toInt()}'),
                    if (_order.discount > 0) _invoiceMeta('Discount:', '-₹${_order.discount.toInt()}'),
                    _invoiceMeta('Delivery Fee:', _order.deliveryFee == 0 ? 'FREE' : '₹${_order.deliveryFee.toInt()}'),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total:', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('₹${_order.totalAmount.toInt()}', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF5A1629))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Thank you for empowering Moradabad women artisans with 100% fair artisan value transfer.\nSupport helpline: support@sheesh.app',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'Invoice: INV-${_order.orderNumber}\nAmount: ₹${_order.totalAmount.toInt()}\nCustomer: ${_order.customerName}\nStatus: ${_order.status.displayName}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice summary copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Invoice Summary'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

