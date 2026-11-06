import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../widgets/network_image_fallback.dart';
import '../../utils/whatsapp_helper.dart';
import 'seller_storefront_screen.dart';

/// Known Moradabad handicraft hubs and their real GPS coordinates
class MoradabadHub {
  final String name;
  final String description;
  final double lat;
  final double lng;
  final IconData icon;

  const MoradabadHub({
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.icon,
  });
}

const List<MoradabadHub> kMoradabadHubs = [
  MoradabadHub(
    name: 'Peetal Mandi',
    description: 'Brassware & Metal Castings Hub',
    lat: 28.8352,
    lng: 78.7758,
    icon: Icons.precision_manufacturing_rounded,
  ),
  MoradabadHub(
    name: 'Bartan Bazaar',
    description: 'Traditional Utensils & Copper Crafts',
    lat: 28.8340,
    lng: 78.7710,
    icon: Icons.soup_kitchen_rounded,
  ),
  MoradabadHub(
    name: 'Civil Lines',
    description: 'Artisan Boutiques & Modern Studios',
    lat: 28.8465,
    lng: 78.7668,
    icon: Icons.storefront_rounded,
  ),
  MoradabadHub(
    name: 'Asalatpura',
    description: 'Intricate Etching & Silver Foil Filigree',
    lat: 28.8260,
    lng: 78.7750,
    icon: Icons.auto_awesome_rounded,
  ),
  MoradabadHub(
    name: 'Sambhal Road',
    description: 'Horn, Bone & Wooden Handicrafts',
    lat: 28.8150,
    lng: 78.7600,
    icon: Icons.forest_rounded,
  ),
  MoradabadHub(
    name: 'Mughalpura',
    description: 'Hand-Cast Brass Bells, Lamps & Idols',
    lat: 28.8390,
    lng: 78.7680,
    icon: Icons.notifications_active_rounded,
  ),
  MoradabadHub(
    name: 'Delhi Road Cluster',
    description: 'Export Guilds & Lacquer Finish Studios',
    lat: 28.8550,
    lng: 78.7450,
    icon: Icons.local_shipping_rounded,
  ),
];

class StoreMapLocation {
  final Seller seller;
  final Offset pixelOffset;
  final double lat;
  final double lng;
  final String hubName;
  final double distanceKm;

  const StoreMapLocation({
    required this.seller,
    required this.pixelOffset,
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
  late TransformationController _transController;
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _pulseController;

  String _selectedLocality = 'All';
  String? _selectedSellerId;
  bool _isListView = false;
  bool _isDarkSatellite = false;

  // Real center coordinates for Moradabad, Uttar Pradesh
  static const double kMoradabadCenterLat = 28.8386;
  static const double kMoradabadCenterLng = 78.7733;
  static const int kMapZoom = 14;

  // 6x6 tile grid of 256x256 = 1536x1536 px (Zoom 14 Moradabad tile is 11776, 6820)
  static const double kCanvasSize = 1536.0;
  static const int kBaseTileX = 11776;
  static const int kBaseTileY = 6820;
  static const int kTileStartCol = kBaseTileX - 3;
  static const int kTileStartRow = kBaseTileY - 3;

  @override
  void initState() {
    super.initState();
    _selectedSellerId = widget.highlightSellerId;
    _transController = TransformationController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Center on Moradabad Core once layout measurements are known
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnGeo(kMoradabadCenterLat, kMoradabadCenterLng, scale: 1.15);
    });
  }

