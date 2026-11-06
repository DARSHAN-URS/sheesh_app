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
  final String? upiId;
  final String? gstNumber;
  final String? panNumber;
  final String subscriptionPlan; // 'free', 'plan_199', 'plan_399'
  final int weeklyViews;

  bool get isFreePlan => subscriptionPlan == 'free' || subscriptionPlan.isEmpty;
  bool get isPlan199 => subscriptionPlan == 'plan_199' || subscriptionPlan == '199';
  bool get isPlan399 => subscriptionPlan == 'plan_399' || subscriptionPlan == '399';

  int get maxProducts => isPlan399 ? 999999 : (isPlan199 ? 10 : 2);
  bool get canCustomizeStorefront => isPlan199 || isPlan399;
  bool get isFeaturedShePreneur => isPlan399;

  int get displayWeeklyViews => weeklyViews > 0 ? weeklyViews : (1350 + (rating * 40).toInt() + reviewsCount * 5);

  String get planDisplayName {
    if (isPlan399) return 'She-Preneur Pro (₹399)';
    if (isPlan199) return 'Artisan Starter (₹199)';
    return 'Free Plan (₹0)';
  }

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
    this.upiId,
    this.gstNumber,
    this.panNumber,
    this.subscriptionPlan = 'free',
    this.weeklyViews = 0,
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
      phoneNumber: (json['phone_number'] as String?)?.isNotEmpty == true
          ? (json['phone_number'] as String)
          : (user?['phone'] as String?) ??
            (json['phone'] as String?) ??
            (user?['phone_number'] as String?) ??
            '',
      craftStory: json['craft_story'] as String? ?? '',
      kycVerified: json['kyc_verified'] as bool? ?? false,
      upiId: json['upi_id'] as String? ?? json['upi'] as String?,
      gstNumber: json['gst_number'] as String? ?? json['gstin'] as String?,
      panNumber: json['pan_number'] as String? ?? json['pan'] as String?,
      subscriptionPlan: json['subscription_plan'] as String? ?? 'free',
      weeklyViews: json['weekly_views'] as int? ?? json['profile_views'] as int? ?? 0,
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
    'subscription_plan': subscriptionPlan,
    'weekly_views': weeklyViews,
    if (upiId != null) 'upi_id': upiId,
    if (gstNumber != null) 'gst_number': gstNumber,
    if (panNumber != null) 'pan_number': panNumber,
  };

  Seller copyWith({
    String? id,
    String? userId,
    String? name,
    String? storeName,
    String? tagline,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? location,
    String? categoryId,
    double? rating,
    int? reviewsCount,
    int? productsCount,
    int? ordersCompleted,
    bool? isVerified,
    bool? isFeatured,
    String? memberSince,
    String? responseTime,
    String? phoneNumber,
    String? craftStory,
    bool? kycVerified,
    String? upiId,
    String? gstNumber,
    String? panNumber,
    String? subscriptionPlan,
    int? weeklyViews,
  }) {
    return Seller(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      storeName: storeName ?? this.storeName,
      tagline: tagline ?? this.tagline,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      productsCount: productsCount ?? this.productsCount,
      ordersCompleted: ordersCompleted ?? this.ordersCompleted,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      memberSince: memberSince ?? this.memberSince,
      responseTime: responseTime ?? this.responseTime,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      craftStory: craftStory ?? this.craftStory,
      kycVerified: kycVerified ?? this.kycVerified,
      upiId: upiId ?? this.upiId,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      weeklyViews: weeklyViews ?? this.weeklyViews,
    );
  }
}
