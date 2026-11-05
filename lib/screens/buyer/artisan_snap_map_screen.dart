import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/network_image_fallback.dart';
import 'seller_storefront_screen.dart';
import 'category_screen.dart';
import 'store_map_screen.dart';

/// Alias for ArtisanMapScreen
typedef ArtisanMapScreen = ArtisanSnapMapScreen;

/// Real GPS coordinates representation for Moradabad landmarks
class MoradabadGeoPoint {
  final double latitude;
  final double longitude;
  final String neighborhood;

  const MoradabadGeoPoint({
    required this.latitude,
    required this.longitude,
    required this.neighborhood,
  });
}

class ArtisanSnapMapScreen extends ConsumerStatefulWidget {
  final List<LocalStoreItem> initialStores;
  final String userLocation;

  const ArtisanSnapMapScreen({
    super.key,
    required this.initialStores,
    required this.userLocation,
  });

  @override
  ConsumerState<ArtisanSnapMapScreen> createState() => _ArtisanSnapMapScreenState();
}

class _ArtisanSnapMapScreenState extends ConsumerState<ArtisanSnapMapScreen> with SingleTickerProviderStateMixin {
  late TransformationController _transformCtrl;
  LocalStoreItem? _selectedStore;
  double? _maxDistanceKm; // filter on map
  String? _selectedCategory; // category filter on map
  late AnimationController _pulseController;

  // Real center coordinates for Moradabad, Uttar Pradesh
  static const double kMoradabadCenterLat = 28.8386;
  static const double kMoradabadCenterLng = 78.7733;
  static const int kMapZoom = 14;

  // Virtual map canvas dimensions (6x6 tiles of 256x256 = 1536x1536)
  static const Size kMapCanvasSize = Size(1536, 1536);

