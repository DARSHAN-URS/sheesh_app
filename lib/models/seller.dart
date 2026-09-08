class Seller {
  final String id;
  final String userId;
  final String name;       // from users.full_name
  final String storeName;
  final String tagline;
  final String bio;
  final String avatarUrl;
  final String coverUrl;
  final String location;
  final String categoryId;
  final double rating;
  final int reviewsCount;
  final int productsCount;
  final int ordersCompleted;
  final bool isVerified;
  final bool isFeatured;
  final String memberSince;
  final String responseTime;
  final String phoneNumber;
  final String craftStory;
  final bool kycVerified;

  const Seller({
    required this.id,
    required this.userId,
    required this.name,
    required this.storeName,
    required this.tagline,
    required this.bio,
    required this.avatarUrl,
    required this.coverUrl,
    required this.location,
    required this.categoryId,
    required this.rating,
    required this.reviewsCount,
    required this.productsCount,
    required this.ordersCompleted,
    this.isVerified = false,
    this.isFeatured = false,
    required this.memberSince,
    required this.responseTime,
    required this.phoneNumber,
    required this.craftStory,
    this.kycVerified = false,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return Seller(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: user?['full_name'] as String? ?? json['store_name'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      location: json['location'] as String? ?? 'Moradabad, UP',
      categoryId: json['category_id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      productsCount: json['products_count'] as int? ?? 0,
      ordersCompleted: json['orders_completed'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      memberSince: json['member_since'] as String? ?? '',
      responseTime: json['response_time'] as String? ?? 'Within 2 hours',
      phoneNumber: json['phone_number'] as String? ?? '',
      craftStory: json['craft_story'] as String? ?? '',
      kycVerified: json['kyc_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'store_name': storeName,
    'tagline': tagline,
    'bio': bio,
    'avatar_url': avatarUrl,
    'cover_url': coverUrl,
    'location': location,
    'category_id': categoryId,
    'rating': rating,
    'reviews_count': reviewsCount,
    'products_count': productsCount,
    'orders_completed': ordersCompleted,
    'is_verified': isVerified,
    'is_featured': isFeatured,
    'member_since': memberSince,
    'response_time': responseTime,
    'phone_number': phoneNumber,
    'craft_story': craftStory,
    'kyc_verified': kycVerified,
  };
}
