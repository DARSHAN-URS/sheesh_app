import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../seller/seller_main_screen.dart';
import '../seller/seller_onboarding_screen.dart';
import 'buyer_home_screen.dart';
import 'category_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'buyer_profile_screen.dart';

class BuyerMainScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const BuyerMainScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends ConsumerState<BuyerMainScreen> {
  late int _currentIndex;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(isSellerModeProvider)) {
        ref.read(isSellerModeProvider.notifier).state = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = ref.watch(wishlistProvider);
    final cartItems = ref.watch(cartProvider).value ?? [];
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    // Listen for tab switch requests from child widgets (e.g. Profile quick links)
    ref.listen<int>(buyerTabIndexProvider, (previous, next) {
      if (next != _currentIndex && next >= 0 && next < 4) {
        setState(() => _currentIndex = next);
      }
    });

    // If role switched to seller mode from the top bar or profile, route seamlessly
    ref.listen<bool>(isSellerModeProvider, (previous, next) {
      if (previous == false && next && !_navigating) {
        final auth = ref.read(authProvider);
        if (!auth.isSeller && auth.sellerProfile == null) {
          // If accessing seller mode for the first time, route to onboarding & registration
          ref.read(isSellerModeProvider.notifier).state = false;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SellerOnboardingScreen()),
          );
          return;
        }
        _navigating = true;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => const SellerMainScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });

    final List<Widget> screens = [
      const BuyerHomeScreen(),
      const CategoryScreen(),
      const CartScreen(isTab: true),
      const BuyerProfileScreen(),
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
              color: AppColors.primary.withValues(alpha: 0.04),
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
          selectedItemColor: AppColors.coral,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  if (cartCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD64438),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_rounded),
                  if (cartCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD64438),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
