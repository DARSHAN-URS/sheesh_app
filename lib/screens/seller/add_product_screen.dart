import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'seller_subscription_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;
  const AddProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _materialController = TextEditingController();
  final _deliveryTimeController = TextEditingController(text: '2-4 business days');
  final _tagsController = TextEditingController();

  String? _selectedCategoryId;
  bool _isHandmade = true;
  bool _isLoading = false;
  List<File> _selectedImages = [];
  final _imagePicker = ImagePicker();
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    if (p != null) {
      _nameController.text = p.name;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toInt().toString();
      if (p.originalPrice != null) {
        _originalPriceController.text = p.originalPrice!.toInt().toString();
      }
      _materialController.text = p.materialOrTechnique;
      _deliveryTimeController.text = p.deliveryTime;
      _tagsController.text = p.tags.join(', ');
      _selectedCategoryId = p.categoryId.isNotEmpty ? p.categoryId : null;
      _isHandmade = p.isHandmade;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _materialController.dispose();
    _deliveryTimeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Upload Craft Photos',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Select photos from your system or take a fresh shot',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Choose from Gallery / System',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Select multiple high-resolution photos from your device',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
                  if (picked.isNotEmpty) {
                    setState(() {
                      _selectedImages.addAll(picked.map((x) => File(x.path)));
                    });
                  }
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64438).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD64438)),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Capture your handcrafted product right now',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (photo != null) {
                    setState(() {
                      _selectedImages.add(File(photo.path));
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isEditing = widget.productToEdit != null;
    if (!_formKey.currentState!.validate()) return;
    if (!isEditing && _selectedImages.isEmpty) {
      _showSnack('Please add at least one product image');
      return;
    }
    if (_selectedCategoryId == null) {
      _showSnack('Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'original_price': _originalPriceController.text.isNotEmpty
            ? double.parse(_originalPriceController.text)
            : null,
        'category_id': _selectedCategoryId,
        'material_or_technique': _materialController.text.trim(),
        'delivery_time': _deliveryTimeController.text.trim(),
        'is_handmade': _isHandmade,
        'tags': _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      };

      String productId;
      if (isEditing) {
        productId = widget.productToEdit!.id;
        try {
          await apiService.put('/products/$productId', data: payload);
        } catch (_) {
          await SupabaseService.client
              .from('products')
              .update(payload)
              .eq('id', productId);
        }
      } else {
        Map<String, dynamic> productData;
        try {
          final res = await apiService.post('/products', data: payload);
          productData = Map<String, dynamic>.from(res as Map);
        } catch (apiErr) {
          // Direct Supabase fallback if Railway backend API fails
          try {
            final auth = ref.read(authProvider);
            final sellerId = auth.sellerProfile?.id ?? (await _getOrCreateSellerId(auth));
            final insertPayload = Map<String, dynamic>.from(payload);
            insertPayload['seller_id'] = sellerId;
            final sbRes = await SupabaseService.client
                .from('products')
                .insert(insertPayload)
                .select();
            if (sbRes is List && sbRes.isNotEmpty) {
              productData = Map<String, dynamic>.from(sbRes.first as Map);
            } else {
              throw apiErr;
            }
          } catch (_) {
            rethrow;
          }
        }
        productId = productData['id'] as String;
      }

      // Upload newly selected images
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() => _uploadProgress = (i + 1) / _selectedImages.length);

        final file = _selectedImages[i];
        final ext = file.path.split('.').last;
        final fileName = '${const Uuid().v4()}.$ext';

        try {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(file.path, filename: fileName),
            'sort_order': (i + (widget.productToEdit?.imageUrls.length ?? 0)).toString(),
          });
          await apiService.postMultipart('/products/$productId/images', formData);
        } catch (_) {
          // Direct Supabase Storage fallback
          try {
            final bytes = await file.readAsBytes();
            final storagePath = '$productId/$fileName';
            await SupabaseService.client.storage
                .from('product-images')
                .uploadBinary(storagePath, bytes);
            final publicUrl = SupabaseService.client.storage
                .from('product-images')
                .getPublicUrl(storagePath);
            await SupabaseService.client.from('product_images').insert({
              'product_id': productId,
              'url': publicUrl,
              'sort_order': i + (widget.productToEdit?.imageUrls.length ?? 0),
            });
          } catch (_) {}
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Product updated successfully! 🎉' : 'Product added successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (e.toString().toLowerCase().contains('limit reached') || e.toString().contains('403')) {
        _showSnack(e.toString());
        if (mounted) {
          SellerSubscriptionScreen.show(context);
        }
      } else {
        final cleanMsg = extractErrorMessage(e);
        _showSnack('Failed to ${isEditing ? "update" : "add"} product: $cleanMsg');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getOrCreateSellerId(AuthState auth) async {
    final uid = auth.supabaseUser?.id;
    if (uid == null) throw Exception('Please log in first');
    try {
      final res = await SupabaseService.client
          .from('sellers')
          .select('id')
          .eq('user_id', uid)
          .maybeSingle();
      if (res != null && res['id'] != null) {
        return res['id'] as String;
      }
      final inserted = await SupabaseService.client
          .from('sellers')
          .insert({
            'user_id': uid,
            'store_name': auth.fullName.isNotEmpty && auth.fullName != 'User'
                ? "${auth.fullName}'s Store"
                : 'My Artisan Store',
            'category_id': _selectedCategoryId ?? 'brass',
            'subscription_plan': 'free',
          })
          .select('id');
      if (inserted is List && inserted.isNotEmpty) {
        return (inserted.first as Map<String, dynamic>)['id'] as String;
      }
      return 'seller_$uid';
    } catch (e) {
      throw Exception('Could not verify seller store: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Edit Handcrafted Product' : 'Add Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Image Picker ────────────────────────────────────
            _sectionTitle('📸 Product Photos'),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickImages,
              child: _selectedImages.isEmpty
                  ? Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 44, color: AppColors.primary.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photos',
                            style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          if (i == _selectedImages.length) {
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.add_rounded, color: AppColors.primary),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImages[i],
                                  width: 100,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedImages.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // ── Product Info ────────────────────────────────────
            _sectionTitle('📝 Product Details'),
            const SizedBox(height: 12),

            _textField(
              controller: _nameController,
              label: 'Product Name *',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            _textField(
              controller: _descriptionController,
              label: 'Description *',
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            _textField(
              controller: _materialController,
              label: 'Material / Technique *',
              hint: 'e.g. Hand-hammered brass, Chikankari embroidery',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 24),

            // ── Category ────────────────────────────────────────
            _sectionTitle('🏷️ Category'),
            const SizedBox(height: 12),

            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const Text('Failed to load categories'),
              data: (cats) => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cats.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '${cat.icon} ${cat.name}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Pricing ─────────────────────────────────────────
            _sectionTitle('💰 Pricing'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _priceController,
                    label: 'Selling Price ₹ *',
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _originalPriceController,
                    label: 'MRP ₹ (optional)',
                    hint: 'For discount %',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _textField(
              controller: _deliveryTimeController,
              label: 'Delivery Time',
              hint: 'e.g. 2-3 days in Moradabad',
            ),
            const SizedBox(height: 14),

            _textField(
              controller: _tagsController,
              label: 'Tags (comma-separated)',
              hint: 'e.g. brass, gift, wedding, handmade',
            ),

            const SizedBox(height: 20),

            // Handmade toggle
            SwitchListTile(
              value: _isHandmade,
              onChanged: (v) => setState(() => _isHandmade = v),
              activeThumbColor: AppColors.primary,
              title: Text(
                '🤲 This is a handmade product',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Handmade products get a special badge',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
              ),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 32),

            if (_isLoading && _uploadProgress > 0) ...[
              Text(
                'Uploading images... ${(_uploadProgress * 100).toInt()}%',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.productToEdit != null ? 'Update Product' : 'Add Product',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
  ).animate().fadeIn();

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
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
}
