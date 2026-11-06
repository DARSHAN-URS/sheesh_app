import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/seller.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/network_image_fallback.dart';
import '../../widgets/store_photo_picker_sheet.dart';

class EditStoreProfileScreen extends ConsumerStatefulWidget {
  final Seller seller;

  const EditStoreProfileScreen({super.key, required this.seller});

  @override
  ConsumerState<EditStoreProfileScreen> createState() => _EditStoreProfileScreenState();
}

class _EditStoreProfileScreenState extends ConsumerState<EditStoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _storeNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _craftStoryCtrl;
  late TextEditingController _upiCtrl;

  late String _avatarUrl;
  late String _coverUrl;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

  final List<String> _moradabadHubs = [
    'Peetal Mandi, Moradabad',
    'Bartan Bazaar, Moradabad',
    'Civil Lines, Moradabad',
    'Asalatpura, Moradabad',
    'Sambhal Road, Moradabad',
    'Mughalpura, Moradabad',
    'Delhi Road Cluster, Moradabad',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.seller;
    _storeNameCtrl = TextEditingController(text: s.storeName);
    _ownerNameCtrl = TextEditingController(text: s.name);
    _taglineCtrl = TextEditingController(text: s.tagline);
    _locationCtrl = TextEditingController(text: s.location.isNotEmpty ? s.location : 'Peetal Mandi, Moradabad');
    _phoneCtrl = TextEditingController(text: s.phoneNumber.replaceAll('+91', ''));
    _craftStoryCtrl = TextEditingController(text: s.craftStory.isNotEmpty ? s.craftStory : s.bio);
    _upiCtrl = TextEditingController(text: s.upiId ?? '');

    _avatarUrl = s.avatarUrl.isNotEmpty ? s.avatarUrl : 'assets/images/sheesh_logo.png';
    _coverUrl = s.coverUrl.isNotEmpty ? s.coverUrl : 'assets/images/backgrounds/craft-studio.jpg';
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _taglineCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _craftStoryCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  /// Directly pick image from Device Media / Gallery or Camera
  Future<void> _pickDirectImage({
    required ImageSource source,
    required bool isCover,
  }) async {
    try {
      setState(() {
        if (isCover) {
          _isUploadingCover = true;
        } else {
          _isUploadingAvatar = true;
        }
      });

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: isCover ? 1400 : 800,
        maxHeight: isCover ? 900 : 800,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          if (isCover) _isUploadingCover = false;
          if (!isCover) _isUploadingAvatar = false;
        });
        return;
      }

      // Optimistically preview local file path immediately
      setState(() {
        if (isCover) {
          _coverUrl = image.path;
        } else {
          _avatarUrl = image.path;
        }
      });

      // Upload to Supabase / cloud storage
      final cloudUrl = await StorageService.uploadImage(
        file: File(image.path),
        folder: isCover ? 'covers' : 'avatars',
      );

      if (!mounted) return;
      setState(() {
        if (isCover) {
          _coverUrl = cloudUrl;
          _isUploadingCover = false;
        } else {
          _avatarUrl = cloudUrl;
          _isUploadingAvatar = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                isCover ? 'Cover photo uploaded from media! ✨' : 'Store logo uploaded from media! ✨',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isCover) _isUploadingCover = false;
        if (!isCover) _isUploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload picture: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Open full sheet with Device Media, Camera, and Moradabad artisan presets
  void _openPhotoPickerSheet({required bool isCover}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCover ? 'Update Store Cover Banner 🖼️' : 'Update Store Logo / Emblem 🏺',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Upload a high quality photo directly from your device media or choose a craft preset',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Option 1: Gallery / Device Media
            ListTile(
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickDirectImage(source: ImageSource.gallery, isCover: isCover);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
              ),
              title: Text(
                'Upload from Gallery / Device Media',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'Choose a photo saved on your phone',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ),

            const Divider(height: 12, color: AppColors.border),

            // Option 2: Camera Photo
            ListTile(
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickDirectImage(source: ImageSource.camera, isCover: isCover);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A7B54).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2A7B54), size: 22),
              ),
              title: Text(
                'Take New Photo with Camera',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'Photograph your workshop or artisan craft studio live',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ),

            const Divider(height: 12, color: AppColors.border),

            // Option 3: Presets Library
            ListTile(
              onTap: () {
                Navigator.pop(sheetCtx);
                StorePhotoPickerSheet.show(
                  context: context,
                  type: isCover ? StorePhotoType.cover : StorePhotoType.avatar,
                  currentUrl: isCover ? _coverUrl : _avatarUrl,
                  onSelected: (selectedUrl) {
                    setState(() {
                      if (isCover) {
                        _coverUrl = selectedUrl;
                      } else {
                        _avatarUrl = selectedUrl;
                      }
                    });
                  },
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldDark.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.goldDark, size: 22),
              ),
              title: Text(
                'Choose from Moradabad Craft Presets',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'Curated brassware studio & pottery backgrounds',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStoreProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final storeName = _storeNameCtrl.text.trim();
    if (storeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your store or brand name.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final rawPhone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      final formattedPhone = rawPhone.length == 10 ? '+91$rawPhone' : (rawPhone.isNotEmpty ? '+$rawPhone' : null);

      await ref.read(authProvider.notifier).updateSellerProfile(
            ownerName: _ownerNameCtrl.text.trim(),
            storeName: storeName,
            tagline: _taglineCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            craftStory: _craftStoryCtrl.text.trim(),
            avatarUrl: _avatarUrl,
            coverUrl: _coverUrl,
            phoneNumber: formattedPhone,
            upiId: _upiCtrl.text.trim().isNotEmpty ? _upiCtrl.text.trim() : null,
          );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Store "$storeName" updated successfully! ✨',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update store: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Artisan Store Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveStoreProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
            label: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ─── 1. Interactive Storefront Banner & Logo Header ─────────────
            _buildStoreHeaderPreview(),

            const SizedBox(height: 16),

            // ─── 2. Media Upload Quick Action Buttons ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                      ),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: Text(
                        'Upload Logo',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openPhotoPickerSheet(isCover: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.goldDark,
                        side: const BorderSide(color: AppColors.goldDark, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppColors.goldDark.withValues(alpha: 0.04),
                      ),
                      icon: const Icon(Icons.wallpaper_rounded, size: 18),
                      label: Text(
                        'Upload Banner',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openPhotoPickerSheet(isCover: true),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── 3. Store Identity Card ─────────────────────────────────────
            _buildSectionCard(
              title: 'Store Identity & Branding',
              subtitle: 'How buyers recognize your brand in Moradabad marketplace',
              icon: Icons.storefront_rounded,
              children: [
                _buildTextField(
                  controller: _storeNameCtrl,
                  label: 'Store / Brand Name',
                  hint: 'e.g. Royal Peetal Creations',
                  icon: Icons.store_mall_directory_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Store name is required' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _ownerNameCtrl,
                  label: 'Artisan / Founder Name',
                  hint: 'e.g. Fatima Begum',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _taglineCtrl,
                  label: 'Brand Tagline / Catchphrase',
                  hint: 'e.g. Hand-etched brass samovars & filigree vases',
                  icon: Icons.auto_awesome_outlined,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── 4. Direct WhatsApp & Contact Section ────────────────────────
            _buildSectionCard(
              title: 'Artisan Contact & WhatsApp Direct',
              subtitle: 'Used for buyer inquiries and order verification',
              icon: Icons.chat_bubble_outline_rounded,
              children: [
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'WhatsApp Mobile Number',
                    hintText: '9876543210',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      margin: const EdgeInsets.only(right: 8),
                      alignment: Alignment.center,
                      width: 70,
                      child: Row(
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '+91',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    suffixIcon: const Icon(Icons.verified_rounded, color: Color(0xFF25D366), size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '💡 Buyers will tap "Chat on WhatsApp" on your creations to contact this number directly.',
                  style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── 5. Location & Moradabad Craft Hub ───────────────────────────
            _buildSectionCard(
              title: 'Workshop Location & Craft Hub',
              subtitle: 'Pins your store on the interactive Moradabad Artisan Map',
              icon: Icons.location_on_outlined,
              children: [
                _buildTextField(
                  controller: _locationCtrl,
                  label: 'Operating Workshop Address',
                  hint: 'e.g. Shop 42, Peetal Mandi, Moradabad, UP',
                  icon: Icons.pin_drop_rounded,
                ),
                const SizedBox(height: 10),
                Text(
                  'Quick-Select Moradabad Handicraft Hub:',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _moradabadHubs.map((hub) {
                    final isSelected = _locationCtrl.text.toLowerCase().contains(hub.toLowerCase().split(',').first);
                    return ChoiceChip(
                      label: Text(hub.split(',').first),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _locationCtrl.text = hub);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── 6. Artisan Heritage & Story ────────────────────────────────
            _buildSectionCard(
              title: 'Craft Heritage & Story',
              subtitle: 'Tell buyers about your family legacy, materials and handmade methods',
              icon: Icons.history_edu_rounded,
              children: [
                TextFormField(
                  controller: _craftStoryCtrl,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
                  decoration: InputDecoration(
                    labelText: 'Artisan Story / Craft Heritage',
                    hintText: 'e.g. Our family has been hand-casting brass in Moradabad for 3 generations, using traditional sand-casting and filigree wirework...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─── 7. Direct UPI Payouts ──────────────────────────────────────
            _buildSectionCard(
              title: 'Direct UPI ID',
              subtitle: 'Direct customer payouts with zero middleman commissions',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildTextField(
                  controller: _upiCtrl,
                  label: 'UPI ID (Virtual Payment Address)',
                  hint: 'e.g. storename@okaxis or 9876543210@upi',
                  icon: Icons.currency_rupee_rounded,
                ),
              ],
            ),
          ],
        ),
      ),

      // ─── Bottom Persistent Save Bar ─────────────────────────────────────────
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
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
            onPressed: _isSaving ? null : _saveStoreProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Save Store Changes ✨',
                        style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── STORE HEADER PREVIEW ──────────────────────────────────────────────────
  Widget _buildStoreHeaderPreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Cover Photo with Edit Pill
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: _isUploadingCover
                    ? Container(
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      )
                    : (_coverUrl.startsWith('/') || _coverUrl.contains('\\'))
                        ? Image.file(File(_coverUrl), fit: BoxFit.cover)
                        : NetworkImageFallback(
                            imageUrl: _coverUrl,
                            fit: BoxFit.cover,
                          ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Change Cover Badge Button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _openPhotoPickerSheet(isCover: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Change Cover 🖼️',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Store Avatar overlapping the bottom of the cover
              Positioned(
                bottom: -28,
                left: 16,
                child: GestureDetector(
                  onTap: () => _openPhotoPickerSheet(isCover: false),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _isUploadingAvatar
                              ? Container(
                                  color: Colors.black26,
                                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                )
                              : (_avatarUrl.startsWith('/') || _avatarUrl.contains('\\'))
                                  ? Image.file(File(_avatarUrl), fit: BoxFit.cover)
                                  : NetworkImageFallback(
                                      imageUrl: _avatarUrl,
                                      fit: BoxFit.cover,
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Lower info preview
          Padding(
            padding: const EdgeInsets.fromLTRB(100, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _storeNameCtrl.text.isNotEmpty ? _storeNameCtrl.text : 'My Artisan Store',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _taglineCtrl.text.isNotEmpty ? _taglineCtrl.text : 'Moradabad Handicrafts',
                        style: GoogleFonts.lato(fontSize: 11.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Preview',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2A7B54)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── REUSABLE SECTION CARD ─────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

