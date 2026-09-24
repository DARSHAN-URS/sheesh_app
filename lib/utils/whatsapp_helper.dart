import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  /// Opens WhatsApp chat with the artisan or support desk.
  static Future<bool> openArtisanChat({
    required String? phoneNumber,
    required String artisanName,
    String? productName,
    double? productPrice,
  }) async {
    String cleanNumber = (phoneNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = cleanNumber.substring(1);
    }
    if (cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }
    // Fallback Moradabad artisan cell hotline if artisan phone is unlisted
    if (cleanNumber.isEmpty || cleanNumber.length < 10) {
      cleanNumber = '918007433744';
    }

    String message;
    if (productName != null) {
      final priceStr = productPrice != null ? ' (₹${productPrice.toInt()})' : '';
      message = 'Namaste $artisanName 🙏! I found your handcrafted piece "$productName"$priceStr on Sheesh. I would love to discuss customization / order details.';
    } else {
      message = 'Namaste $artisanName 🙏! I am exploring your artisan storefront on Sheesh and have an inquiry about your handcrafted creations.';
    }

    final uri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
