class SavedAddress {
  final String id;
  final String label; // "Home", "Work", "Other"
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    this.label = 'Home',
    required this.name,
    required this.phone,
    required this.street,
    this.city = 'Moradabad',
    this.state = 'Uttar Pradesh',
    this.postalCode = '244001',
    this.isDefault = false,
  });

  String get formattedAddress => '$street, $city, $state - $postalCode';

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? 'Moradabad',
      state: json['state'] as String? ?? 'Uttar Pradesh',
      postalCode: json['postal_code'] as String? ?? '244001',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'is_default': isDefault,
    };
  }
}