  // OSM / CartoDB Tile coordinates for Moradabad at zoom 14
  static const int kBaseTileX = 11776;
  static const int kBaseTileY = 6734;

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
    _selectedStore = widget.initialStores.isNotEmpty ? widget.initialStores.first : null;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Ensure the map ALWAYS opens with our location at the exact centre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnUser(animate: false);
    });
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Calculates the center of the user's location on the canvas
  Offset _getUserMapOffset() {
    return Offset(kMapCanvasSize.width / 2, kMapCanvasSize.height / 2);
  }

  /// Center the map strictly on our location in the middle of the viewport
  void _centerMapOnUser({bool animate = true}) {
    if (!mounted) return;
    final media = MediaQuery.of(context).size;
    final viewportWidth = media.width;
    final viewportHeight = media.height;

    final userPos = _getUserMapOffset();
    final targetX = (viewportWidth / 2) - userPos.dx;
    final targetY = (viewportHeight / 2) - userPos.dy;

    final targetMatrix = Matrix4.identity()..translate(targetX, targetY);

    _transformCtrl.value = targetMatrix;
    setState(() {});
  }

  /// Real geographic coordinates mapped for each Moradabad artisan store
  MoradabadGeoPoint _getStoreGeoPoint(LocalStoreItem item) {
    final storeName = item.seller.storeName.toLowerCase();
    final loc = item.seller.location.toLowerCase();

    if (storeName.contains('fatima') || loc.contains('peetal mandi')) {
      return const MoradabadGeoPoint(latitude: 28.8352, longitude: 78.7758, neighborhood: 'Peetal Mandi');
    } else if (storeName.contains('qaira') || loc.contains('budh')) {
      return const MoradabadGeoPoint(latitude: 28.8415, longitude: 78.7802, neighborhood: 'Budh Bazaar');
    } else if (storeName.contains('noor') || loc.contains('civil lines')) {
      return const MoradabadGeoPoint(latitude: 28.8465, longitude: 78.7668, neighborhood: 'Civil Lines');
    } else if (storeName.contains('al-hassan') || loc.contains('sambhal')) {
      return const MoradabadGeoPoint(latitude: 28.8285, longitude: 78.7830, neighborhood: 'Sambhal Road');
    } else if (loc.contains('prince') || loc.contains('market')) {
      return const MoradabadGeoPoint(latitude: 28.8370, longitude: 78.7705, neighborhood: 'Prince Road');
    } else if (loc.contains('mandi chowk') || storeName.contains('chanderi')) {
      return const MoradabadGeoPoint(latitude: 28.8320, longitude: 78.7785, neighborhood: 'Mandi Chowk');
    } else {
      // Deterministic realistic offset from Moradabad center (within 1-3.5 km)
      final hash = item.seller.id.hashCode.abs();
      final angle = (hash % 360) * (math.pi / 180.0);
      final distKm = (item.distanceKm).clamp(0.6, 6.0);
      // 1 deg latitude ≈ 111 km, 1 deg longitude ≈ 97 km at 28.8°
      final dLat = (distKm / 111.0) * math.sin(angle);
      final dLng = (distKm / 97.0) * math.cos(angle);

      return MoradabadGeoPoint(
        latitude: kMoradabadCenterLat + dLat,
        longitude: kMoradabadCenterLng + dLng,
        neighborhood: item.clusterArea.isNotEmpty ? item.clusterArea : 'Moradabad Central',
      );
    }
  }

  /// Converts real Lat/Lng into pixel coordinates on the 1536x1536 Web Mercator map canvas
  Offset _geoToPixelOffset(double lat, double lng) {
    // Zoom 14 scale
    const zoom = kMapZoom;
    const numTiles = 1 << zoom;

    // Web Mercator formula
    final xTile = ((lng + 180.0) / 360.0) * numTiles;
    final latRad = lat * math.pi / 180.0;
    final yTile = ((1.0 - (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi)) / 2.0) * numTiles;

    // Relative to the top-left tile of our 6x6 grid
    // Grid starts at (kBaseTileX - 3, kBaseTileY - 3)
    const tileStartX = kBaseTileX - 3;
    const tileStartY = kBaseTileY - 3;

    final pixelX = (xTile - tileStartX) * 256.0;
    final pixelY = (yTile - tileStartY) * 256.0;

    return Offset(pixelX, pixelY);
  }

  /// Launch external turn-by-turn directions in Google Maps or Apple Maps
  Future<void> _openGoogleMapsDirections(LocalStoreItem item) async {
    final geo = _getStoreGeoPoint(item);
    final storeName = item.seller.storeName;
    final encodedQuery = Uri.encodeComponent('$storeName, ${geo.neighborhood}, Moradabad, Uttar Pradesh');
    
    // Standard Google Maps directions URL with fallback
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${geo.latitude},${geo.longitude}&query=$encodedQuery');

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
            content: Text('Artisan Location: ${geo.neighborhood}, Moradabad (GPS: ${geo.latitude.toStringAsFixed(4)}, ${geo.longitude.toStringAsFixed(4)})'),
            backgroundColor: const Color(0xFF5A1629),
          ),
        );
      }
    }
  }

  String _getCategoryEmoji(String catId) {
    switch (catId) {
      case 'brass':
        return '🪔';
      case 'bridal':
        return '👗';
      case 'jewels':
        return '💎';
      case 'decor':
        return '🏮';
      case 'wood':
        return '🪵';
      default:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return const StoreMapScreen();
  }

  Widget _buildLegacyMap(BuildContext context) {
    final userAvatar = auth.avatarUrl;
    final userName = auth.fullName.isNotEmpty ? auth.fullName : 'You';

    // Apply distance / category filters on the map
    final stores = widget.initialStores.where((item) {
      if (_maxDistanceKm != null && item.distanceKm > _maxDistanceKm!) return false;
      if (_selectedCategory != null && item.seller.categoryId != _selectedCategory) return false;
      return true;
    }).toList();

    final userOffset = _getUserMapOffset();

    return Scaffold(
      backgroundColor: const Color(0xFF1E232A),
      body: Stack(
        children: [
          // ── Interactive Real Map Canvas ──
          InteractiveViewer(
            transformationController: _transformCtrl,
            minScale: 0.6,
            maxScale: 2.8,
            boundaryMargin: const EdgeInsets.all(600),
            constrained: false,
            child: SizedBox(
              width: kMapCanvasSize.width,
              height: kMapCanvasSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Realistic Vector Road Network Background (Base Canvas)
                  CustomPaint(
                    size: kMapCanvasSize,
                    painter: _RealMapTerrainPainter(),
                  ),

                  // 2. Real OpenStreetMap / CartoDB Slippy Map Tiles Layer
                  _buildRealMapTileGrid(),

                  // 3. District & Neighborhood Geography Labels
                  ..._buildDistrictLabels(),

                  // 4. Center User Avatar & Live GPS Marker (Strictly Centered)
                  Positioned(
                    left: userOffset.dx - 40,
                    top: userOffset.dy - 40,
                    child: _buildUserAvatarMarker(userAvatar, userName),
                  ),

                  // 5. Nearby Artisan Store Pins (Real Geo Locations in Moradabad)
                  ...stores.map((item) {
                    final geo = _getStoreGeoPoint(item);
                    final offset = _geoToPixelOffset(geo.latitude, geo.longitude);
                    final isSelected = _selectedStore?.seller.id == item.seller.id;

                    return Positioned(
                      left: offset.dx - 32,
                      top: offset.dy - 36,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStore = item;
                          });
                        },
                        child: _buildStorePin(item, isSelected),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Top Gradient Overlay for Header Readability ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Top Navigation Bar: Renamed strictly to "Map" ──
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Back Button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Map Header Pill (Renamed as Map)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'MAP • MORADABAD',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: const Color(0xFFE2C48D),
                                      ),
                                    ),
                                    Text(
                                      '${stores.length} Workshops Near You',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.map_rounded, size: 18, color: Color(0xFFE2C48D)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Recenter on Our Location Button
                      InkWell(
                        onTap: () {
                          _centerMapOnUser(animate: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Centered at: ${widget.userLocation}',
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF5A1629),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.my_location_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Real Distance & Craft Filters ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildMapFilterChip(
                        label: 'All Distances',
                        isSelected: _maxDistanceKm == null,
                        onTap: () => setState(() => _maxDistanceKm = null),
                      ),
                      const SizedBox(width: 6),
                      _buildMapFilterChip(
                        label: '< 2 km',
                        isSelected: _maxDistanceKm == 2.0,
                        onTap: () => setState(() => _maxDistanceKm = 2.0),
                      ),
                      const SizedBox(width: 6),
                      _buildMapFilterChip(
                        label: '< 5 km',
                        isSelected: _maxDistanceKm == 5.0,
                        onTap: () => setState(() => _maxDistanceKm = 5.0),
                      ),
                      const SizedBox(width: 6),
                      _buildMapFilterChip(
                        label: '< 10 km',
                        isSelected: _maxDistanceKm == 10.0,
                        onTap: () => setState(() => _maxDistanceKm = 10.0),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 18, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(width: 10),
                      _buildMapFilterChip(
                        label: '🪔 Brass',
                        isSelected: _selectedCategory == 'brass',
                        onTap: () => setState(() => _selectedCategory = _selectedCategory == 'brass' ? null : 'brass'),
                      ),
                      const SizedBox(width: 6),
                      _buildMapFilterChip(
                        label: '👗 Zardozi',
                        isSelected: _selectedCategory == 'bridal',
                        onTap: () => setState(() => _selectedCategory = _selectedCategory == 'bridal' ? null : 'bridal'),
                      ),
                      const SizedBox(width: 6),
                      _buildMapFilterChip(
                        label: '💎 Kundan',
                        isSelected: _selectedCategory == 'jewels',
                        onTap: () => setState(() => _selectedCategory = _selectedCategory == 'jewels' ? null : 'jewels'),
                      ),
                      const SizedBox(width: 6),
                      _buildMapFilterChip(
                        label: '🏮 Decor',
                        isSelected: _selectedCategory == 'decor',
                        onTap: () => setState(() => _selectedCategory = _selectedCategory == 'decor' ? null : 'decor'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Storefront Preview Card with Direct Navigation ──
          if (_selectedStore != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildSelectedStorePreviewCard(_selectedStore!),
            ),
        ],
      ),
    );
  }

  /// Grid of real high-resolution MapTiler tiles of Moradabad (6x6 tiles)
  Widget _buildRealMapTileGrid() {
    const tileRows = 6;
    const tileCols = 6;
    const tileStartCol = kBaseTileX - 3;
    const tileStartRow = kBaseTileY - 3;
    final mapKey = AppConfig.mapTilerApiKey;

    return Stack(
      children: [
        for (int row = 0; row < tileRows; row++)
          for (int col = 0; col < tileCols; col++)
            Positioned(
              left: col * 256.0,
              top: row * 256.0,
              width: 256.0,
              height: 256.0,
              child: Opacity(
                opacity: 0.95,
                child: CachedNetworkImage(
                  imageUrl: 'https://api.maptiler.com/maps/streets-v2/256/$kMapZoom/${tileStartCol + col}/${tileStartRow + row}.png?key=$mapKey',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    imageUrl: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/$kMapZoom/${tileStartCol + col}/${tileStartRow + row}.png',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  /// Buyer's Real Location Marker with GPS Accuracy Rings
  Widget _buildUserAvatarMarker(String? avatarUrl, String userName) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final rippleRadius = 42.0 + (pulseValue * 46.0);
        final rippleOpacity = (1.0 - pulseValue).clamp(0.0, 0.7);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outermost Radar Ripple Ring
            Container(
              width: rippleRadius * 2,
              height: rippleRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD64438).withValues(alpha: rippleOpacity * 0.45),
                  width: 2.5,
                ),
                color: const Color(0xFFD64438).withValues(alpha: rippleOpacity * 0.10),
              ),
            ),
            // Inner Pulsing GPS Ring
            Container(
              width: (42.0 + (pulseValue * 22.0)) * 2,
              height: (42.0 + (pulseValue * 22.0)) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC89B3C).withValues(alpha: rippleOpacity * 0.7),
                  width: 1.5,
                ),
              ),
            ),

            // User Avatar Frame
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261017),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC89B3C), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4ADE80),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Your Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A1629), Color(0xFFD64438)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A1629).withValues(alpha: 0.6),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImageFallback(imageUrl: avatarUrl, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 28),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Store Marker Pin on Map
  Widget _buildStorePin(LocalStoreItem item, bool isSelected) {
    final emoji = _getCategoryEmoji(item.seller.categoryId);
    final borderColor = isSelected ? const Color(0xFFC89B3C) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 68 : 52,
          height: isSelected ? 68 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: borderColor, width: isSelected ? 3.5 : 2.5),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFC89B3C).withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.4),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: NetworkImageFallback(
                    imageUrl: item.seller.avatarUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A1629),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ),

        // Pin stem arrow
        CustomPaint(
          size: const Size(12, 7),
          painter: _PinArrowPainter(color: borderColor),
        ),

        const SizedBox(height: 2),

        // Store Name & Distance Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC89B3C) : Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${item.seller.storeName.split(' ').first} • ${item.distanceKm.toStringAsFixed(1)}km',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF261017) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom Popup Card when a Store is Selected
  Widget _buildSelectedStorePreviewCard(LocalStoreItem item) {
    final geo = _getStoreGeoPoint(item);
    final driveMinutes = (item.distanceKm * 3.5).round().clamp(2, 35);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC89B3C), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Store Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC89B3C), width: 2),
                ),
                child: ClipOval(
                  child: NetworkImageFallback(
                    imageUrl: item.seller.avatarUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Store Name & Neighborhood
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.seller.storeName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF261017),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF2A7B54)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${geo.neighborhood} • ${item.seller.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF8A6B7E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Distance & Walking/Driving Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBE5C8)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2A7B54),
                      ),
                    ),
                    Text(
                      '~$driveMinutes min',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A7B54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal list of craft products from this artisan store
          if (item.postedProducts.isNotEmpty)
            SizedBox(
              height: 58,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.postedProducts.take(4).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = item.postedProducts[i];
                  return Container(
                    width: 140,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF3EC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEDCD4)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: NetworkImageFallback(
                              imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF261017),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₹${p.price.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5A1629),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 14),

          // Action Buttons: Visit Storefront & Real Google Maps Directions
          Row(
            children: [
              // Google Maps Directions
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openGoogleMapsDirections(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5A1629),
                    side: const BorderSide(color: Color(0xFF5A1629), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: Text(
                    'Directions 🧭',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Visit Live Storefront
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SellerStorefrontScreen(sellerId: item.seller.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A1629),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.storefront_rounded, size: 16),
                  label: Text(
                    'Visit Storefront 🏪',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildMapFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC89B3C) : Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF261017) : Colors.white,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDistrictLabels() {
    // Exact Moradabad landmark geography positions on the 1536x1536 map canvas
    final labels = [
      {'name': 'Peetal Mandi\nBrass Heart', 'lat': 28.8352, 'lng': 78.7758},
      {'name': 'Civil Lines\nHeritage Quarter', 'lat': 28.8465, 'lng': 78.7668},
      {'name': 'Mandi Chowk\nZardozi & Silks', 'lat': 28.8320, 'lng': 78.7785},
      {'name': 'Budh Bazaar\nHistoric Markets', 'lat': 28.8415, 'lng': 78.7802},
      {'name': 'Kanth Road\nArtisan Studios', 'lat': 28.8525, 'lng': 78.7580},
      {'name': 'Ramganga River\nWaterfront', 'lat': 28.8480, 'lng': 78.7880},
    ];

    return labels.map((l) {
      final lat = l['lat'] as double;
      final lng = l['lng'] as double;
      final name = l['name'] as String;
      final pos = _geoToPixelOffset(lat, lng);

      return Positioned(
        left: pos.dx - 45,
        top: pos.dy - 12,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232A).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Fallback Realistic Moradabad GIS Road & River Canvas
class _RealMapTerrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark elegant basemap background
    final bgPaint = Paint()..color = const Color(0xFF1B2028);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City land parcels
    final blockPaint = Paint()
      ..color = const Color(0xFF232A34)
      ..style = PaintingStyle.fill;

    final blockBorderPaint = Paint()
      ..color = const Color(0xFF2E3744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(101);
    for (int i = 0; i < 54; i++) {
      final x = (random.nextDouble() * (size.width - 160));
      final y = (random.nextDouble() * (size.height - 160));
      final w = 70.0 + random.nextDouble() * 120.0;
      final h = 50.0 + random.nextDouble() * 95.0;
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(8));
      canvas.drawRRect(rrect, blockPaint);
      canvas.drawRRect(rrect, blockBorderPaint);
    }

    // 3. Ramganga River Curve
    final riverPaint = Paint()
      ..color = const Color(0xFF1B4958).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38.0
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(0, size.height * 0.15);
    riverPath.cubicTo(
      size.width * 0.25, size.height * 0.20,
      size.width * 0.40, size.height * 0.05,
      size.width * 0.70, size.height * 0.18,
    );
    riverPath.cubicTo(
      size.width * 0.85, size.height * 0.25,
      size.width * 0.95, size.height * 0.45,
      size.width, size.height * 0.55,
    );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Main Highway Arteries & City Grid
    final roadPaint = Paint()
      ..color = const Color(0xFF4A5568).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFF374151).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (double deg = 0; deg < 360; deg += 45) {
      final rad = deg * (math.pi / 180.0);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + size.width * math.cos(rad), cy + size.height * math.sin(rad)),
        roadPaint,
      );
    }

    for (double r = 120; r <= 680; r += 140) {
      canvas.drawCircle(Offset(cx, cy), r, secondaryRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinArrowPainter extends CustomPainter {
  final Color color;
  const _PinArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
