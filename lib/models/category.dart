class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isActive;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String? ?? '#9E1B4C',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'is_active': isActive,
    'sort_order': sortOrder,
  };

  String get hindiName {
    switch (id) {
      case 'suits':
        return 'सूट और ज़रदोज़ी';
      case 'brass':
        return 'पीतल के बर्तन और शिल्प';
      case 'jewels':
        return 'कुंदन और आभूषण';
      case 'sweets':
        return 'मिठाई और बेक्स';
      case 'henna':
        return 'मेहंदी और श्रृंगार';
      default:
        return name;
    }
  }
}
