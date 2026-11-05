class SavedAddress {
  final String id;
  final String label; // "Home", "Work", "Other"
  final String name;
  final String phone;
  final String street;
  final String? landmark;
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
    this.landmark,
    this.city = 'Moradabad',
    this.state = 'Uttar Pradesh',
    this.postalCode = '244001',
    this.isDefault = false,
  });

  String get formattedAddress {
    final landmarkPart = (landmark != null && landmark!.trim().isNotEmpty) ? ', Near ${landmark!.trim()}' : '';
    return '$street$landmarkPart, $city, $state - $postalCode';
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    String? name,
    String? phone,
    String? street,
    String? landmark,
    String? city,
    String? state,
    String? postalCode,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String? ?? '',
      landmark: json['landmark'] as String?,
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
      if (landmark != null && landmark!.trim().isNotEmpty) 'landmark': landmark,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'is_default': isDefault,
    };
  }
}
