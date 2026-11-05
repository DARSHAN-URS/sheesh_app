import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config.dart';
import '../models/seller.dart';
import '../models/product.dart';

class ShareHelper {
  /// Shares the artisan store using the actual app download link,
  /// copies the link directly to the clipboard, and triggers the native OS share dialog.
  static Future<void> shareStore(BuildContext context, Seller seller) async {
    const appLink = AppConfig.appPlayStoreUrl;

    // 1. Copy app link to clipboard
    await Clipboard.setData(const ClipboardData(text: appLink));

    // 2. Compose attractive sharing text
    final shareText = '''
Namaste! 🙏 Explore "${seller.storeName}" on Sheesh — India's authentic Moradabad artisan marketplace.

${seller.tagline.isNotEmpty ? '✨ ${seller.tagline}\n' : ''}📍 Handcrafted in ${seller.location}

Download the Sheesh app to order directly from master artisans:
$appLink
'''.trim();

    // 3. Show confirmation feedback to the user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'App link copied to clipboard & sharing! ✓',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // 4. Open native OS share sheet
    try {
      await Share.share(
        shareText,
        subject: 'Explore ${seller.storeName} on Sheesh',
      );
    } catch (_) {
      // Fallback: clipboard copy already succeeded
    }
  }

  /// Shares a product creation with the app link and copies link to clipboard.
  static Future<void> shareProduct(BuildContext context, Product product) async {
    const appLink = AppConfig.appPlayStoreUrl;

    // 1. Copy app link to clipboard
    await Clipboard.setData(const ClipboardData(text: appLink));

    // 2. Compose sharing text
    final shareText = '''
Check out this authentic handcrafted creation on Sheesh:
"${product.name}" (₹${product.price.toInt()})
Crafted by ${product.sellerStore} in Moradabad.

Download the Sheesh app to discover and order:
$appLink
'''.trim();

    // 3. Show feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Product & App link copied to clipboard! ✓',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // 4. Open native OS share sheet
    try {
      await Share.share(
        shareText,
        subject: 'Check out ${product.name} on Sheesh',
      );
    } catch (_) {
      // Fallback: clipboard copy already succeeded
    }
  }

  /// General Sheesh app sharing for buyers and community members.
  static Future<void> shareApp(BuildContext context) async {
    const appLink = AppConfig.appPlayStoreUrl;

    // 1. Copy app link to clipboard
    await Clipboard.setData(const ClipboardData(text: appLink));

    // 2. Compose text
    final shareText = '''
Namaste! 🙏 Discover Sheesh — India's authentic marketplace connecting you directly with the master artisans of Moradabad (Peetal Nagri).

Buy handcrafted brassware, bridal fashion, kundan jewels, and decor with 0 middlemen!

Download Sheesh on Android:
$appLink
'''.trim();

    // 3. Show feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sheesh app link copied to clipboard! ✓',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2A7B54),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    // 4. Open share sheet
    try {
      await Share.share(
        shareText,
        subject: 'Download Sheesh — Moradabad Artisan Marketplace',
      );
    } catch (_) {
      // Fallback
    }
  }
}
