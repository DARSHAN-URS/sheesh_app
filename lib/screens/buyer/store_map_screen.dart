import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../providers/products_provider.dart';
import '../../widgets/network_image_fallback.dart';
import 'seller_storefront_screen.dart';

/// Known Moradabad handicraft hubs and their normalized relative map coordinates (0.0 to 1.0)
class MoradabadHub {
  final String name;
  final String description;
  final double x; // 0.0 (West) to 1.0 (East)
  final double y; // 0.0 (North) to 1.0 (South)
  final double lat;
  final double lng;
  final IconData icon;

  const MoradabadHub({
    required this.name,
    required this.description,
    required this.x,
    required this.y,
    required this.lat,
    required this.lng,
    required this.icon,
  });
}

const List<MoradabadHub> kMoradabadHubs = [
  MoradabadHub(
    name: 'Peetal Mandi',
    description: 'Brassware & Metal Castings Hub',
    x: 0.42,
    y: 0.54,
    lat: 28.8315,
    lng: 78.7650,
    icon: Icons.precision_manufacturing_rounded,
  ),
  MoradabadHub(
    name: 'Bartan Bazaar',
    description: 'Traditional Utensils & Copper Crafts',
    x: 0.52,
    y: 0.50,
    lat: 28.8340,
    lng: 78.7710,
    icon: Icons.soup_kitchen_rounded,
  ),
  MoradabadHub(
    name: 'Civil Lines',
    description: 'Artisan Boutiques & Modern Studios',
    x: 0.65,
    y: 0.32,
    lat: 28.8480,
    lng: 78.7820,
    icon: Icons.storefront_rounded,
  ),
  MoradabadHub(
    name: 'Asalatpura',
    description: 'Intricate Etching & Silver Foil Filigree',
    x: 0.56,
    y: 0.68,
    lat: 28.8260,
    lng: 78.7750,
    icon: Icons.auto_awesome_rounded,
  ),
  MoradabadHub(
    name: 'Sambhal Road',
    description: 'Horn, Bone & Wooden Handicrafts',
    x: 0.30,
    y: 0.78,
    lat: 28.8150,
    lng: 78.7600,
    icon: Icons.forest_rounded,
  ),
  MoradabadHub(
    name: 'Mughalpura',
    description: 'Hand-Cast Brass Bells, Lamps & Idols',
    x: 0.38,
    y: 0.42,
    lat: 28.8390,
    lng: 78.7680,
    icon: Icons.notifications_active_rounded,
  ),
  MoradabadHub(
    name: 'Delhi Road Cluster',
    description: 'Export Guilds & Lacquer Finish Studios',
    x: 0.22,
    y: 0.25,
    lat: 28.8550,
    lng: 78.7450,
    icon: Icons.local_shipping_rounded,
  ),
];

class StoreMapLocation {
  final Seller seller;
  final double x;
  final double y;
  final double lat;
  final double lng;
  final String hubName;
  final double distanceKm;

  const StoreMapLocation({
    required this.seller,
    required this.x,
    required this.y,
    required this.lat,
    required this.lng,
    required this.hubName,
    required this.distanceKm,
  });
}

class StoreMapScreen extends ConsumerStatefulWidget {
  final String? highlightSellerId;

  const StoreMapScreen({super.key, this.highlightSellerId});

