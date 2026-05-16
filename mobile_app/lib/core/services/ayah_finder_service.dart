import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class AyahFinderService {
  Future<void> uploadAudio(File file) async {
    final endpoint = dotenv.env['AYAH_FINDER_ENDPOINT'] ?? '';

    if (endpoint.isEmpty || endpoint.contains('yourdomain')) {
      throw const AppException(
        AppStrings.ayahUploadDraft,
        code: 'ayah_finder_endpoint_missing',
      );
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.files.add(await http.MultipartFile.fromPath('audio', file.path));
      final response = await request.send().timeout(const Duration(seconds: 45));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AppException(
          AppStrings.genericError,
          code: 'ayah_finder_upload_failed',
        );
      }
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Ayah finder upload failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.genericError,
        cause: error,
        stackTrace: stackTrace,
        code: 'ayah_finder_failed',
      );
    }
  }
}
