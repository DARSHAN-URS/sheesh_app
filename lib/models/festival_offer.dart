import 'package:flutter/material.dart';

class FestivalOffer {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String? couponCode;
  final String? discountText;
  final String? categoryId;
  final List<Color> backgroundGradient;
  final Color accentColor;
  final String? imageUrl;
  final int priority;

  const FestivalOffer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.couponCode,
    this.discountText,
    this.categoryId,
    required this.backgroundGradient,
    this.accentColor = const Color(0xFFE8C87A),
    this.imageUrl,
    this.priority = 1,
  });

  factory FestivalOffer.fromJson(Map<String, dynamic> json) {
    List<Color> gradient = [
      const Color(0xFF5A1629),
      const Color(0xFF2E0B15),
    ];
    if (json['background_gradient'] is List && (json['background_gradient'] as List).isNotEmpty) {
      gradient = (json['background_gradient'] as List).map((hex) {
        return _parseHexColor(hex.toString()) ?? const Color(0xFF5A1629);
      }).toList();
      if (gradient.length == 1) {
        gradient.add(gradient.first.withValues(alpha: 0.8));
      }
    }

    Color accent = const Color(0xFFE8C87A);
    if (json['accent_color'] != null) {
      accent = _parseHexColor(json['accent_color'].toString()) ?? accent;
    }

    return FestivalOffer(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Festive Offer',
      subtitle: json['subtitle']?.toString() ?? '',
      badge: json['badge']?.toString() ?? 'SPECIAL OFFER',
      couponCode: json['coupon_code']?.toString(),
      discountText: json['discount_text']?.toString(),
      categoryId: json['category_id']?.toString(),
      backgroundGradient: gradient,
      accentColor: accent,
      imageUrl: json['image_url']?.toString(),
      priority: (json['priority'] as num?)?.toInt() ?? 1,
    );
  }

  static Color? _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }

  // Pre-configured default festival offers for instant local / offline rendering
  static const List<FestivalOffer> defaultOffers = [
    FestivalOffer(
      id: 'fest_diwali_brass',
      title: 'Diwali Artisan Dazzle 🪔',
      subtitle: 'Up to 35% OFF on hand-cast brass urlis, diyas & shadow filigree lamps.',
      badge: 'FESTIVAL SPECIAL',
      couponCode: 'PEETAL10',
      discountText: '35% OFF',
      categoryId: 'brass',
      backgroundGradient: [Color(0xFF5A1629), Color(0xFF2E0B15)],
      accentColor: Color(0xFFE8C87A),
      imageUrl: 'https://images.unsplash.com/photo-1577083552431-6e5fd01aa342?w=800',
      priority: 1,
    ),
    FestivalOffer(
      id: 'fest_zari_suits',
      title: 'Moradabad Zari & Silk Utsav 👑',
      subtitle: 'Flat ₹150 OFF on handcrafted pure georgette & chanderi festive suits.',
      badge: 'EXCLUSIVE COLLECTION',
      couponCode: 'SHEESH100',
      discountText: 'FLAT ₹150 OFF',
      categoryId: 'suits',
      backgroundGradient: [Color(0xFF7D1D3F), Color(0xFF4A0E24)],
      accentColor: Color(0xFFF39C12),
      imageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800',
      priority: 2,
    ),
    FestivalOffer(
      id: 'fest_wedding_jewels',
      title: 'Shahi Wedding Jewellery Mela ✨',
      subtitle: 'Handmade meenakari & kundan sets directly from local artisan workshops.',
      badge: 'WEDDING SEASON',
      couponCode: 'FIRSTSHEESH',
      discountText: 'SPECIAL GIFT INCLUDED',
      categoryId: 'jewellery',
      backgroundGradient: [Color(0xFF421226), Color(0xFF1F050F)],
      accentColor: Color(0xFFE5A93C),
      imageUrl: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800',
      priority: 3,
    ),
    FestivalOffer(
      id: 'fest_free_express',
      title: 'City Express Artisan Delivery 🚚',
      subtitle: 'Free delivery anywhere in Moradabad on handcrafted orders over ₹499.',
      badge: 'LIMITED TIME',
      couponCode: 'MORADABADFREE',
      discountText: 'FREE SHIPPING',
      categoryId: null,
      backgroundGradient: [Color(0xFF1A4D35), Color(0xFF0F2E20)],
      accentColor: Color(0xFF4ADE80),
      imageUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800',
      priority: 4,
    ),
  ];
}

