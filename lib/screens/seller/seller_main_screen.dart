import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../buyer/buyer_main_screen.dart';
import 'seller_home_screen.dart';
import 'seller_products_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_profile_screen.dart';

class SellerMainScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const SellerMainScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends ConsumerState<SellerMainScreen> {
  late int _currentIndex;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    // Ensure seller mode state is synced when mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(isSellerModeProvider)) {
        ref.read(isSellerModeProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sellerOrders = ref.watch(sellerOrdersProvider).value ?? [];

    // If role switched to buyer mode, route seamlessly
    ref.listen<bool>(isSellerModeProvider, (previous, next) {
      if (previous == true && !next && !_navigating) {
        _navigating = true;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => const BuyerMainScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });

    final List<Widget> screens = [
      const SellerHomeScreen(),
      const SellerProductsScreen(),
      const SellerOrdersScreen(),
      const SellerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.goldDark,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'My Crafts',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.receipt_long_outlined),
                  if (sellerOrders.isNotEmpty)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.goldDark,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${sellerOrders.length}',
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Storefront',
            ),
          ],
        ),
      ),
    );
  }
}
