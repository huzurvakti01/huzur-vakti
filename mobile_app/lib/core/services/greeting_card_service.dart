import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class GreetingCardService {
  Future<File> createCard({
    required String message,
    required int backgroundIndex,
    String? backgroundUrl,
  }) async {
    try {
      final palette = [
        img.ColorRgb8(14, 124, 102),
        img.ColorRgb8(231, 197, 104),
        img.ColorRgb8(9, 26, 23),
      ];

      img.Image image;

      if (backgroundUrl != null && backgroundUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(backgroundUrl)).timeout(const Duration(seconds: 20));
        final decoded = img.decodeImage(response.bodyBytes);
        if (decoded == null) {
          image = img.Image(width: 1080, height: 1350);
          img.fill(image, color: palette[backgroundIndex % palette.length]);
        } else {
          image = img.copyResizeCropSquare(decoded, size: 1350);
          image = img.copyResize(image, width: 1080, height: 1350);
          img.fillRect(
            image,
            x1: 0,
            y1: 0,
            x2: 1080,
            y2: 1350,
            color: img.ColorRgba8(0, 0, 0, 76),
          );
        }
      } else {
        image = img.Image(width: 1080, height: 1350);
        final bg = palette[backgroundIndex % palette.length];
        img.fill(image, color: bg);
      }

      img.fillCircle(
        image,
        x: 880,
        y: 180,
        radius: 240,
        color: img.ColorRgba8(255, 255, 255, 42),
      );
      img.fillCircle(
        image,
        x: 180,
        y: 1180,
        radius: 260,
        color: img.ColorRgba8(255, 255, 255, 30),
      );

      img.drawString(
        image,
        message.isEmpty ? 'Hayırlı Cumalar' : message,
        font: img.arial48,
        x: 120,
        y: 540,
        color: img.ColorRgb8(255, 255, 255),
      );

      img.drawString(
        image,
        'Huzur Vakti',
        font: img.arial24,
        x: 120,
        y: 1210,
        color: img.ColorRgba8(255, 255, 255, 210),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/huzur_vakti_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(img.encodePng(image), flush: true);
      return file;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Greeting card generation failed',
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.genericError,
        cause: error,
        stackTrace: stackTrace,
        code: 'greeting_card_failed',
      );
    }
  }
}
