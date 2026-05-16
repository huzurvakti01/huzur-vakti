import 'package:geolocator/geolocator.dart';

import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class LocationService {
  Future<Position> currentPosition({
    double fallbackLat = 41.0082,
    double fallbackLon = 28.9784,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.warning(
          'Location permission denied',
          context: {'permission': permission.name},
        );
        throw const PermissionAppException(
          'Konum izni verilmedi. Namaz vakitleri için ayarlardan konum izni verebilirsiniz.',
        );
      }

      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } on PermissionAppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Location read failed, using fallback location',
        error: error,
        stackTrace: stackTrace,
        context: {'fallbackLat': fallbackLat, 'fallbackLon': fallbackLon},
      );
      return _fallback(fallbackLat, fallbackLon);
    }
  }

  Position _fallback(double lat, double lon) {
    return Position(
      longitude: lon,
      latitude: lat,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
