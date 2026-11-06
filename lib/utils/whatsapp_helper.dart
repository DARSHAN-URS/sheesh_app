import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class WhatsAppHelper {
  /// Opens WhatsApp chat with the store owner / artisan.
  /// Uses the store owner's actual listed phone number.
  /// If no phone number is listed, notifies the user cleanly instead of using fake fallback numbers.
  static Future<bool> openArtisanChat({
    BuildContext? context,
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

    // If no valid phone number is registered for this store owner
    if (cleanNumber.isEmpty || cleanNumber.length < 10) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$artisanName has not linked a WhatsApp mobile number yet.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return false;
    }

    String message;
    if (productName != null) {
      final priceStr = productPrice != null ? ' (₹${productPrice.toInt()})' : '';
      message = 'Namaste $artisanName 🙏! I found your handcrafted piece "$productName"$priceStr on Sheesh. I would love to discuss customization / order details.';
    } else {
      message = 'Namaste $artisanName 🙏! I am exploring your artisan storefront on Sheesh and have an inquiry about your handcrafted creations.';
    }

    final uri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp for $artisanName (+${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2)}).'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return launched;
    } catch (_) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp for $artisanName.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  /// Opens phone dialer directly with the artisan's contact number
  static Future<bool> makeArtisanCall({
    BuildContext? context,
    required String? phoneNumber,
    required String artisanName,
  }) async {
    String cleanNumber = (phoneNumber ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNumber.isEmpty || cleanNumber.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$artisanName has not listed a contact phone number yet.'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
      return false;
    }

    final uri = Uri.parse('tel:$cleanNumber');
    try {
      return await launchUrl(uri);
    } catch (_) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling $artisanName: $cleanNumber'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return false;
    }
  }
}
