import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'network_image_fallback.dart';

class StorePhotoPreset {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String tag;

  const StorePhotoPreset({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.tag,
  });
}

const List<StorePhotoPreset> kSheeshCoverPresets = [
  StorePhotoPreset(
    title: 'Peetal Mandi Brass Workshop',
    subtitle: 'Warm brass casting, polishing and hammered urlis',
    imageUrl: 'assets/images/backgrounds/craft-studio.jpg',
    tag: 'BRASSWARE',
  ),
  StorePhotoPreset(
    title: 'Terracotta & Clay Pottery Kiln',
    subtitle: 'Hand-thrown ceramics, earthy pots & artisanal glazes',
    imageUrl: 'assets/images/backgrounds/pottery-clay.jpg',
    tag: 'POTTERY',
  ),
  StorePhotoPreset(
    title: 'Shahi Zardozi & Velvet Studio',
    subtitle: 'Intricate golden zari embroidery & royal silks',
    imageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=1000',
    tag: 'BRIDAL & ZARI',
  ),
  StorePhotoPreset(
    title: 'Kundan Jewelry Atelier',
    subtitle: 'Traditional meenakari, gemstones & polki jewelry',
    imageUrl: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=1000',
    tag: 'JEWELLERY',
  ),
  StorePhotoPreset(
    title: 'Mughal Filigree Lighting Studio',
    subtitle: 'Pierced Moroccan brass lanterns & ambient shadow lamps',
    imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=1000',
    tag: 'LIGHTING',
  ),
  StorePhotoPreset(
    title: 'Sheesham Wood & Tarkashi Inlay',
    subtitle: 'Seasoned wood with hammered pure brass wirework',
    imageUrl: 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=1000',
    tag: 'WOODWORK',
  ),
];

const List<StorePhotoPreset> kSheeshAvatarPresets = [
  StorePhotoPreset(
    title: 'Sheesh Brand Crest',
    subtitle: 'Official wine & coral celestial arch emblem',
    imageUrl: 'assets/images/sheesh_logo.png',
    tag: 'BRAND ICON',
  ),
  StorePhotoPreset(
    title: 'Heritage Artisan (Priya)',
    subtitle: 'Traditional jewelry & silk atelier founder',
    imageUrl: 'assets/images/creators/priya.jpg',
    tag: 'PORTRAIT',
  ),
  StorePhotoPreset(
    title: 'Studio Ceramist (Meera)',
    subtitle: 'Master terracotta artisan & clay pottery maker',
    imageUrl: 'assets/images/creators/meera.jpg',
    tag: 'PORTRAIT',
  ),
  StorePhotoPreset(
    title: 'Master Weaver (Ananya)',
    subtitle: '3rd generation Kanchipuram pit loom artisan',
    imageUrl: 'assets/images/creators/ananya.jpg',
    tag: 'PORTRAIT',
  ),
  StorePhotoPreset(
    title: 'Golden Peetal Diya Crest',
    subtitle: 'Traditional Moradabad brassware symbol',
    imageUrl: 'https://images.unsplash.com/photo-1608755728617-aefab37d2edd?w=400',
    tag: 'CREST',
  ),
  StorePhotoPreset(
    title: 'Ustad Brass Master',
    subtitle: 'Senior Moradabad metal craftsman portrait',
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    tag: 'PORTRAIT',
  ),
];

enum StorePhotoType { avatar, cover }

class StorePhotoPickerSheet extends StatefulWidget {
  final StorePhotoType type;
  final String? currentUrl;
  final ValueChanged<String> onSelected;

  const StorePhotoPickerSheet({
    super.key,
    required this.type,
    this.currentUrl,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required StorePhotoType type,
    String? currentUrl,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StorePhotoPickerSheet(
        type: type,
        currentUrl: currentUrl,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<StorePhotoPickerSheet> createState() => _StorePhotoPickerSheetState();
}

class _StorePhotoPickerSheetState extends State<StorePhotoPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _previewUrl;
  bool _isCustomPicked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _previewUrl = widget.currentUrl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _previewUrl = image.path;
          _isCustomPicked = true;
          _isUploading = true;
        });

        final cloudUrl = await StorageService.uploadImage(
          file: File(image.path),
          folder: widget.type == StorePhotoType.cover ? 'covers' : 'avatars',
        );

        if (mounted) {
          setState(() {
            _previewUrl = cloudUrl;
            _isUploading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    }
  }

  void _applySelection() {
    if (_previewUrl != null && _previewUrl!.isNotEmpty) {
      widget.onSelected(_previewUrl!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCover = widget.type == StorePhotoType.cover;
    final presets = isCover ? kSheeshCoverPresets : kSheeshAvatarPresets;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCover ? Icons.panorama_rounded : Icons.account_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCover ? 'Choose Store Cover Photo' : 'Choose Store Profile Photo',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isCover
                            ? 'Select from Sheesh artisan studios or upload your workshop banner'
                            : 'Pick a Sheesh brand seal or upload your own store avatar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab Bar (Sheesh Presets vs Custom Upload)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '✨ Options from Sheesh'),
                Tab(text: '📷 Choose from Media'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── TAB 1: SHEESH CURATED PRESETS ──
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  itemCount: presets.length,
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    final isSelected = _previewUrl == preset.imageUrl;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _previewUrl = preset.imageUrl;
                          _isCustomPicked = false;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.blush : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail Preview
                            Container(
                              width: isCover ? 85 : 54,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isCover ? 10 : 27),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: NetworkImageFallback(
                                imageUrl: preset.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Text details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          preset.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    preset.subtitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5A1629).withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      preset.tag,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF5A1629),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Selection Checkmark
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                            else
                              const Icon(Icons.radio_button_off_rounded, color: AppColors.textLight, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ── TAB 2: CHOOSE FROM YOUR MEDIA (Gallery / Camera) ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCover ? 'Select Banner from Your Media' : 'Select Avatar from Your Media',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCover
                            ? 'Upload a photo from your gallery or take a fresh shot of your Moradabad workshop.'
                            : 'Upload your store logo or personal artisan portrait directly from your photos.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 18),

                      // Media Action Cards
                      InkWell(
                        onTap: () => _pickImage(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF4F0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose from Gallery / Photos',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Pick any image file saved on your device',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () => _pickImage(ImageSource.camera),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD64438).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD64438), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Take Photo with Camera',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Capture your workshop or product right now',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Live Preview Box for Selected Media
                      if (_previewUrl != null && _previewUrl!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF2A7B54), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Selected Photo Preview',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (_isCustomPicked)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _previewUrl = widget.currentUrl;
                                    _isCustomPicked = false;
                                  });
                                },
                                child: Text(
                                  'Reset',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFFD64438),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: isCover ? 130 : 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: NetworkImageFallback(
                            imageUrl: _previewUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _applySelection,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isCover ? 'Apply Cover Banner' : 'Apply Store Avatar',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

