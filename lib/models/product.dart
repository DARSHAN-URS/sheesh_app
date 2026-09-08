class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String categoryId;
  final String sellerId;
  // Seller info (joined from sellers table)
  final String sellerName;
  final String sellerStore;
  final String sellerLocation;
  final bool sellerIsVerified;
  // Images (joined from product_images table)
  final List<String> imageUrls;
  final double rating;
  final int reviewsCount;
  final bool isHandmade;
  final bool isFeatured;
  final bool inStock;
  final String materialOrTechnique;
  final String deliveryTime;
  final List<String> tags;
  final List<String> availableSizes;
  final List<String> availableColors;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.categoryId,
    required this.sellerId,
    this.sellerName = '',
    this.sellerStore = '',
    this.sellerLocation = 'Moradabad, UP',
    this.sellerIsVerified = false,
    required this.imageUrls,
    this.rating = 4.8,
    this.reviewsCount = 0,
    this.isHandmade = true,
    this.isFeatured = false,
    this.inStock = true,
    required this.materialOrTechnique,
    this.deliveryTime = '2-3 days in Moradabad',
    this.tags = const [],
    this.availableSizes = const [],
    this.availableColors = const [],
    this.createdAt,
  });

  int get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract image URLs from product_images join
    List<String> images = [];
    if (json['product_images'] != null) {
      final imgList = json['product_images'] as List<dynamic>;
      imgList.sort((a, b) => (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0));
      images = imgList.map((img) => img['url'] as String).toList();
    }

    // Extract seller info from sellers join
    final seller = json['sellers'] as Map<String, dynamic>?;

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null ? (json['original_price'] as num).toDouble() : null,
      categoryId: json['category_id'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: seller?['store_name'] as String? ?? '',
      sellerStore: seller?['store_name'] as String? ?? '',
      sellerLocation: seller?['location'] as String? ?? 'Moradabad, UP',
      sellerIsVerified: seller?['is_verified'] as bool? ?? false,
      imageUrls: images,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      isHandmade: json['is_handmade'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      inStock: json['in_stock'] as bool? ?? true,
      materialOrTechnique: json['material_or_technique'] as String? ?? '',
      deliveryTime: json['delivery_time'] as String? ?? '2-3 days in Moradabad',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      availableSizes: (json['available_sizes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      availableColors: (json['available_colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'original_price': originalPrice,
    'category_id': categoryId,
    'seller_id': sellerId,
    'rating': rating,
    'reviews_count': reviewsCount,
    'is_handmade': isHandmade,
    'is_featured': isFeatured,
    'in_stock': inStock,
    'material_or_technique': materialOrTechnique,
    'delivery_time': deliveryTime,
    'tags': tags,
    'available_sizes': availableSizes,
    'available_colors': availableColors,
  };

  Product copyWith({
    bool? inStock,
    bool? isFeatured,
    double? rating,
    int? reviewsCount,
  }) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      originalPrice: originalPrice,
      categoryId: categoryId,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerStore: sellerStore,
      sellerLocation: sellerLocation,
      sellerIsVerified: sellerIsVerified,
      imageUrls: imageUrls,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isHandmade: isHandmade,
      isFeatured: isFeatured ?? this.isFeatured,
      inStock: inStock ?? this.inStock,
      materialOrTechnique: materialOrTechnique,
      deliveryTime: deliveryTime,
      tags: tags,
      availableSizes: availableSizes,
      availableColors: availableColors,
      createdAt: createdAt,
    );
  }
}
