import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sheesh_brand_emblem.dart';
import '../../widgets/sheesh_app_bar.dart';
import '../../widgets/network_image_fallback.dart';
import '../../widgets/store_photo_picker_sheet.dart';
import 'seller_main_screen.dart';
import 'seller_subscription_screen.dart';

class CraftCategoryItem {
  final String id;
  final String emoji;
  final String title;
  final String description;

  const CraftCategoryItem({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
  });
}

const List<CraftCategoryItem> kCraftCategories = [
  CraftCategoryItem(
    id: 'jewelry',
    emoji: '💎',
    title: 'Jewellery',
    description: 'Gold, silver, diamond, kundan & imitation jewellery',
  ),
  CraftCategoryItem(
    id: 'brass',
    emoji: '🏺',
    title: 'Brassware & Metalcraft',
    description: 'Moradabad peetal artifacts, pooja essentials & vintage vessels',
  ),
  CraftCategoryItem(
    id: 'bridal',
    emoji: '👗',
    title: 'Bridal Wear & Zardozi',
    description: 'Handcrafted zardozi lehengas, dupattas & embroidered attire',
  ),
  CraftCategoryItem(
    id: 'decor',
    emoji: '✨',
    title: 'Home Decor & Artifacts',
    description: 'Carved wooden decor, brass lamps, wall hangings & centerpieces',
  ),
  CraftCategoryItem(
    id: 'pottery',
    emoji: '🎨',
    title: 'Pottery & Terracotta',
    description: 'Clay cookware, ceramic planters, earthen vessels & handcrafted diyas',
  ),
  CraftCategoryItem(
    id: 'textiles',
    emoji: '🧵',
    title: 'Handloom & Textiles',
    description: 'Chanderi sarees, pure silk stoles & organic block-printed linens',
  ),
];

class BrandColorOption {
  final String name;
  final Color primary;
  final Color secondary;

  const BrandColorOption({
    required this.name,
    required this.primary,
    required this.secondary,
  });
}

const List<BrandColorOption> kBrandColors = [
  BrandColorOption(
    name: 'Sheesh Coral',
    primary: Color(0xFFD64438),
    secondary: Color(0xFFB83228),
  ),
  BrandColorOption(
    name: 'Royal Plum',
    primary: Color(0xFF5A1F45),
    secondary: Color(0xFF401431),
  ),
  BrandColorOption(
    name: 'Antique Gold',
    primary: Color(0xFFC89B3C),
    secondary: Color(0xFFA6761A),
  ),
  BrandColorOption(
    name: 'Forest Sage',
    primary: Color(0xFF2A7B54),
    secondary: Color(0xFF1E5B3D),
  ),
  BrandColorOption(
    name: 'Terracotta Rose',
    primary: Color(0xFFDE5D52),
    secondary: Color(0xFFC4483E),
  ),
  BrandColorOption(
    name: 'Indigo Sapphire',
    primary: Color(0xFF254D7A),
    secondary: Color(0xFF1B3859),
  ),
  BrandColorOption(
    name: 'Deep Wine',
    primary: Color(0xFF6A1E2D),
    secondary: Color(0xFF4E1420),
  ),
  BrandColorOption(
    name: 'Sunset Amber',
    primary: Color(0xFFE67E22),
    secondary: Color(0xFFCA6510),
  ),
  BrandColorOption(
    name: 'Midnight Black',
    primary: Color(0xFF24101C),
    secondary: Color(0xFF14070F),
  ),
];

class CreateStoreScreen extends ConsumerStatefulWidget {
  final Seller? existingSeller;
  final int initialStep;
  final bool isRedesigning;

  const CreateStoreScreen({
    super.key,
    this.existingSeller,
    this.initialStep = 0,
    this.isRedesigning = false,
  });

  @override
  ConsumerState<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends ConsumerState<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _artisanNameCtrl;
  late TextEditingController _storeNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _upiCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _panCtrl;

  late CraftCategoryItem _selectedCategory;
  late BrandColorOption _selectedColor;
  late String _coverUrl;
  late String _avatarUrl;

  int _currentStep = 0; // 0 = Your Details, 1 = Shop Details
  bool _isAutoSlug = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    final auth = ref.read(authProvider);
    final seller = widget.existingSeller ?? auth.sellerProfile;