  @override
  void dispose() {
    _transController.dispose();
    _searchCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Converts real Lat/Lng into pixel coordinates on the 1536x1536 Web Mercator tile grid
  Offset _geoToPixel(double lat, double lng) {
    const int numTiles = 1 << kMapZoom; // 16384
    final double xTile = ((lng + 180.0) / 360.0) * numTiles;
    final double latRad = lat * math.pi / 180.0;
    final double yTile = ((1.0 - (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi)) / 2.0) * numTiles;

    final double pixelX = (xTile - kTileStartCol) * 256.0;
    final double pixelY = (yTile - kTileStartRow) * 256.0;

    return Offset(
      pixelX.clamp(0.0, kCanvasSize),
      pixelY.clamp(0.0, kCanvasSize),
    );
  }

  /// Centers the interactive map strictly on real geo coordinates
  void _centerMapOnGeo(double lat, double lng, {double scale = 1.2}) {
    if (!mounted) return;
    final media = MediaQuery.of(context).size;
    final pixelPos = _geoToPixel(lat, lng);

    final double tx = (media.width / 2) - (pixelPos.dx * scale);
    final double ty = (media.height / 2) - (pixelPos.dy * scale);

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

    // Stable deterministic offset around hub to avoid marker overlap
    final hash = seller.id.hashCode.abs();
    final angle = (hash % 360) * (math.pi / 180.0);
    final distKm = 0.3 + ((hash % 35) / 10.0); // 0.3 to 3.8 km

    // 1 deg lat ≈ 111 km, 1 deg lng ≈ 97 km at Moradabad latitude
    final dLat = (distKm / 111.0) * math.sin(angle);
    final dLng = (distKm / 97.0) * math.cos(angle);

    final realLat = matchedHub.lat + dLat;
    final realLng = matchedHub.lng + dLng;
    final pixelOffset = _geoToPixel(realLat, realLng);

    return StoreMapLocation(
      seller: seller,
      pixelOffset: pixelOffset,
      lat: realLat,
      lng: realLng,
      hubName: matchedHub.name,
      distanceKm: double.parse(distKm.toStringAsFixed(1)),
    );
  }

  Future<void> _openDirectionsInGoogleMaps(StoreMapLocation loc) async {
    final encodedStore = Uri.encodeComponent('${loc.seller.storeName}, ${loc.hubName}, Moradabad, Uttar Pradesh');
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${loc.lat},${loc.lng}&query=$encodedStore',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsUrl);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Artisan Location: ${loc.hubName}, Moradabad (GPS: ${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)})'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(allSellersProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _isDarkSatellite ? const Color(0xFF14191E) : const Color(0xFFF6F3EE),
      body: sellersAsync.when(
        data: (rawSellers) {
          final sellers = List<Seller>.from(rawSellers.isNotEmpty ? rawSellers : _getSampleArtisans());
          
          // Ensure current user's seller store appears on map if active
          if (auth.isSeller && auth.sellerProfile != null) {
            final exists = sellers.any((s) => s.id == auth.sellerProfile!.id);
            if (!exists) {
              sellers.insert(0, auth.sellerProfile!);
            }
          }

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
              // ── 1. The Interactive Slippy Map Canvas / List View ──
              Positioned.fill(
                child: _isListView
                    ? _buildListView(filteredLocations)
                    : _buildInteractiveMap(filteredLocations, activeLoc),
              ),

              // ── 2. Unified Top Header (Title + Search + Hub Pills, Never Overlaps) ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildUnifiedHeader(totalCount: filteredLocations.length),
              ),

              // ── 3. Floating Map Controls (Theme Toggle & Recenter) ──
              if (!_isListView)
                Positioned(
                  right: 16,
                  bottom: activeLoc != null ? 245 : 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFloatingActionBtn(
                        icon: _isDarkSatellite ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                        tooltip: _isDarkSatellite ? 'Heritage Streets View' : 'Dark Satellite View',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isDarkSatellite = !_isDarkSatellite);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildFloatingActionBtn(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Recenter on Peetal Mandi',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _centerMapOnGeo(kMoradabadCenterLat, kMoradabadCenterLng, scale: 1.35);
                        },
                      ),
                    ],
                  ),
                ),

              // ── 4. Selected Store Bottom Preview Card ──
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

  // ─── INTERACTIVE MAP CANVAS WITH REAL SLIPPY TILES ──────────────────────────
  Widget _buildInteractiveMap(List<StoreMapLocation> locations, StoreMapLocation? activeLoc) {
    final userPos = _geoToPixel(kMoradabadCenterLat, kMoradabadCenterLng);
    final auth = ref.watch(authProvider);

    return InteractiveViewer(
      transformationController: _transController,
      constrained: false,
      minScale: 0.5,
      maxScale: 3.5,
      boundaryMargin: const EdgeInsets.all(700),
      child: SizedBox(
        width: kCanvasSize,
        height: kCanvasSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Real Slippy Map Tile Grid Layer (CartoDB Voyager / Dark Matter)
            _buildRealMapTileGrid(),

            // 2. Ramganga River & Geographic Accent Overlay
            CustomPaint(
              size: const Size(kCanvasSize, kCanvasSize),
              painter: _MoradabadOverlayPainter(isDark: _isDarkSatellite),
            ),

            // 3. Moradabad Handicraft Hub Badges
            for (final hub in kMoradabadHubs) ...[
              _buildHubPositioned(hub),
            ],

            // 4. Center User Location / You are in Moradabad Live Marker (Fixed Stationary Anchor)
            Positioned(
              left: userPos.dx - 50,
              top: userPos.dy - 50,
              width: 100,
              height: 100,
              child: _buildUserAvatarMarker(auth.avatarUrl, auth.fullName),
            ),

            // 5. Artisan Store Pins
            for (final loc in locations)
              Positioned(
                left: loc.pixelOffset.dx - 24,
                top: loc.pixelOffset.dy - 48,
                child: _buildStorePin(loc, isSelected: loc.seller.id == _selectedSellerId),
              ),
          ],
        ),
      ),
    );
  }

  /// 6x6 Tile Grid of OpenStreetMap / ESRI slippy map tiles (100% Free, Zero API Keys, No Watermarks)
  Widget _buildRealMapTileGrid() {
    return Stack(
      children: [
        for (int row = 0; row < 6; row++)
          for (int col = 0; col < 6; col++)
            Positioned(
              left: col * 256.0,
              top: row * 256.0,
              width: 256.0,
              height: 256.0,
              child: CachedNetworkImage(
                imageUrl: _isDarkSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$kMapZoom/${kTileStartRow + row}/${kTileStartCol + col}'
                    : 'https://tile.openstreetmap.org/$kMapZoom/${kTileStartCol + col}/${kTileStartRow + row}.png',
                httpHeaders: const {
                  'User-Agent': 'SheeshMoradabadArtisanApp/1.0 (contact: info@sheesh.app)'
                },
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: _isDarkSatellite ? const Color(0xFF14191E) : const Color(0xFFF7F4EF),
                ),
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/$kMapZoom/${kTileStartRow + row}/${kTileStartCol + col}',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: _isDarkSatellite ? const Color(0xFF14191E) : const Color(0xFFF7F4EF),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildHubPositioned(MoradabadHub hub) {
    final pos = _geoToPixel(hub.lat, hub.lng);
    return Positioned(
      left: pos.dx - 60,
      top: pos.dy - 40,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedLocality = hub.name);
          _centerMapOnGeo(hub.lat, hub.lng, scale: 1.8);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isDarkSatellite
                ? const Color(0xFF1F2937).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.goldDark.withValues(alpha: 0.45),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
      ),
    );
  }

  /// User Live Location Marker with Fixed Stationary Position and Concentric Pulse
  Widget _buildUserAvatarMarker(String? avatarUrl, String userName) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Concentric Animated Radar Ripple (Stationary anchor at dead center)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = _pulseController.value;
              final rippleDiameter = 40.0 + (pulseValue * 48.0);
              final rippleOpacity = (1.0 - pulseValue).clamp(0.0, 0.6);

              return Container(
                width: rippleDiameter,
                height: rippleDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD64438).withValues(alpha: rippleOpacity * 0.45),
                    width: 2.0,
                  ),
                  color: const Color(0xFFD64438).withValues(alpha: rippleOpacity * 0.08),
                ),
              );
            },
          ),

          // 2. Fixed Anchor: User Location Tag + Avatar Emblem (Never shifts or wobbles)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A1629),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'You are here',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A1629), Color(0xFFD64438)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A1629).withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImageFallback(imageUrl: avatarUrl, fit: BoxFit.cover)
                      : const Center(
                          child: Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorePin(StoreMapLocation loc, {required bool isSelected}) {
    final seller = loc.seller;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedSellerId = seller.id);
        _centerMapOnGeo(loc.lat, loc.lng, scale: 1.8);
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
                if (isSelected)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (ctx, child) {
                      return Container(
                        width: 52 + (14 * _pulseController.value),
                        height: 52 + (14 * _pulseController.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.35 * (1.0 - _pulseController.value)),
                        ),
                      );
                    },
                  ),

                // Main Pin Circle
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
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
                      child: const Icon(Icons.check, size: 9, color: Colors.white),
                    ),
                  ),

                // Rating Pill
                Positioned(
                  top: -7,
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
              constraints: const BoxConstraints(maxWidth: 110),
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

  // ─── UNIFIED TOP HEADER BAR (TITLE + SEARCH + HUB CHIPS) ────────────────────
  Widget _buildUnifiedHeader({required int totalCount}) {
    final topPad = MediaQuery.of(context).padding.top;
    final localities = ['All', ...kMoradabadHubs.map((h) => h.name)];

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
      decoration: BoxDecoration(
        color: _isDarkSatellite
            ? const Color(0xFF1E262B).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border.all(
          color: _isDarkSatellite ? Colors.white12 : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back, Title, Store count, View Toggle
          Row(
            children: [
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Moradabad Artisan Map',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _isDarkSatellite ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

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

          const SizedBox(height: 10),

          // Row 2: Search Field
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

          const SizedBox(height: 10),

          // Row 3: Locality Filter Pills (Seamlessly part of the same header container)
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
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
                    backgroundColor: _isDarkSatellite ? const Color(0xFF1E293B) : const Color(0xFFF1ECE4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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
                        _centerMapOnGeo(hub.lat, hub.lng, scale: 1.85);
                      } else {
                        _centerMapOnGeo(kMoradabadCenterLat, kMoradabadCenterLng, scale: 1.25);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

                // Action Buttons: WhatsApp, Directions & Visit Store
                Row(
                  children: [
                    // Direct WhatsApp Artisan Chat
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                        foregroundColor: const Color(0xFF128C7E),
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      tooltip: 'WhatsApp Artisan',
                      onPressed: () {
                        WhatsAppHelper.openArtisanChat(
                          context: context,
                          phoneNumber: seller.phoneNumber,
                          artisanName: seller.storeName.isNotEmpty ? seller.storeName : seller.name,
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Directions / GPS
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: Text(
                        'Directions',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openDirectionsInGoogleMaps(loc),
                    ),
                    const SizedBox(width: 8),

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
                          'Visit Store',
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold),
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

  // ─── LIST VIEW ALTERNATIVE ─────────────────────────────────────────────────
  Widget _buildListView(List<StoreMapLocation> locations) {
    final topPad = MediaQuery.of(context).padding.top + 160;

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
                  const SizedBox(width: 14),

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

                  IconButton(
                    icon: const Icon(Icons.pin_drop_rounded, color: AppColors.primary),
                    tooltip: 'Pinpoint on Map',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isListView = false;
                        _selectedSellerId = seller.id;
                      });
                      _centerMapOnGeo(loc.lat, loc.lng, scale: 2.0);
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

/// Subtle vector overlay enhancing landmarks on top of the real map tiles
class _MoradabadOverlayPainter extends CustomPainter {
  final bool isDark;

  _MoradabadOverlayPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ramganga River Path (Flows from North-West to South-East past Moradabad)
    final riverPaint = Paint()
      ..color = (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFC7DEEA)).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final riverPath = Path()
      ..moveTo(size.width * 0.42, 0)
      ..cubicTo(
        size.width * 0.50, size.height * 0.22,
        size.width * 0.62, size.height * 0.45,
        size.width * 0.72, size.height * 0.70,
      )
      ..cubicTo(
        size.width * 0.78, size.height * 0.85,
        size.width * 0.88, size.height * 0.95,
        size.width * 0.96, size.height,
      );
    canvas.drawPath(riverPath, riverPaint);

    // 2. Arterial Roads (Delhi-Moradabad Highway, Sambhal Road, Kanth Road)
    final roadPaint = Paint()
      ..color = (isDark ? Colors.white12 : const Color(0xFFE2DCD1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Delhi Road arterial
    final delhiRd = Path()
      ..moveTo(0, size.height * 0.48)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.52, size.width * 0.64, size.height * 0.60);
    canvas.drawPath(delhiRd, roadPaint);

    // Sambhal Road arterial
    final sambhalRd = Path()
      ..moveTo(size.width * 0.58, size.height)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.75, size.width * 0.65, size.height * 0.60);
    canvas.drawPath(sambhalRd, roadPaint);

    // 3. Subtle golden highlight around the historic brass corridors (Peetal Mandi & Bartan Bazaar)
    final haloPaint = Paint()
      ..color = const Color(0xFFC89B3C).withValues(alpha: isDark ? 0.12 : 0.08)
      ..style = PaintingStyle.fill;

    // Peetal Mandi & Bartan Bazaar Old City Heritage Halos (Center ~990, ~940 on 1536 canvas)
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.61), 180, haloPaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.61), 90, haloPaint..color = const Color(0xFFC89B3C).withValues(alpha: isDark ? 0.18 : 0.12));
  }

  @override
  bool shouldRepaint(covariant _MoradabadOverlayPainter oldDelegate) => oldDelegate.isDark != isDark;
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
