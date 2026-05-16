import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class GalleryImage {
  final String id;
  final String title;
  final String imageUrl;
  final String author;
  final String sourceUrl;

  const GalleryImage({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.author,
    required this.sourceUrl,
  });
}

class GalleryService {
  static const _fallback = [
    GalleryImage(
      id: 'kaaba-night',
      title: 'Kabe Gece',
      imageUrl: 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?auto=format&fit=crop&w=1400&q=85',
      author: 'Unsplash',
      sourceUrl: 'https://unsplash.com',
    ),
    GalleryImage(
      id: 'mosque-istanbul',
      title: 'Cami Silüeti',
      imageUrl: 'https://images.unsplash.com/photo-1542816417-0983c9c9ad53?auto=format&fit=crop&w=1400&q=85',
      author: 'Unsplash',
      sourceUrl: 'https://unsplash.com',
    ),
    GalleryImage(
      id: 'quran-close',
      title: 'Kur’an ve Tesbih',
      imageUrl: 'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?auto=format&fit=crop&w=1400&q=85',
      author: 'Unsplash',
      sourceUrl: 'https://unsplash.com',
    ),
    GalleryImage(
      id: 'ramadan-lantern',
      title: 'Ramazan Işığı',
      imageUrl: 'https://images.unsplash.com/photo-1552909172-6a2f0b079a8d?auto=format&fit=crop&w=1400&q=85',
      author: 'Unsplash',
      sourceUrl: 'https://unsplash.com',
    ),
  ];

  Future<List<GalleryImage>> fetchIslamicWallpapers() async {
    final key = dotenv.env['UNSPLASH_ACCESS_KEY'] ?? '';

    if (key.isEmpty) {
      return _fallback;
    }

    try {
      final uri = Uri.https(
        'api.unsplash.com',
        '/search/photos',
        {
          'query': 'islamic architecture mosque ramadan',
          'per_page': '24',
          'orientation': 'portrait',
          'client_id': key,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 16));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? [];

      final images = results.map((item) {
        final map = item as Map<String, dynamic>;
        final urls = map['urls'] as Map<String, dynamic>? ?? {};
        final user = map['user'] as Map<String, dynamic>? ?? {};

        return GalleryImage(
          id: (map['id'] ?? '').toString(),
          title: (map['alt_description'] ?? map['description'] ?? 'İslami Duvar Kağıdı').toString(),
          imageUrl: (urls['regular'] ?? urls['full'] ?? '').toString(),
          author: (user['name'] ?? 'Unsplash').toString(),
          sourceUrl: (map['links'] as Map<String, dynamic>? ?? {})['html']?.toString() ?? 'https://unsplash.com',
        );
      }).where((item) => item.imageUrl.isNotEmpty).toList(growable: false);

      return images.isEmpty ? _fallback : images;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Gallery fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return _fallback;
    }
  }


  Future<File> saveImageToDevice(GalleryImage image) async {
    try {
      final response = await http.get(Uri.parse(image.imageUrl)).timeout(const Duration(seconds: 25));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AppException(
          AppStrings.wallpaperSaveFailed,
          code: 'wallpaper_download_failed',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = image.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/huzur_wallpaper_$safeName.jpg');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file;
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Wallpaper save failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.wallpaperSaveFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'wallpaper_save_failed',
      );
    }
  }


    if (_fallback.isEmpty) {
      throw const AppException('Galeri içeriği bulunamadı.', code: 'gallery_empty');
    }
    return _fallback[index % _fallback.length];
  }
}
