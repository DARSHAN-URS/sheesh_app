import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../core/config.dart';
import '../../models/address.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/addresses_provider.dart';
import '../../services/api_service.dart';
import '../../utils/delivery_estimate.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();

  String _paymentMethod = 'razorpay'; // 'razorpay' or 'cod'
  bool _isProcessing = false;
  late Razorpay _razorpay;

  // Coupon state
  String? _appliedCouponCode;
  double _appliedDiscountAmount = 0;
  String? _appliedCouponDescription;
  bool _isValidatingCoupon = false;

  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Pre-fill name, phone, and address from profile and past orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (_nameController.text.isEmpty && auth.fullName.isNotEmpty) {
        _nameController.text = auth.fullName;
      }
      final addresses = ref.read(addressesProvider).valueOrNull ?? [];
      if (addresses.isNotEmpty) {
        final defaultAddr = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        _selectAddress(defaultAddr);
      } else {
        final orders = ref.read(ordersProvider).valueOrNull ?? [];
        if (orders.isNotEmpty) {
          final lastOrder = orders.first;
          if (_addressController.text.isEmpty && lastOrder.deliveryAddress.isNotEmpty) {
            _addressController.text = lastOrder.deliveryAddress;
          }
          if (_phoneController.text.isEmpty && lastOrder.customerPhone.isNotEmpty) {
            _phoneController.text = lastOrder.customerPhone;
          }
        } else {
          final phone = auth.profile?['phone'] as String? ?? '';
          if (_phoneController.text.isEmpty && phone.isNotEmpty) {
            _phoneController.text = phone;
          }
          final city = auth.profile?['city'] as String? ?? '';
          if (_addressController.text.isEmpty && city.isNotEmpty) {
            _addressController.text = city;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _selectAddress(SavedAddress addr) {
    setState(() {
      _selectedAddressId = addr.id;
      _nameController.text = addr.name;
      _phoneController.text = addr.phone;
      _addressController.text = addr.formattedAddress;
    });
  }

  // ─── Razorpay Callbacks ───────────────────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final pendingOrderId = _pendingOrderId;
    if (pendingOrderId == null) return;
    try {
      await ref.read(ordersProvider.notifier).verifyPayment(
        orderId: pendingOrderId,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (!mounted) return;
      _showOrderSuccess(pendingOrderId);
    } catch (e) {
      _showError('Payment verification failed. Contact support.');
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    _showError('Payment failed: ${response.message}');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
  }

  // ─── Coupon Validation ────────────────────────────────────────────────────

  Future<void> _applyCoupon(double cartSubtotal) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isValidatingCoupon = true);
    try {
      final res = await apiService.post('/coupons/validate', data: {
        'code': code,
        'cart_subtotal': cartSubtotal,
      }) as Map<String, dynamic>;
      setState(() {
        _appliedCouponCode = res['code'] as String;
        _appliedDiscountAmount = (res['discount_amount'] as num).toDouble();
        _appliedCouponDescription = res['description'] as String?;
        _isValidatingCoupon = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon "$code" applied! Saved ₹${_appliedDiscountAmount.toInt()} 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isValidatingCoupon = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _appliedDiscountAmount = 0;
      _appliedCouponDescription = null;
      _couponController.clear();
    });
  }

  // ─── Order Flow ───────────────────────────────────────────────────────────

  String? _pendingOrderId;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final result = await ref.read(ordersProvider.notifier).placeOrder(
        deliveryAddress: _addressController.text.trim(),
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        paymentMethod: _paymentMethod,
        couponCode: _appliedCouponCode,
      );

      _pendingOrderId = (result['order'] as Map<String, dynamic>)['id'] as String;

      if (_paymentMethod == 'cod') {
        if (mounted) _showOrderSuccess(_pendingOrderId!);
        return;
      }

      final razorpayData = result['razorpay'] as Map<String, dynamic>;
      final auth = ref.read(authProvider);

      final options = {
        'key': AppConfig.razorpayKeyId,
        'order_id': razorpayData['order_id'],
        'amount': razorpayData['amount'],
        'currency': razorpayData['currency'] ?? 'INR',
        'name': 'Sheesh — Artisan Marketplace',
        'description': 'Order #${_pendingOrderId?.substring(0, 8)}',
        'prefill': {
          'name': _nameController.text.trim(),
          'contact': _phoneController.text.trim(),
          'email': auth.supabaseUser?.email ?? '',
        },
        'theme': {'color': '#9E1B4C'},
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError(e.toString());
    }
  }

  void _showOrderSuccess(String orderId) {
    ref.read(cartProvider.notifier).fetchCart();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => _OrderSuccessScreen(orderId: orderId)),
      (route) => route.isFirst,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _showAddAddressSheet() {
    final nameCtrl = TextEditingController(text: _nameController.text);
    final phoneCtrl = TextEditingController(text: _phoneController.text);
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Moradabad');
    final pinCtrl = TextEditingController(text: '244001');
    String label = 'Home';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add New Delivery Address', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Label selector
                Row(
                  children: ['Home', 'Work', 'Other'].map((l) {
                    final isSel = label == l;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(l, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                        selected: isSel,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        onSelected: (val) => setSheetState(() => label = l),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Recipient Name')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Phone')),
                const SizedBox(height: 10),
                TextField(controller: streetCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Flat / House No. / Street / Colony')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: pinCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN Code'))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (streetCtrl.text.trim().isEmpty) return;
                            setSheetState(() => isSaving = true);
                            final created = await ref.read(addressesProvider.notifier).addAddress(
                              label: label,
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              street: streetCtrl.text.trim(),
                              city: cityCtrl.text.trim(),
                              postalCode: pinCtrl.text.trim(),
                              isDefault: true,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (created != null) {
                              _selectAddress(created);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save & Deliver Here', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final effectiveDiscount = max(cartNotifier.discount, _appliedDiscountAmount);
          final finalTotal = max(0.0, cartNotifier.subtotal + cartNotifier.deliveryFee - effectiveDiscount);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Estimated Delivery Banner ───────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.goldDark, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated Arrival: ${DeliveryEstimate.getEstimate()} • Free delivery over ₹999',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Saved Address Book ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('📍 Delivery Address'),
                    TextButton.icon(
                      onPressed: _showAddAddressSheet,
                      icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppColors.primary),
                      label: Text('+ Add New', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                addressesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (addresses) {
                    if (addresses.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      height: 84,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: addresses.length,
                        itemBuilder: (ctx, i) {
                          final addr = addresses[i];
                          final isSelected = _selectedAddressId == addr.id;
                          return GestureDetector(
                            onTap: () => _selectAddress(addr),
                            child: Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12, bottom: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(addr.label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    addr.name,
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    addr.formattedAddress,
                                    style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _field(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Name for delivery',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '10-digit number',
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v?.length ?? 0) < 10 ? 'Enter valid number' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _addressController,
                  label: 'Delivery Address',
                  hint: 'House no., street, area, city, pincode',
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 28),

                // ── Promo / Coupon Code Section ─────────────────
                _sectionTitle('🎟️ Apply Coupon / Promo Code'),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter code (e.g. PEETAL10, SHEESH100)',
                                hintStyle: GoogleFonts.lato(fontSize: 12, color: AppColors.textLight),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _isValidatingCoupon ? null : () => _applyCoupon(cartNotifier.subtotal),
                            child: _isValidatingCoupon
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Apply', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      if (_appliedCouponCode != null) ...[
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Applied: $_appliedCouponCode (-₹${_appliedDiscountAmount.toInt()})',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                  if (_appliedCouponDescription != null && _appliedCouponDescription!.isNotEmpty)
                                    Text(
                                      _appliedCouponDescription!,
                                      style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _removeCoupon,
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Payment Method ──────────────────────────────
                _sectionTitle('💳 Payment Method'),
                const SizedBox(height: 12),

                _paymentOption(
                  value: 'razorpay',
                  title: 'Pay Online',
                  subtitle: 'UPI, Cards, NetBanking, Wallets',
                  icon: Icons.payment_rounded,
                ),
                const SizedBox(height: 10),
                _paymentOption(
                  value: 'cod',
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your order arrives',
                  icon: Icons.local_atm_rounded,
                ),

                const SizedBox(height: 28),

                // ── Order Summary ───────────────────────────────
                _sectionTitle('🛍️ Order Summary'),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.product.imageUrls.isNotEmpty
                                  ? Image.network(
                                      item.product.imageUrls.first,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 44,
                                      height: 44,
                                      color: AppColors.surface,
                                      child: const Icon(Icons.shopping_bag_outlined),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Qty: ${item.quantity}${item.selectedSize != null ? " • ${item.selectedSize}" : ""}',
                                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 24),
                      _summaryRow('Subtotal', '₹${cartNotifier.subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      _summaryRow(
                        'Delivery',
                        cartNotifier.deliveryFee == 0 ? 'FREE' : '₹${cartNotifier.deliveryFee.toStringAsFixed(0)}',
                        valueColor: cartNotifier.deliveryFee == 0 ? Colors.green : null,
                      ),
                      if (effectiveDiscount > 0) ...[
                        const SizedBox(height: 6),
                        _summaryRow(
                          _appliedCouponCode != null ? 'Coupon ($_appliedCouponCode)' : 'Special Discount',
                          '-₹${effectiveDiscount.toStringAsFixed(0)}',
                          valueColor: Colors.green,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '₹${finalTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    _paymentMethod == 'cod' ? 'Place Order (COD)' : 'Pay Now',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
  ).animate().fadeIn();

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13),
        hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13),
      ),
    ).animate().fadeIn();
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white70,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textLight, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 22,
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13)),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor ?? AppColors.textDark),
        ),
      ],
    );
  }
}

// ─── Order Success Screen ─────────────────────────────────────────────────────

class _OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const _OrderSuccessScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.green, size: 52),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  'Order Placed! 🎉',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Thank you for supporting Moradabad women artisans. Your order has been notified.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Order ID: #${orderId.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
