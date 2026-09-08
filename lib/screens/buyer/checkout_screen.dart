import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';

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
  String _paymentMethod = 'razorpay'; // 'razorpay' or 'cod'
  bool _isProcessing = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Pre-fill name from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      _nameController.text = auth.fullName;
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─── Razorpay Callbacks ───────────────────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment on backend
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
      );

      _pendingOrderId = (result['order'] as Map<String, dynamic>)['id'] as String;

      if (_paymentMethod == 'cod') {
        // COD — order placed immediately
        if (mounted) _showOrderSuccess(_pendingOrderId!);
        return;
      }

      // Launch Razorpay payment sheet
      final razorpayData = result['razorpay'] as Map<String, dynamic>;
      final auth = ref.read(authProvider);

      final options = {
        'key': AppConfig.razorpayKeyId,
        'order_id': razorpayData['order_id'],
        'amount': razorpayData['amount'], // in paise
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
    ref.read(cartProvider.notifier).fetchCart(); // Refresh cart (it's cleared)
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

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

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
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Delivery Details ────────────────────────────
                _sectionTitle('📍 Delivery Details'),
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
                                      width: 44, height: 44,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 44, height: 44,
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
                                    style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Qty: ${item.quantity}${item.selectedSize != null ? " • ${item.selectedSize}" : ""}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12, color: AppColors.textLight,
                                    ),
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
                      if (cartNotifier.discount > 0) ...[
                        const SizedBox(height: 6),
                        _summaryRow(
                          'Discount',
                          '-₹${cartNotifier.discount.toStringAsFixed(0)}',
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
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '₹${cartNotifier.total.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w800,
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
                    width: 24, height: 24,
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
        labelStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textLight, size: 26),
            const SizedBox(width: 12),
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
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight)),
      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: valueColor ?? AppColors.textDark,
        ),
      ),
    ],
  );
}

// ─── Order Success Screen ─────────────────────────────────────────────────────

class _OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const _OrderSuccessScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, size: 64, color: Colors.green.shade600),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 28),

                Text(
                  'Order Placed! 🎉',
                  style: GoogleFonts.poppins(
                    fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 10),

                Text(
                  'Your artisan has been notified and will start crafting your order with love.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
