import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageService {
  static const String publicBucket = 'sheesh-media';

  /// Uploads an image file to Supabase Storage bucket and returns the public HTTPS URL.
  /// If unconfigured or offline, falls back safely to the local path.
  static Future<String> uploadImage({
    required File file,
    required String folder, // 'avatars', 'covers', 'products'
  }) async {
    try {
      final user = SupabaseService.currentUser;
      final userId = user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final ext = file.path.split('.').last.toLowerCase();
      final validExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp') ? ext : 'jpg';
      final fileName = '$folder/${userId}_${DateTime.now().millisecondsSinceEpoch}.$validExt';

      final client = SupabaseService.client;

      // Try uploading to Supabase Storage
      await client.storage.from(publicBucket).upload(
        fileName,
        file,
        fileOptions: FileOptions(
          contentType: 'image/$validExt',
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from(publicBucket).getPublicUrl(fileName);
      if (publicUrl.isNotEmpty) {
        return publicUrl;
      }
    } catch (e) {
      debugPrint('Supabase storage upload notice (using local file fallback): $e');
    }

    // Fallback to local file path so UI never breaks
    return file.path;
  }
}

