import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import 'order_detail_screen.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final OrderModel? order;
  final String? initialOrderId;
  final String? initialAwbNumber;

  const OrderTrackingScreen({
    super.key,
    this.order,
    this.initialOrderId,
    this.initialAwbNumber,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> with SingleTickerProviderStateMixin {
  late OrderModel? _selectedOrder;
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _selectedOrder = widget.order;
    if (widget.initialAwbNumber != null) {
      _searchCtrl.text = widget.initialAwbNumber!;
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
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

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Helpline number: $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone, String orderNum) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent('Hello! Regarding my Sheesh Order #$orderNum tracking in Moradabad:');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _makeCall(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final allOrders = ordersAsync.valueOrNull ?? [];

    // Resolve active order
    if (_selectedOrder == null && allOrders.isNotEmpty) {
      if (widget.initialOrderId != null) {
        _selectedOrder = allOrders.where((o) => o.id == widget.initialOrderId || o.orderNumber == widget.initialOrderId).firstOrNull;
      }
      _selectedOrder ??= allOrders.first;
    }

    final order = _selectedOrder;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SheeshAppBar(
        showBackButton: true,
        title: 'Live Order Tracking',
        showCart: false,
      ),
      body: order == null
          ? _buildNoOrdersView(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Order Selector Pill Row (if user has multiple orders) ──
                  if (allOrders.length > 1) ...[
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allOrders.length,
                        itemBuilder: (ctx, idx) {
                          final o = allOrders[idx];
                          final isSelected = o.id == order.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(
                                'Order #${o.orderNumber}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF5A1629),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF5A1629) : AppColors.border,
                                ),
                              ),
                              onSelected: (_) => setState(() => _selectedOrder = o),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Live Courier Canvas Map Visualizer ──
                  _buildLiveRouteMap(order),

                  const SizedBox(height: 16),

                  // ── Estimated Delivery Banner & OTP Card ──
                  _buildEtaAndOtpCard(order),

                  const SizedBox(height: 16),

                  // ── Delivery Partner Live Contact Card ──
                  _buildDeliveryAgentCard(order),

                  const SizedBox(height: 16),

                  // ── Step-by-Step Delivery Timeline ──
                  _buildTrackingTimeline(order),

                  const SizedBox(height: 16),

                  // ── Order Package Summary & Address ──
                  _buildPackageSummary(order),

                  const SizedBox(height: 20),

                  // ── Action Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5A1629),
                            side: const BorderSide(color: Color(0xFF5A1629)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.receipt_long_outlined, size: 16),
                          label: Text(
                            'Full Order Details',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A7B54),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.support_agent_rounded, size: 16),
                          label: Text(
                            'Help & Support',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () => _openWhatsApp('9548269940', order.orderNumber),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // ─── VISUAL ROUTE MAP CANVAS ───────────────────────────────────────────────

  Widget _buildLiveRouteMap(OrderModel order) {
    final status = order.status;
    final isDelivered = status == OrderStatus.delivered;
    final isOut = status == OrderStatus.shipped;

    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E262B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E3840)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background stylized map canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _RouteMapCanvasPainter(pulseAnim: _pulseController),
            ),
          ),

          // Top Info Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDelivered ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDelivered
                            ? 'Delivered in Moradabad'
                            : isOut
                                ? 'Live Transit: Peetal Mandi → Your Door'
                                : 'Artisan Workshop Dispatch Hub',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'GPS LIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4ADE80),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Route Nodes: Origin Workshop
          Positioned(
            left: 28,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC89B3C),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🏺', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 3),
                Text(
                  'Artisan Hub\nPeetal Mandi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),

          // Delivery Van / Transit Marker
          Positioned(
            left: MediaQuery.of(context).size.width * 0.42,
            bottom: 46,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (ctx, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A1629),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD64438).withValues(alpha: 0.5 * (1 - _pulseController.value)),
                            blurRadius: 14 * _pulseController.value,
                            spreadRadius: 6 * _pulseController.value,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 16),
                    );
                  },
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDelivered ? 'Delivered' : 'On the Way (1.8 km)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDelivered ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Destination: Buyer Door
          Positioned(
            right: 28,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A7B54),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('📍', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your Address\nMoradabad',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ETA AND OTP CARD ──────────────────────────────────────────────────────

  Widget _buildEtaAndOtpCard(OrderModel order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final estimatedDate = order.orderDate.add(const Duration(days: 3));
    final otp = order.deliveryOtp;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A1629).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDelivered
                      ? const Color(0xFF2A7B54).withValues(alpha: 0.12)
                      : const Color(0xFF5A1629).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDelivered ? Icons.check_circle_rounded : Icons.access_time_filled_rounded,
                  color: isDelivered ? const Color(0xFF2A7B54) : const Color(0xFF5A1629),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDelivered ? 'Delivered Successfully! 🎉' : 'Arriving by Today, 6:30 PM',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDelivered
                          ? 'Received on ${DateFormat('d MMM yyyy, h:mm a').format(order.orderDate.add(const Duration(days: 2)))}'
                          : 'Courier Partner: Sheesh Moradabad Express Logistics',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isDelivered) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF3EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECD8CD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF2A7B54)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Verification OTP',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Share with rider: $otp',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF261017),
                            letterSpacing: 1.2,
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
                      'SECURE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2A7B54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── DELIVERY AGENT LIVE CARD ──────────────────────────────────────────────

  Widget _buildDeliveryAgentCard(OrderModel order) {
    const riderName = 'Ramesh Kumar';
    const riderPhone = '+919548269940';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Agent Avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF5A1629), Color(0xFF8B263E)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderName,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC89B3C)),
                    const SizedBox(width: 3),
                    Text(
                      '4.9 (540+ deliveries) • Verified Rider',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Call & WhatsApp quick action pills
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_rounded, color: Color(0xFF2A7B54), size: 18),
            ),
            onPressed: () => _makeCall(riderPhone),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('💬', style: TextStyle(fontSize: 14)),
            ),
            onPressed: () => _openWhatsApp(riderPhone, order.orderNumber),
          ),
        ],
      ),
    );
  }

  // ─── STEP BY STEP TRACKING TIMELINE ────────────────────────────────────────

  Widget _buildTrackingTimeline(OrderModel order) {
    final currentStep = order.status.stepIndex;
    final awb = 'SH-EXP-${order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '')}';
    final date = order.orderDate;

    final steps = [
      _TrackingStepItem(
        title: 'Order Confirmed',
        subtitle: 'Payment received & confirmed by artisan',
        timestamp: DateFormat('d MMM, h:mm a').format(date),
        icon: Icons.check_circle_rounded,
        isCompleted: currentStep >= 0,
      ),
      _TrackingStepItem(
        title: 'Handcrafted & Packed',
        subtitle: 'Carefully wrapped in signature heritage box with seal',
        timestamp: currentStep >= 2 ? DateFormat('d MMM, h:mm a').format(date.add(const Duration(hours: 4))) : 'In progress',
        icon: Icons.inventory_2_rounded,
        isCompleted: currentStep >= 2,
      ),
      _TrackingStepItem(
        title: 'Dispatched with Moradabad Express',
        subtitle: 'AWB: $awb (Tap to copy)',
        timestamp: currentStep >= 3 ? DateFormat('d MMM, h:mm a').format(date.add(const Duration(hours: 18))) : 'Scheduled',
        icon: Icons.airport_shuttle_rounded,
        isCompleted: currentStep >= 3,
        onTapSubtitle: () {
          Clipboard.setData(ClipboardData(text: awb));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AWB tracking number copied! ✓'), duration: Duration(seconds: 2)),
          );
        },
      ),
      _TrackingStepItem(
        title: 'Out for Delivery',
        subtitle: 'Rider Ramesh Kumar is nearby your delivery area',
        timestamp: currentStep >= 3 ? 'Today' : 'Upcoming',
        icon: Icons.delivery_dining_rounded,
        isCompleted: currentStep >= 3,
      ),
      _TrackingStepItem(
        title: 'Delivered to Doorstep',
        subtitle: 'Safe handoff completed via OTP verification',
        timestamp: currentStep >= 4 ? DateFormat('d MMM, h:mm a').format(date.add(const Duration(days: 2))) : 'Pending',
        icon: Icons.home_rounded,
        isCompleted: currentStep >= 4,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Shipment Timeline',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3EC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AWB: $awb',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5A1629),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (idx) {
            final s = steps[idx];
            final isLast = idx == steps.length - 1;
            return _buildTimelineRow(s, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(_TrackingStepItem step, bool isLast) {
    final activeColor = step.isCompleted ? const Color(0xFF2A7B54) : const Color(0xFFCBD5E1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Icon & Vertical Connecting Line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: step.isCompleted ? const Color(0xFF2A7B54) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  step.icon,
                  size: 14,
                  color: step.isCompleted ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: activeColor,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Step Text Details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: step.isCompleted ? FontWeight.bold : FontWeight.w600,
                          color: step.isCompleted ? AppColors.textPrimary : AppColors.textLight,
                        ),
                      ),
                      Text(
                        step.timestamp,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: step.isCompleted ? const Color(0xFF2A7B54) : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: step.onTapSubtitle,
                    child: Text(
                      step.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: step.onTapSubtitle != null ? const Color(0xFF5A1629) : AppColors.textSecondary,
                        decoration: step.onTapSubtitle != null ? TextDecoration.underline : null,
                      ),
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

  // ─── PACKAGE ITEMS SUMMARY & DELIVERY DESTINATION ──────────────────────────

  Widget _buildPackageSummary(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Package Contents (${order.items.length} items)',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'Total: ₹${order.totalAmount.toInt()}',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF5A1629)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((it) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF3EC).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: NetworkImageFallback(
                        imageUrl: it.productImage ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.productName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Qty: ${it.quantity} • ₹${it.unitPrice.toInt()}',
                          style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFFD64438)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${order.customerName} • ${order.deliveryAddress}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────────────────────

  Widget _buildNoOrdersView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF5A1629).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined, size: 64, color: Color(0xFF5A1629)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Shipments',
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'When you place an order with Moradabad artisans, you can track the live courier dispatch and arrival right here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A1629),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.storefront_rounded, size: 16),
              label: Text(
                'Explore Artisan Stores 🛍️',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingStepItem {
  final String title;
  final String subtitle;
  final String timestamp;
  final IconData icon;
  final bool isCompleted;
  final VoidCallback? onTapSubtitle;

  _TrackingStepItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.isCompleted,
    this.onTapSubtitle,
  });
}

/// Custom Vector Painter for Stylized Delivery Route on Dark Canvas
class _RouteMapCanvasPainter extends CustomPainter {
  final Animation<double> pulseAnim;

  _RouteMapCanvasPainter({required this.pulseAnim}) : super(repaint: pulseAnim);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF263238).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    // Draw city street grid
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Ramganga River curve (subtle dark cyan)
    final riverPaint = Paint()
      ..color = const Color(0xFF1E3A4C).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.25)
      ..cubicTo(size.width * 0.35, size.height * 0.15, size.width * 0.6, size.height * 0.45, size.width, size.height * 0.3);
    canvas.drawPath(riverPath, riverPaint);

    // Draw dashed delivery route line from origin (28, size.height - 40) to destination (size.width - 28, size.height - 40)
    final routePaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final start = Offset(45, size.height - 52);
    final control = Offset(size.width * 0.45, size.height * 0.45);
    final end = Offset(size.width - 45, size.height - 52);

    final routePath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant _RouteMapCanvasPainter oldDelegate) => true;
}