  @override
  ConsumerState<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends ConsumerState<StoreMapScreen> with SingleTickerProviderStateMixin {
  final TransformationController _transController = TransformationController();
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _pulseController;

  String _selectedLocality = 'All';
  String? _selectedSellerId;
  bool _isListView = false;
  bool _isDarkSatellite = false;

  final double _canvasWidth = 1400;
  final double _canvasHeight = 1100;

  @override
  void initState() {
    super.initState();
    _selectedSellerId = widget.highlightSellerId;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Center map on Peetal Mandi / Moradabad core after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMap(xRatio: 0.48, yRatio: 0.50, scale: 1.35);
    });
  }

  @override
  void dispose() {
    _transController.dispose();
    _searchCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _centerMap({required double xRatio, required double yRatio, double scale = 1.4}) {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final targetX = xRatio * _canvasWidth;
    final targetY = yRatio * _canvasHeight;

    final double tx = (size.width / 2) - (targetX * scale);
    final double ty = (size.height / 2) - (targetY * scale);

    final matrix = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale);

    setState(() {
      _transController.value = matrix;
    });
  }

  StoreMapLocation _computeLocation(Seller seller, int index) {
    final locText = '${seller.location} ${seller.storeName} ${seller.bio}'.toLowerCase();

    MoradabadHub matchedHub = kMoradabadHubs.first;
    for (final hub in kMoradabadHubs) {
      if (locText.contains(hub.name.toLowerCase())) {
        matchedHub = hub;
        break;
      }
    }

    // Stable jitter based on seller ID hash to prevent marker stacking
    final hash = seller.id.hashCode.abs();
    final angle = (hash % 360) * (math.pi / 180.0);
    final radius = 0.025 + ((hash % 35) / 1000.0);

    final x = (matchedHub.x + radius * math.cos(angle)).clamp(0.08, 0.92);
    final y = (matchedHub.y + radius * math.sin(angle)).clamp(0.08, 0.92);
    final lat = matchedHub.lat + (radius * 0.035 * math.sin(angle));
    final lng = matchedHub.lng + (radius * 0.035 * math.cos(angle));

    final dist = 0.5 + ((hash % 45) / 10.0);

    return StoreMapLocation(
      seller: seller,
      x: x,
      y: y,
      lat: lat,
      lng: lng,
      hubName: matchedHub.name,
      distanceKm: double.parse(dist.toStringAsFixed(1)),
    );
  }

  Future<void> _openDirectionsInGoogleMaps(StoreMapLocation loc) async {
    final encodedStore = Uri.encodeComponent('${loc.seller.storeName}, ${loc.hubName}, Moradabad');
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${loc.lat},${loc.lng}&query_place_id=$encodedStore',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        final browserUrl = Uri.parse('https://maps.google.com/?q=${loc.lat},${loc.lng}');
        await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening location: ${loc.lat}, ${loc.lng}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(allSellersProvider);

    return Scaffold(
      backgroundColor: _isDarkSatellite ? const Color(0xFF14191E) : const Color(0xFFF6F3EE),
      body: sellersAsync.when(
        data: (rawSellers) {
          final sellers = rawSellers.isNotEmpty ? rawSellers : _getSampleArtisans();
          final locations = <StoreMapLocation>[];
          for (int i = 0; i < sellers.length; i++) {
            locations.add(_computeLocation(sellers[i], i));
          }

          // Filter by locality and search
          final query = _searchCtrl.text.trim().toLowerCase();
          final filteredLocations = locations.where((loc) {
            final matchesLocality = _selectedLocality == 'All' ||
                loc.hubName.toLowerCase() == _selectedLocality.toLowerCase();
            final matchesSearch = query.isEmpty ||
                loc.seller.storeName.toLowerCase().contains(query) ||
                loc.seller.name.toLowerCase().contains(query) ||
                loc.seller.location.toLowerCase().contains(query);
            return matchesLocality && matchesSearch;
          }).toList();

          StoreMapLocation? activeLoc;
          if (_selectedSellerId != null) {
            activeLoc = filteredLocations.where((l) => l.seller.id == _selectedSellerId).firstOrNull ??
                locations.where((l) => l.seller.id == _selectedSellerId).firstOrNull;
          }

          return Stack(
            children: [
              // ── 1. The Map Canvas / List View ──
              Positioned.fill(
                child: _isListView
                    ? _buildListView(filteredLocations)
                    : _buildInteractiveMap(filteredLocations, activeLoc),
              ),

              // ── 2. Top Header & Search Bar ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(totalCount: filteredLocations.length),
              ),

              // ── 3. Locality Filter Pills ──
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 0,
                right: 0,
                child: _buildLocalityFilters(),
              ),

              // ── 4. Map Utility Buttons (Recenter & Theme Toggle) ──
              if (!_isListView)
                Positioned(
                  right: 16,
                  bottom: activeLoc != null ? 245 : 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFloatingActionBtn(
                        icon: _isDarkSatellite ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                        tooltip: _isDarkSatellite ? 'Heritage Map View' : 'Dark Satellite View',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isDarkSatellite = !_isDarkSatellite);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildFloatingActionBtn(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Recenter on Moradabad Hub',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _centerMap(xRatio: 0.48, yRatio: 0.50, scale: 1.35);
                        },
                      ),
                    ],
                  ),
                ),

              // ── 5. Selected Store Bottom Preview Card ──
              if (activeLoc != null && !_isListView)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _buildActiveStoreCard(activeLoc),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'Unable to load artisan store map',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(allSellersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── INTERACTIVE MAP CANVAS ────────────────────────────────────────────────
  Widget _buildInteractiveMap(List<StoreMapLocation> locations, StoreMapLocation? activeLoc) {
    return InteractiveViewer(
      transformationController: _transController,
      minScale: 0.8,
      maxScale: 3.5,
      boundaryMargin: const EdgeInsets.all(500),
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
        child: Stack(
          children: [
            // Custom vector painter representing Moradabad topography, Ramganga river, & handicraft corridors
            Positioned.fill(
              child: CustomPaint(
                painter: _MoradabadCartographyPainter(
                  isDark: _isDarkSatellite,
                  pulseAnim: _pulseController,
                ),
              ),
            ),

            // Locality Hub Banners
            for (final hub in kMoradabadHubs)
              Positioned(
                left: hub.x * _canvasWidth - 65,
                top: hub.y * _canvasHeight - 48,
                child: _buildHubBadge(hub),
              ),

            // Store Pins
            for (final loc in locations)
              Positioned(
                left: loc.x * _canvasWidth - 24,
                top: loc.y * _canvasHeight - 48,
                child: _buildStorePin(loc, isSelected: loc.seller.id == _selectedSellerId),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubBadge(MoradabadHub hub) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedLocality = hub.name);
        _centerMap(xRatio: hub.x, yRatio: hub.y, scale: 1.8);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isDarkSatellite
              ? const Color(0xFF1F2937).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.goldDark.withValues(alpha: 0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hub.icon, size: 12, color: AppColors.goldDark),
            const SizedBox(width: 4),
            Text(
              hub.name,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _isDarkSatellite ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorePin(StoreMapLocation loc, {required bool isSelected}) {
    final seller = loc.seller;
    final isFeatured = seller.isFeatured || seller.rating >= 4.8;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedSellerId = seller.id);
        _centerMap(xRatio: loc.x, yRatio: loc.y, scale: 2.1);
      },
      child: AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Store Avatar in Gold Pin Frame
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Pulse ripple for selected / featured pins
                if (isSelected || isFeatured)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (ctx, child) {
                      return Container(
                        width: 54 + (16 * _pulseController.value),
                        height: 54 + (16 * _pulseController.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isSelected ? AppColors.primary : AppColors.gold)
                              .withValues(alpha: 0.35 * (1.0 - _pulseController.value)),
                        ),
                      );
                    },
                  ),

                // Main Pin Circle
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF5A1629), Color(0xFFD64438)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFAA7A1E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: NetworkImageFallback(
                      imageUrl: seller.avatarUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Verified Badge
                if (seller.isVerified)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A7B54),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),

                // Rating Pill
                Positioned(
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A1629),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFFD700)),
                        const SizedBox(width: 2),
                        Text(
                          seller.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Pin Needle
            CustomPaint(
              size: const Size(12, 10),
              painter: _PinNeedlePainter(
                color: isSelected ? const Color(0xFF5A1629) : const Color(0xFFAA7A1E),
              ),
            ),

            // Store Name Label Box
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(maxWidth: 105),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5A1629)
                    : (_isDarkSatellite ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? Colors.white : AppColors.border,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                seller.storeName,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (_isDarkSatellite ? Colors.white : AppColors.textPrimary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTIVE STORE PREVIEW CARD ─────────────────────────────────────────────
  Widget _buildActiveStoreCard(StoreMapLocation loc) {
    final seller = loc.seller;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover Banner & Quick Close
          Stack(
            children: [
              SizedBox(
                height: 80,
                width: double.infinity,
                child: NetworkImageFallback(
                  imageUrl: seller.coverUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSellerId = null),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${loc.distanceKm} km away in ${loc.hubName}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Store Details Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                      ),
                      child: ClipOval(
                        child: NetworkImageFallback(
                          imageUrl: seller.avatarUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & She-Preneur Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  seller.storeName,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (seller.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 15, color: Color(0xFF2A7B54)),
                              ],
                            ],
                          ),
                          Text(
                            'By ${seller.name} • ${seller.location}',
                            style: GoogleFonts.lato(fontSize: 11.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                              const SizedBox(width: 3),
                              Text(
                                '${seller.rating.toStringAsFixed(1)} (${seller.reviewsCount} reviews)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '•  ${seller.productsCount > 0 ? seller.productsCount : 12}+ Craft Items',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Buttons: Visit Store & Get Directions
                Row(
                  children: [
                    // Directions / GPS
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: Text(
                        'Directions',
                        style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openDirectionsInGoogleMaps(loc),
                    ),
                    const SizedBox(width: 10),

                    // Visit Storefront
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.storefront_rounded, size: 16),
                        label: Text(
                          'Visit Storefront',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SellerStorefrontScreen(sellerId: seller.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOP BAR & CONTROLS ────────────────────────────────────────────────────
  Widget _buildTopBar({required int totalCount}) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 10),
      decoration: BoxDecoration(
        color: _isDarkSatellite
            ? const Color(0xFF1E262B).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Back Button
              Container(
                decoration: BoxDecoration(
                  color: _isDarkSatellite ? const Color(0xFF2D3748) : const Color(0xFFF1ECE4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: _isDarkSatellite ? Colors.white : AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Moradabad Artisan Map',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _isDarkSatellite ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A7B54).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalCount Stores',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2A7B54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Direct from workshops, Peetal Mandi & studios',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: _isDarkSatellite ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle List / Map View
              Container(
                decoration: BoxDecoration(
                  color: _isDarkSatellite ? const Color(0xFF2D3748) : const Color(0xFFF1ECE4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isListView ? Icons.map_rounded : Icons.view_agenda_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  tooltip: _isListView ? 'Show Map' : 'Show List',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isListView = !_isListView);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: _isDarkSatellite ? const Color(0xFF2D3748) : const Color(0xFFF8F6F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkSatellite ? Colors.white24 : AppColors.border,
                width: 0.8,
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _isDarkSatellite ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search artisan, store, craft (e.g. Brass, Filigree, Vases)...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: _isDarkSatellite ? Colors.white54 : AppColors.textLight,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOCALITY FILTER PILLS ─────────────────────────────────────────────────
  Widget _buildLocalityFilters() {
    final localities = ['All', ...kMoradabadHubs.map((h) => h.name)];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: localities.length,
        itemBuilder: (ctx, index) {
          final locName = localities[index];
          final isSelected = _selectedLocality.toLowerCase() == locName.toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                locName == 'All' ? '📍 All Hubs' : locName,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (_isDarkSatellite ? Colors.white70 : AppColors.textPrimary),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: _isDarkSatellite ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 0.8,
                ),
              ),
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() => _selectedLocality = locName);

                if (locName != 'All') {
                  final hub = kMoradabadHubs.firstWhere((h) => h.name == locName);
                  _centerMap(xRatio: hub.x, yRatio: hub.y, scale: 2.0);
                } else {
                  _centerMap(xRatio: 0.48, yRatio: 0.50, scale: 1.35);
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ─── LIST VIEW ALTERNATIVE ─────────────────────────────────────────────────
  Widget _buildListView(List<StoreMapLocation> locations) {
    final topPad = MediaQuery.of(context).padding.top + 120;

    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 54, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              'No artisan stores found in this area',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try selecting "All Hubs" or clearing search query.',
              style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 32),
      itemCount: locations.length,
      itemBuilder: (ctx, index) {
        final loc = locations[index];
        final seller = loc.seller;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SellerStorefrontScreen(sellerId: seller.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                        ),
                        child: ClipOval(
                          child: NetworkImageFallback(
                            imageUrl: seller.avatarUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (seller.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2A7B54),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Store Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.storeName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${seller.name} • ${loc.hubName}',
                          style: GoogleFonts.lato(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                            const SizedBox(width: 3),
                            Text(
                              seller.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${loc.distanceKm} km',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Show On Map Action Button
                  IconButton(
                    icon: const Icon(Icons.pin_drop_rounded, color: AppColors.primary),
                    tooltip: 'Pinpoint on Map',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isListView = false;
                        _selectedSellerId = seller.id;
                      });
                      _centerMap(xRatio: loc.x, yRatio: loc.y, scale: 2.2);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDarkSatellite ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isDarkSatellite ? Colors.white24 : AppColors.border,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }

  // Fallback sample Moradabad artisans if backend is empty
  List<Seller> _getSampleArtisans() {
    return const [
      Seller(
        id: 'seller_peetal_1',
        userId: 'u1',
        name: 'Fatima Begum',
        storeName: 'Royal Peetal Creations',
        tagline: 'Hand-etched brass samovars, vases & vintage bells',
        bio: '3rd generation artisan family in Peetal Mandi specializing in classical Mughal brass engraving.',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
        coverUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800',
        location: 'Peetal Mandi, Moradabad',
        categoryId: 'cat_brass',
        rating: 4.9,
        reviewsCount: 148,
        productsCount: 24,
        ordersCompleted: 312,
        isVerified: true,
        isFeatured: true,
        memberSince: '2023',
        responseTime: 'Within 1 hour',
        phoneNumber: '+919548269940',
        craftStory: 'Preserving antique brass techniques passed down by our great-grandmothers.',
      ),
      Seller(
        id: 'seller_bartan_2',
        userId: 'u2',
        name: 'Sunita Sharma',
        storeName: 'Shree Brass & Copper Heritage',
        tagline: 'Pure hammered copper bottles, thalis & dining sets',
        bio: 'Ayurvedic pure copper cookware & traditional Moradabad bartan craft.',
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
        coverUrl: 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800',
        location: 'Bartan Bazaar, Moradabad',
        categoryId: 'cat_kitchenware',
        rating: 4.8,
        reviewsCount: 96,
        productsCount: 18,
        ordersCompleted: 189,
        isVerified: true,
        isFeatured: true,
        memberSince: '2023',
        responseTime: 'Within 2 hours',
        phoneNumber: '+919548269941',
        craftStory: 'Hammered by hand to create durable, therapeutic copper vessel pieces.',
      ),
      Seller(
        id: 'seller_civil_3',
        userId: 'u3',
        name: 'Ayesha Khan',
        storeName: 'Noor Modern Artisan Studio',
        tagline: 'Contemporary brass planter stands & minimalist lighting',
        bio: 'Blending centuries-old brass casting with modern Scandinavian minimalist interior decor.',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        coverUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
        location: 'Civil Lines, Moradabad',
        categoryId: 'cat_decor',
        rating: 5.0,
        reviewsCount: 82,
        productsCount: 15,
        ordersCompleted: 145,
        isVerified: true,
        isFeatured: true,
        memberSince: '2024',
        responseTime: 'Within 30 mins',
        phoneNumber: '+919548269942',
        craftStory: 'Bringing artisanal luxury into modern homes with sustainable brass crafts.',
      ),
      Seller(
        id: 'seller_asalat_4',
        userId: 'u4',
        name: 'Zainab Parveen',
        storeName: 'Zainab Filigree & Silver Plate',
        tagline: 'Intricate silver-coated filigree jewelry & dry fruit platters',
        bio: 'Silver filigree wire art and engraved royal serving trays from Asalatpura.',
        avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400',
        coverUrl: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
        location: 'Asalatpura, Moradabad',
        categoryId: 'cat_jewelry',
        rating: 4.7,
        reviewsCount: 64,
        productsCount: 20,
        ordersCompleted: 110,
        isVerified: true,
        isFeatured: false,
        memberSince: '2024',
        responseTime: 'Within 3 hours',
        phoneNumber: '+919548269943',
        craftStory: 'Hand-twisting pure metal threads to form floral filigree masterpieces.',
      ),
      Seller(
        id: 'seller_sambhal_5',
        userId: 'u5',
        name: 'Pooja Agarwal',
        storeName: 'KalaKriti Horn & Wood Studio',
        tagline: 'Eco-friendly ethically sourced horn combs, cutlery & boxes',
        bio: 'Sustainable horn inlay and natural sheesham wood handcrafted tableware.',
        avatarUrl: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=400',
        coverUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800',
        location: 'Sambhal Road, Moradabad',
        categoryId: 'cat_wood',
        rating: 4.9,
        reviewsCount: 112,
        productsCount: 22,
        ordersCompleted: 240,
        isVerified: true,
        isFeatured: true,
        memberSince: '2023',
        responseTime: 'Within 1 hour',
        phoneNumber: '+919548269944',
        craftStory: 'Upcycling discarded natural horn into smooth, enduring home artifacts.',
      ),
    ];
  }
}

/// Custom Vector Canvas Painter rendering the Moradabad Cartographic layout
class _MoradabadCartographyPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> pulseAnim;

  _MoradabadCartographyPainter({
    required this.isDark,
    required this.pulseAnim,
  }) : super(repaint: pulseAnim);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF14191E) : const Color(0xFFF7F4EF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 1. Subtle Cartographic Grid lines
    final gridPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1F2937).withValues(alpha: 0.5)
          : const Color(0xFFE5DECE).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 45) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 45) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Ramganga River flowing across top-right
    final riverPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1A384D).withValues(alpha: 0.7)
          : const Color(0xFFBCE3EC).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(size.width * 0.1, 0)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.12,
        size.width * 0.75,
        size.height * 0.08,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(riverPath, riverPaint);

    // 3. District Craft Enclave Shaded Zones
    _drawCraftEnclave(
      canvas: canvas,
      center: Offset(size.width * 0.45, size.height * 0.52),
      radius: 170,
      color: const Color(0xFFC89B3C).withValues(alpha: isDark ? 0.08 : 0.12),
      label: 'PEETAL MANDI BRASS HUB',
      isDark: isDark,
    );

    _drawCraftEnclave(
      canvas: canvas,
      center: Offset(size.width * 0.65, size.height * 0.32),
      radius: 140,
      color: const Color(0xFF5A1629).withValues(alpha: isDark ? 0.09 : 0.08),
      label: 'CIVIL LINES DESIGN QUARTER',
      isDark: isDark,
    );

    _drawCraftEnclave(
      canvas: canvas,
      center: Offset(size.width * 0.32, size.height * 0.76),
      radius: 150,
      color: const Color(0xFF2A7B54).withValues(alpha: isDark ? 0.08 : 0.10),
      label: 'SAMBHAL ROAD HANDICRAFT CORRIDOR',
      isDark: isDark,
    );

    // 4. Major Arterial Road Corridors
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFDFD7C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final highwayPaint = Paint()
      ..color = isDark
          ? const Color(0xFFE2B755).withValues(alpha: 0.35)
          : const Color(0xFFD4A737).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Delhi - Moradabad Highway (NH9)
    final nh9Path = Path()
      ..moveTo(0, size.height * 0.38)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.42,
        size.width * 0.65,
        size.height * 0.48,
        size.width,
        size.height * 0.62,
      );
    canvas.drawPath(nh9Path, roadPaint);
    canvas.drawPath(nh9Path, highwayPaint);

    // Sambhal Road Arterial
    final sambhalPath = Path()
      ..moveTo(size.width * 0.48, size.height * 0.45)
      ..lineTo(size.width * 0.22, size.height);
    canvas.drawPath(sambhalPath, roadPaint);

    // Kanth Road to Civil Lines
    final kanthPath = Path()
      ..moveTo(size.width * 0.48, size.height * 0.45)
      ..lineTo(size.width * 0.72, 0);
    canvas.drawPath(kanthPath, roadPaint);
  }

  void _drawCraftEnclave({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
    required String label,
    required bool isDark,
  }) {
    final zonePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withValues(alpha: color.a * 2.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, zonePaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Text Label inside Zone
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white30 : const Color(0xFF8A7760).withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - radius + 14),
    );
  }

  @override
  bool shouldRepaint(covariant _MoradabadCartographyPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _PinNeedlePainter extends CustomPainter {
  final Color color;

  _PinNeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinNeedlePainter oldDelegate) => oldDelegate.color != color;
}