    final bool hasRealSeller = seller != null &&
        seller.id.isNotEmpty &&
        !seller.id.startsWith('seller_current') &&
        seller.storeName.isNotEmpty &&
        seller.storeName != 'My Sheesh Store' &&
        seller.storeName != 'Qaira Creations';

    _selectedCategory = kCraftCategories.firstWhere(
      (c) => c.id == seller?.categoryId,
      orElse: () => kCraftCategories[0],
    );

    _selectedColor = kBrandColors[0];
    _coverUrl = hasRealSeller && seller!.coverUrl.isNotEmpty
        ? seller.coverUrl
        : 'assets/images/backgrounds/craft-studio.jpg';
    _avatarUrl = hasRealSeller && seller!.avatarUrl.isNotEmpty
        ? seller.avatarUrl
        : (auth.avatarUrl ?? 'assets/images/sheesh_logo.png');

    _artisanNameCtrl = TextEditingController(
      text: hasRealSeller && seller!.name.isNotEmpty
          ? seller.name
          : (auth.fullName.isNotEmpty && auth.fullName != 'User' ? auth.fullName : ''),
    );
    _storeNameCtrl = TextEditingController(
      text: hasRealSeller ? seller!.storeName : '',
    );
    _phoneCtrl = TextEditingController(
      text: hasRealSeller && seller?.phoneNumber != null && seller!.phoneNumber!.isNotEmpty
          ? seller.phoneNumber!.replaceAll('+91', '').trim()
          : (auth.supabaseUser?.phone?.replaceAll('+91', '').trim() ?? ''),
    );

    final initialSlug = hasRealSeller ? _generateSlug(seller!.storeName) : '';
    _slugCtrl = TextEditingController(text: initialSlug);

    _taglineCtrl = TextEditingController(
      text: hasRealSeller &&
              seller!.tagline.isNotEmpty &&
              seller.tagline != 'Handcrafted with Love in Moradabad' &&
              seller.tagline != 'Handcrafted with Love & Heritage'
          ? seller.tagline
          : '',
    );
    _locationCtrl = TextEditingController(
      text: hasRealSeller &&
              seller!.location.isNotEmpty &&
              seller.location != 'Moradabad, UP' &&
              seller.location != 'Peetal Mandi, Moradabad'
          ? seller.location
          : (auth.city.isNotEmpty && auth.city != 'Moradabad, UP' ? auth.city : ''),
    );

    String resolvedBio = '';
    if (hasRealSeller) {
      final candidateBio = seller!.craftStory.isNotEmpty ? seller.craftStory : seller.bio;
      if (candidateBio != 'Traditional Moradabad crafts passed down generations.' &&
          candidateBio != 'Moradabad local artisan' &&
          candidateBio != 'Generational Moradabad crafts.' &&
          candidateBio != 'Local artisan specialized in handcrafted treasures.') {
        resolvedBio = candidateBio;
      }
    }
    _bioCtrl = TextEditingController(text: resolvedBio);

    _upiCtrl = TextEditingController(
      text: hasRealSeller ? (seller?.upiId ?? '') : '',
    );
    _gstCtrl = TextEditingController(
      text: hasRealSeller ? (seller?.gstNumber ?? '') : '',
    );
    _panCtrl = TextEditingController(
      text: hasRealSeller ? (seller?.panNumber ?? '') : '',
    );

