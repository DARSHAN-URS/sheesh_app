import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/address.dart';
import '../providers/addresses_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AddressesManagerSheet extends ConsumerWidget {
  final SavedAddress? selectedAddress;
  final void Function(SavedAddress)? onAddressSelected;

  const AddressesManagerSheet({
    super.key,
    this.selectedAddress,
    this.onAddressSelected,
  });

  static Future<SavedAddress?> show({
    required BuildContext context,
    SavedAddress? selectedAddress,
    void Function(SavedAddress)? onAddressSelected,
  }) {
    return showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressesManagerSheet(
        selectedAddress: selectedAddress,
        onAddressSelected: onAddressSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);
    final addresses = addressesAsync.valueOrNull ?? [];
    final canAdd = addresses.length < AddressesNotifier.maxAddresses;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Delivery Addresses',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: addresses.length >= AddressesNotifier.maxAddresses
                                  ? const Color(0xFFD64438).withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${addresses.length}/${AddressesNotifier.maxAddresses} saved',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: addresses.length >= AddressesNotifier.maxAddresses
                                    ? const Color(0xFFD64438)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Save up to ${AddressesNotifier.maxAddresses} addresses with PIN code & delivery instructions',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
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

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),

          // Address List
          Expanded(
            child: addressesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('Failed to load addresses: $err'),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF3EC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pin_drop_outlined, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No Saved Addresses Yet',
                            style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your home, workshop or office delivery address with PIN code for quick checkout.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final addr = list[i];
                    final isCurrentSelected = selectedAddress?.id == addr.id;

                    return _buildAddressCard(
                      context: context,
                      ref: ref,
                      address: addr,
                      isSelected: isCurrentSelected,
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Bar: Add New Address
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!canAdd) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD64438)),
                        const SizedBox(width: 6),
                        Text(
                          'Maximum limit reached (5/5). Edit or delete an address to add a new one.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD64438),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAdd ? AppColors.primary : Colors.grey.shade300,
                      foregroundColor: canAdd ? Colors.white : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: canAdd ? () => _openAddressForm(context, ref) : null,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: Text(
                      canAdd
                          ? '+ Add New Address (${addresses.length}/5)'
                          : 'Maximum 5 Addresses Reached',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required BuildContext context,
    required WidgetRef ref,
    required SavedAddress address,
    required bool isSelected,
  }) {
    IconData labelIcon;
    Color labelColor;
    if (address.label.toLowerCase() == 'home') {
      labelIcon = Icons.home_rounded;
      labelColor = const Color(0xFF5A1629);
    } else if (address.label.toLowerCase() == 'work') {
      labelIcon = Icons.work_rounded;
      labelColor = const Color(0xFF2A7B54);
    } else {
      labelIcon = Icons.location_on_rounded;
      labelColor = const Color(0xFFC89B3C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFBF4F0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (onAddressSelected != null) {
            onAddressSelected!(address);
            Navigator.pop(context, address);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Label, Default badge, and Edit/Delete menu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: labelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(labelIcon, size: 12, color: labelColor),
                        const SizedBox(width: 4),
                        Text(
                          address.label.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A7B54).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A7B54),
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    onPressed: () => _openAddressForm(context, ref, addressToEdit: address),
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    onPressed: () => _confirmDelete(context, ref, address),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Name & Phone
              Row(
                children: [
                  Text(
                    address.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${address.phone}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Street & Landmark
              Text(
                address.street,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDark, height: 1.3),
              ),
              if (address.landmark != null && address.landmark!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Landmark: ${address.landmark}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 4),

              // City, State & PIN Code Badge
              Row(
                children: [
                  Text(
                    '${address.city}, ${address.state}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0DDD4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PIN: ${address.postalCode}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A1629),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Footer Actions: "Deliver Here" & "Set Default"
              Row(
                children: [
                  if (!address.isDefault)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        ref.read(addressesProvider.notifier).setDefaultAddress(address.id);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                      label: Text(
                        'Set as Default',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (onAddressSelected != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFF2A7B54) : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        onAddressSelected!(address);
                        Navigator.pop(context, address);
                      },
                      child: Text(
                        isSelected ? 'Selected ✓' : 'Deliver Here',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SavedAddress address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Address', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${address.name} (${address.label})"?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(addressesProvider.notifier).deleteAddress(address.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAddressForm(BuildContext context, WidgetRef ref, {SavedAddress? addressToEdit}) {
    final isEditing = addressToEdit != null;

    final nameCtrl = TextEditingController(text: isEditing ? addressToEdit.name : '');
    final phoneCtrl = TextEditingController(text: isEditing ? addressToEdit.phone : '');
    final streetCtrl = TextEditingController(text: isEditing ? addressToEdit.street : '');
    final landmarkCtrl = TextEditingController(text: isEditing ? (addressToEdit.landmark ?? '') : '');
    final cityCtrl = TextEditingController(text: isEditing ? addressToEdit.city : '');
    final stateCtrl = TextEditingController(text: isEditing ? addressToEdit.state : '');
    final pinCtrl = TextEditingController(text: isEditing ? addressToEdit.postalCode : '');

    String selectedLabel = isEditing ? addressToEdit.label : 'Home';
    bool makeDefault = isEditing ? addressToEdit.isDefault : false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Delivery Address' : 'Add New Delivery Address',
                      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                Text(
                  'All fields marked with * are required for delivery',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),

                // Label selector (Home / Work / Other)
                Row(
                  children: [
                    _buildLabelChip(
                      title: 'Home 🏠',
                      isSelected: selectedLabel == 'Home',
                      onTap: () => setModalState(() => selectedLabel = 'Home'),
                    ),
                    const SizedBox(width: 8),
                    _buildLabelChip(
                      title: 'Work 💼',
                      isSelected: selectedLabel == 'Work',
                      onTap: () => setModalState(() => selectedLabel = 'Work'),
                    ),
                    const SizedBox(width: 8),
                    _buildLabelChip(
                      title: 'Other 📍',
                      isSelected: selectedLabel == 'Other',
                      onTap: () => setModalState(() => selectedLabel = 'Other'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Full Name
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Recipient Full Name *',
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: '10-digit mobile number',
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // PIN Code & City Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'PIN Code *',
                          hintText: 'e.g. 244001',
                          counterText: '',
                          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: cityCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'City *',
                          hintText: 'e.g. Moradabad',
                          prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Street Address / House / Flat
                TextField(
                  controller: streetCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Flat / House No., Building, Street & Colony *',
                    hintText: 'e.g. Flat 302, Green Valley Apartments, Civil Lines',
                    prefixIcon: const Icon(Icons.signpost_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 12),

                // Landmark & State Row
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: landmarkCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Landmark (Optional)',
                          hintText: 'Near Jama Masjid',
                          prefixIcon: const Icon(Icons.near_me_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: stateCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'State *',
                          hintText: 'e.g. Uttar Pradesh',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Make Default Switch
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: makeDefault,
                  onChanged: (val) => setModalState(() => makeDefault = val ?? false),
                  title: Text(
                    'Make this my default delivery address',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),

                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final street = streetCtrl.text.trim();
                            final city = cityCtrl.text.trim();
                            final pincode = pinCtrl.text.trim();
                            final landmark = landmarkCtrl.text.trim();
                            final stateName = stateCtrl.text.trim();

                            if (name.isEmpty) {
                              _showToast(context, 'Please enter recipient name');
                              return;
                            }
                            if (phone.length < 10) {
                              _showToast(context, 'Please enter a valid 10-digit mobile number');
                              return;
                            }
                            if (pincode.length != 6) {
                              _showToast(context, 'Please enter a valid 6-digit postal PIN code');
                              return;
                            }
                            if (street.isEmpty) {
                              _showToast(context, 'Please enter street / house address');
                              return;
                            }
                            if (city.isEmpty) {
                              _showToast(context, 'Please enter city');
                              return;
                            }
                            if (stateName.isEmpty) {
                              _showToast(context, 'Please enter state');
                              return;
                            }

                            setModalState(() => isSaving = true);
                            try {
                              if (isEditing) {
                                await ref.read(addressesProvider.notifier).updateAddress(
                                      id: addressToEdit.id,
                                      label: selectedLabel,
                                      name: name,
                                      phone: phone,
                                      street: street,
                                      landmark: landmark.isNotEmpty ? landmark : null,
                                      city: city,
                                      stateName: stateName,
                                      postalCode: pincode,
                                      isDefault: makeDefault,
                                    );
                              } else {
                                await ref.read(addressesProvider.notifier).addAddress(
                                      label: selectedLabel,
                                      name: name,
                                      phone: phone,
                                      street: street,
                                      landmark: landmark.isNotEmpty ? landmark : null,
                                      city: city,
                                      stateName: stateName,
                                      postalCode: pincode,
                                      isDefault: makeDefault,
                                    );
                              }
                              if (modalCtx.mounted) Navigator.pop(modalCtx);
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              _showToast(context, '$e');
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Save Address Changes' : 'Save Address (${ref.read(addressesProvider).valueOrNull?.length ?? 0}/5)',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFFAF3EC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