    _storeNameCtrl.addListener(_onStoreNameChanged);
  }

  void _onStoreNameChanged() {
    if (_isAutoSlug) {
      final slug = _generateSlug(_storeNameCtrl.text);
      if (slug.isNotEmpty) {
        setState(() {
          _slugCtrl.text = slug;
        });
      }
    }
  }

  String _generateSlug(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  @override
  void dispose() {
    _artisanNameCtrl.dispose();
    _storeNameCtrl.removeListener(_onStoreNameChanged);
    _storeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _slugCtrl.dispose();
    _taglineCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _upiCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  void _showCustomizationLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎨', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Customization Locked',
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Storefront visual customization (cover banners, avatars & brand colors) is an Artisan Starter (₹199) and She-Preneur Pro (₹399) feature.\n\nUpgrade now to give your Digital Dukaan a distinctive brand identity!',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Maybe Later', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A1629),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              SellerSubscriptionScreen.show(context);
            },
            child: Text('View Plans 🚀', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLaunchStore() async {
    final artisanName = _artisanNameCtrl.text.trim();
    if (artisanName.isEmpty) {
      _showToast('Please enter your artisan / owner name');
      setState(() => _currentStep = 0);
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showToast('Please enter a valid 10-digit WhatsApp number');
      setState(() => _currentStep = 0);
      return;
    }

    final sName = _storeNameCtrl.text.trim();
    if (sName.isEmpty) {
      _showToast('Please enter your store / shop name');
      setState(() => _currentStep = 1);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';
      final upiId = _upiCtrl.text.trim();
      final gstNumber = _gstCtrl.text.trim();
      final panNumber = _panCtrl.text.trim();

      final auth = ref.read(authProvider);
      final isRealExistingSeller = widget.existingSeller != null &&
          auth.sellerProfile != null &&
          auth.sellerProfile!.id.isNotEmpty &&
          auth.sellerProfile!.id != 'seller_current' &&
          widget.existingSeller!.id != 'seller_current';

      if (isRealExistingSeller || widget.isRedesigning) {
        await ref.read(authProvider.notifier).updateSellerProfile(
              ownerName: artisanName,
              storeName: sName,
              tagline: _taglineCtrl.text.trim(),
              location: _locationCtrl.text.trim(),
              craftStory: _bioCtrl.text.trim(),
              avatarUrl: _avatarUrl,
              coverUrl: _coverUrl,
              upiId: upiId.isNotEmpty ? upiId : null,
              gstNumber: gstNumber.isNotEmpty ? gstNumber : null,
              panNumber: panNumber.isNotEmpty ? panNumber : null,
            );
        if (!mounted) return;
        ref.read(isSellerModeProvider.notifier).state = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.isRedesigning
                      ? 'Storefront redesign saved successfully! ✨'
                      : 'Storefront updated successfully! ✓',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2A7B54),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (widget.isRedesigning) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SellerMainScreen()),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
        }
        return;
      }

      await ref.read(authProvider.notifier).becomeSeller(
            ownerName: artisanName,
            storeName: sName,
            tagline: _taglineCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            location: _locationCtrl.text.trim().isNotEmpty
                ? _locationCtrl.text.trim()
                : 'Moradabad, UP',
            categoryId: _selectedCategory.id,
            phoneNumber: formattedPhone,
            craftStory: _bioCtrl.text.trim(),
            upiId: upiId.isNotEmpty ? upiId : null,
            gstNumber: gstNumber.isNotEmpty ? gstNumber : null,
            panNumber: panNumber.isNotEmpty ? panNumber : null,
            avatarUrl: _avatarUrl,
            coverUrl: _coverUrl,
          );

      if (!mounted) return;

      ref.read(isSellerModeProvider.notifier).state = true;

      // Navigate immediately to subscription selection screen (option 1 free selected by default)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SellerSubscriptionScreen(isFirstTimeOnboarding: true),
        ),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Store "$sName" created! Choose your artisan plan ✨',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ref.read(isSellerModeProvider.notifier).state = true;
        if (widget.existingSeller != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Storefront saved successfully! ✓',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF2A7B54),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SellerMainScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Congratulations! "$sName" is now live on Sheesh ✨',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF2A7B54),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: const Color(0xFFD64438),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isEditing = widget.existingSeller != null;
    final seller = widget.existingSeller ?? ref.watch(authProvider).sellerProfile;
    final storeDisplayName = _storeNameCtrl.text.trim().isNotEmpty
        ? _storeNameCtrl.text.trim()
        : 'Your Store Name';
    final storeSlug = _slugCtrl.text.trim().isNotEmpty
        ? _slugCtrl.text.trim()
        : (_storeNameCtrl.text.trim().isNotEmpty
            ? _generateSlug(_storeNameCtrl.text.trim())
            : 'your-store');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EC),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // ── Background Warm Canvas Gradient ──
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFAF3EC),
                      Color(0xFFFFFBF7),
                      Color(0xFFFAF1E8),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // ── Top-Left Warm Organic Shape ──
            Positioned(
              top: -30,
              left: -35,
              child: Container(
                width: 160,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7D8CA).withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(90),
                    bottomRight: Radius.circular(130),
                    bottomLeft: Radius.circular(100),
                  ),
                ),
              ),
            ),

            // ── Top-Right Soft Warm Circle ──
            Positioned(
              top: size.height * 0.12,
              right: -35,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF9DDD1).withValues(alpha: 0.50),
                ),
              ),
            ),

            // ── Scrollable Form & Content ──
            SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          color: const Color(0xFF261017),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HeaderLogoBadge(size: 26),
                            const SizedBox(width: 8),
                            Text(
                              'Sheश Seller Hub',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF261017),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // balance back button
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header Title & Subtitle ──
                            Text(
                              isEditing
                                  ? 'Edit Store Details'
                                  : (_currentStep == 0 ? 'Artisan Details 👤' : 'Shop Details 🏪'),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF261017),
                                letterSpacing: -0.5,
                              ),
                            ).animate().fadeIn(duration: 400.ms),

                            const SizedBox(height: 4),

                            Text(
                              _currentStep == 0
                                  ? 'Step 1 of 2: Enter your artisan profile, WhatsApp number & workshop location.'
                                  : 'Step 2 of 2: Configure your shop name, craft category, branding & direct UPI payments.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF6D5262),
                                height: 1.4,
                              ),
                            ).animate().fadeIn(delay: 100.ms),

                            const SizedBox(height: 18),

                            // ── Step Navigation Pill Selector ──
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E4D8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5D5C6)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _currentStep = 0),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _currentStep == 0 ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: _currentStep == 0
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.08),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person_rounded,
                                              size: 16,
                                              color: _currentStep == 0
                                                  ? const Color(0xFF5A1629)
                                                  : const Color(0xFF8A6B7E),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '1. Your Details 👤',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight:
                                                    _currentStep == 0 ? FontWeight.bold : FontWeight.w600,
                                                color: _currentStep == 0
                                                    ? const Color(0xFF5A1629)
                                                    : const Color(0xFF8A6B7E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        final name = _artisanNameCtrl.text.trim();
                                        final phone = _phoneCtrl.text.trim();
                                        if (name.isEmpty) {
                                          _showToast('Please enter your name first');
                                          return;
                                        }
                                        if (phone.isEmpty || phone.length < 10) {
                                          _showToast('Please enter a valid WhatsApp number');
                                          return;
                                        }
                                        setState(() => _currentStep = 1);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _currentStep == 1 ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: _currentStep == 1
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.08),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.storefront_rounded,
                                              size: 16,
                                              color: _currentStep == 1
                                                  ? const Color(0xFF5A1629)
                                                  : const Color(0xFF8A6B7E),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '2. Shop Details 🏪',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight:
                                                    _currentStep == 1 ? FontWeight.bold : FontWeight.w600,
                                                color: _currentStep == 1
                                                    ? const Color(0xFF5A1629)
                                                    : const Color(0xFF8A6B7E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_currentStep == 0) ...[
                              _buildArtisanDetailsStep(),
                            ],

                            if (_currentStep == 1) ...[
                              if (seller != null || widget.isRedesigning) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (seller?.canCustomizeStorefront ?? false)
                                        ? const Color(0xFFE8F7ED)
                                        : const Color(0xFFFFF9F2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: (seller?.canCustomizeStorefront ?? false)
                                          ? const Color(0xFFBBE5C8)
                                          : const Color(0xFFF0DDD4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        (seller?.isPlan399 ?? false)
                                            ? '👑'
                                            : ((seller?.isPlan199 ?? false) ? '🌟' : '📦'),
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Active Tier: ${seller?.planDisplayName ?? "Free Plan (₹0)"}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF261017),
                                              ),
                                            ),
                                            Text(
                                              (seller?.canCustomizeStorefront ?? false)
                                                  ? 'Storefront redesign unlocked! Customize your brand palette, cover banner & logo below.'
                                                  : 'Free Plan (2 products). Store name & UPI details editable. Visual custom styling unlocks on ₹199 / ₹399 plans.',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                color: const Color(0xFF6D5262),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // ── Real-Time Interactive Storefront Preview Card ──
                              _buildLiveStorefrontPreview(storeDisplayName, storeSlug)
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.05, end: 0),

                            const SizedBox(height: 24),

                            // ── Section 1: Craft Category ──
                            _buildSectionHeader(
                              icon: Icons.category_outlined,
                              title: 'Craft Category',
                              subtitle: 'Select the primary craft domain for your storefront',
                            ),
                            const SizedBox(height: 10),
                            _buildCategoryPickerCard(),

                            const SizedBox(height: 22),

                            // ── Section 2: Store Name ──
                            _buildSectionHeader(
                              icon: Icons.storefront_rounded,
                              title: 'Store name',
                              subtitle: 'Your public brand name shown to buyers across India',
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _storeNameCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF261017),
                              ),
                              decoration: _inputDecoration(
                                hint: 'e.g. Royal Brass Studio, Noor Zari',
                                prefix: const Icon(
                                  Icons.storefront_outlined,
                                  color: Color(0xFFD64438),
                                  size: 20,
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ── Section 3: Store Motto / Tagline ──
                            _buildSectionHeader(
                              icon: Icons.auto_awesome,
                              title: 'Store Tagline / Motto',
                              subtitle: 'Catchy phrase highlighting your craft heritage',
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _taglineCtrl,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14),
                              decoration: _inputDecoration(
                                hint: 'e.g. Authentic Handcrafted Brass & Heritage',
                                prefix: const Icon(Icons.auto_awesome, color: Color(0xFFC89B3C), size: 18),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ── Section 4: Store Link (Auto Slug & URL Checker) ──
                            _buildSectionHeader(
                              icon: Icons.link_rounded,
                              title: 'Store link',
                              subtitle: 'Your free, permanent digital storefront URL',
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _slugCtrl,
                              onChanged: (val) {
                                _isAutoSlug = false;
                                setState(() {});
                              },
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF261017),
                              ),
                              decoration: _inputDecoration(
                                hint: 'e.g. royal-brass-studio',
                                prefix: const Icon(
                                  Icons.link_rounded,
                                  color: Color(0xFFD64438),
                                  size: 20,
                                ),
                                suffix: const Padding(
                                  padding: EdgeInsets.only(right: 14),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF2A7B54),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  Text(
                                    'sheesh.app/store/$storeSlug',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF8A6B7E),
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_rounded, color: Color(0xFF2A7B54), size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        'This store URL is available.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2A7B54),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Section 5: Brand Color Picker ──
                            _buildSectionHeader(
                              icon: Icons.palette_outlined,
                              title: 'Brand color',
                              subtitle:
                                  'Used for buttons and highlights on your storefront. You can change this later in Appearance.',
                            ),
                            const SizedBox(height: 12),
                            _buildBrandColorPicker(),

                            const SizedBox(height: 24),

                            // ── Section 6: Store Photos & Branding ──
                            _buildSectionHeader(
                              icon: Icons.photo_library_outlined,
                              title: 'Store Photos & Branding',
                              subtitle: 'Choose from Sheesh artisan studios or upload your workshop banner and avatar',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF261017),
                                      side: const BorderSide(color: Color(0xFFEEDCD4)),
                                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.panorama_outlined, size: 16, color: Color(0xFFD64438)),
                                    label: Text(
                                      'Cover Photo',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      if (widget.existingSeller != null && !widget.existingSeller!.canCustomizeStorefront) {
                                        _showCustomizationLockedDialog(context);
                                        return;
                                      }
                                      StorePhotoPickerSheet.show(
                                        context: context,
                                        type: StorePhotoType.cover,
                                        currentUrl: _coverUrl,
                                        onSelected: (url) => setState(() => _coverUrl = url),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF261017),
                                      side: const BorderSide(color: Color(0xFFEEDCD4)),
                                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.account_circle_outlined, size: 16, color: Color(0xFFD64438)),
                                    label: Text(
                                      'Store Avatar',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      if (widget.existingSeller != null && !widget.existingSeller!.canCustomizeStorefront) {
                                        _showCustomizationLockedDialog(context);
                                        return;
                                      }
                                      StorePhotoPickerSheet.show(
                                        context: context,
                                        type: StorePhotoType.avatar,
                                        currentUrl: _avatarUrl,
                                        onSelected: (url) => setState(() => _avatarUrl = url),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ── Section 8: Direct UPI Payment ID ──
                            _buildSectionHeader(
                              icon: Icons.qr_code_2_rounded,
                              title: 'Direct UPI ID (Receive Payments)',
                              subtitle:
                                  'GPay, PhonePe, Paytm or BHIM UPI ID for direct 0% commission buyer payments',
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _upiCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF261017),
                              ),
                              decoration: _inputDecoration(
                                hint: 'e.g. yourname@oksbi or 9876543210@paytm',
                                prefix: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Color(0xFF2A7B54),
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_outlined, color: Color(0xFF2A7B54), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '100% of order payment credited directly to your bank account via UPI.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2A7B54),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Section 9: Business Registration & GST (Optional) ──
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSectionHeader(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'GST & Business Registration',
                                    subtitle: 'Optional • Only if your craft enterprise is registered',
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F7ED),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBBE5C8)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2A7B54), size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Optional',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2A7B54),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Legal exemption microcopy banner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF0DDD4)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Color(0xFFC89B3C), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Under Section 23 of the CGST Act, artisans and handicraft producers with annual turnover under ₹20 Lakhs (or ₹40 Lakhs for goods) are legally exempt from GST. You do not need a GSTIN to launch!',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        height: 1.4,
                                        color: const Color(0xFF6B4226),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // GSTIN TextField
                            TextField(
                              controller: _gstCtrl,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 15,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: const Color(0xFF261017),
                              ),
                              decoration: _inputDecoration(
                                hint: '09AAAAA0000A1Z5 (15-digit GSTIN)',
                                prefix: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Color(0xFF5A1629),
                                  size: 20,
                                ),
                                suffix: _gstCtrl.text.trim().isNotEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(Icons.check_circle_rounded, color: Color(0xFF2A7B54), size: 18),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),

                            // PAN / Business Registration TextField
                            TextField(
                              controller: _panCtrl,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 10,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                color: const Color(0xFF261017),
                              ),
                              decoration: _inputDecoration(
                                hint: 'ABCDE1234F (10-digit PAN Number)',
                                prefix: const Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFF5A1629),
                                  size: 20,
                                ),
                                suffix: _panCtrl.text.trim().isNotEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(Icons.check_circle_rounded, color: Color(0xFF2A7B54), size: 18),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),

                            const SizedBox(height: 32),

                            // ── Navigation Buttons: Back & Launch ──
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _currentStep = 0),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF5A1629),
                                    side: const BorderSide(color: Color(0xFF5A1629)),
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: Text(
                                    'Back',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _selectedColor.primary,
                                          _selectedColor.secondary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _selectedColor.primary.withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLaunchStore,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  widget.isRedesigning
                                                      ? 'Save & View Storefront ✨'
                                                      : (isEditing
                                                          ? 'Save Store Details'
                                                          : 'Launch Your Digital Dukaan ✨'),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(Icons.arrow_forward_rounded, size: 18),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 200.ms),
                            ],

                            const SizedBox(height: 16),

                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: Color(0xFF2A7B54), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '100% Free • Zero Commission on Direct Orders',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6D5262),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisanDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section A: Artisan Full Name
        _buildSectionHeader(
          icon: Icons.badge_outlined,
          title: 'Artisan / Owner Full Name',
          subtitle: 'Your official name or master craftsperson identity',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _artisanNameCtrl,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF261017),
          ),
          decoration: _inputDecoration(
            hint: 'Enter your full name',
            prefix: const Icon(Icons.person_outline_rounded, color: Color(0xFFD64438), size: 20),
          ),
        ),

        const SizedBox(height: 22),

        // Section B: WhatsApp Phone Number
        _buildSectionHeader(
          icon: Icons.phone_outlined,
          title: 'WhatsApp Contact Number',
          subtitle: 'For direct buyer WhatsApp chats, order alerts & delivery rider OTP',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF261017),
          ),
          decoration: _inputDecoration(
            hint: '10-digit WhatsApp number',
            prefix: Container(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+91',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF261017),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Section C: Workshop Location & City
        _buildSectionHeader(
          icon: Icons.location_on_outlined,
          title: 'Workshop Location & City',
          subtitle: 'Where your handcrafted creations are made',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationCtrl,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            hint: 'e.g. Workshop area, City, State',
            prefix: const Icon(Icons.location_pin, color: Color(0xFFD64438), size: 20),
          ),
        ),

        const SizedBox(height: 22),

        // Section D: Artisan Craft Lineage & Heritage Story
        _buildSectionHeader(
          icon: Icons.history_edu_rounded,
          title: 'Artisan Craft Lineage & Bio',
          subtitle: 'Tell buyers about your family craft legacy, techniques & experience',
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioCtrl,
          maxLines: 4,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            height: 1.45,
            color: const Color(0xFF261017),
          ),
          decoration: InputDecoration(
            hintText:
                'Describe your craft tradition, heritage techniques, years of experience, and story...',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFA68D96), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFFFDFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEEDCD4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEEDCD4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _selectedColor.primary, width: 1.8),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),

        const SizedBox(height: 22),

        // Section E: Artisan Profile Avatar
        _buildSectionHeader(
          icon: Icons.account_circle_outlined,
          title: 'Artisan Profile Avatar',
          subtitle: 'Photo shown next to your name and verified artisan badge',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEDCD4)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD64438), width: 2),
                ),
                child: ClipOval(
                  child: NetworkImageFallback(
                    imageUrl: _avatarUrl,
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
                      'Master Artisan Avatar',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose from artisan avatars or your gallery',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF8A6B7E)),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A1629),
                  side: const BorderSide(color: Color(0xFF5A1629)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  StorePhotoPickerSheet.show(
                    context: context,
                    type: StorePhotoType.avatar,
                    currentUrl: _avatarUrl,
                    onSelected: (url) => setState(() => _avatarUrl = url),
                  );
                },
                child: Text(
                  'Change 📸',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Button: Proceed to Step 2
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_selectedColor.primary, _selectedColor.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _selectedColor.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              final name = _artisanNameCtrl.text.trim();
              final phone = _phoneCtrl.text.trim();
              if (name.isEmpty) {
                _showToast('Please enter your artisan or owner name');
                return;
              }
              if (phone.isEmpty || phone.length < 10) {
                _showToast('Please enter a valid 10-digit WhatsApp number');
                return;
              }
              setState(() => _currentStep = 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Shop Details 🏪',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: _selectedColor.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF261017),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: const Color(0xFF8A6B7E),
          ),
        ),
      ],
    );
  }

  /// Interactive Live Storefront Preview Card (Real-Time WYSIWYG)
  Widget _buildLiveStorefrontPreview(String storeName, String slug) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0DDD4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A1521).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with Selected Brand Color / Cover Photo (Interactive)
          GestureDetector(
            onTap: () {
              StorePhotoPickerSheet.show(
                context: context,
                type: StorePhotoType.cover,
                currentUrl: _coverUrl,
                onSelected: (url) => setState(() => _coverUrl = url),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 84,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _selectedColor.primary,
                    _selectedColor.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_coverUrl != null && _coverUrl!.trim().isNotEmpty) ...[
                    NetworkImageFallback(
                      imageUrl: _coverUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ] else ...[
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _coverUrl != null ? 'CHANGE COVER' : 'EDIT COVER',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Avatar Circle (Interactive)
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: GestureDetector(
                    onTap: () {
                      StorePhotoPickerSheet.show(
                        context: context,
                        type: StorePhotoType.avatar,
                        currentUrl: _avatarUrl,
                        onSelected: (url) => setState(() => _avatarUrl = url),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _avatarUrl != null && _avatarUrl!.trim().isNotEmpty
                              ? NetworkImageFallback(
                                  imageUrl: _avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 58,
                                  height: 58,
                                )
                              : Center(
                                  child: Text(
                                    _selectedCategory.emoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _selectedColor.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Store Title & Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              storeName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF261017),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF2A7B54),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'sheesh.app/store/$slug',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _selectedColor.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8EDE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_selectedCategory.emoji} ${_selectedCategory.title}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5A1F45),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F7ED),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_rounded, size: 9, color: Color(0xFF2A7B54)),
                                const SizedBox(width: 3),
                                Text(
                                  'WhatsApp Ready',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2A7B54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Category Dropdown / Selector with Icon & Description
  Widget _buildCategoryPickerCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEDCD4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8EDE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _selectedCategory.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            _selectedCategory.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF261017),
            ),
          ),
          subtitle: Text(
            _selectedCategory.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF8A6B7E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Container(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                children: kCraftCategories.map((cat) {
                  final isSelected = cat.id == _selectedCategory.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD64438).withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: const Color(0xFFD64438).withValues(alpha: 0.35))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: const Color(0xFF261017),
                                  ),
                                ),
                                Text(
                                  cat.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF8A6B7E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFD64438),
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive Horizontal Color Swatches
  Widget _buildBrandColorPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEDCD4)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: kBrandColors.map((brandCol) {
            final isSelected = brandCol.name == _selectedColor.name;
            return GestureDetector(
              onTap: () {
                if (widget.existingSeller != null && !widget.existingSeller!.canCustomizeStorefront) {
                  _showCustomizationLockedDialog(context);
                  return;
                }
                setState(() {
                  _selectedColor = brandCol;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                width: isSelected ? 44 : 36,
                height: isSelected ? 44 : 36,
                decoration: BoxDecoration(
                  color: brandCol.primary,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: brandCol.primary.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFA68D96), fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFFFDFB),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEEDCD4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEEDCD4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _selectedColor.primary, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}

