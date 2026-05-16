import 'dart:math';

import 'location_service.dart';

class QiblaService {
  final LocationService locationService;

  QiblaService({required this.locationService});

  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  Future<double> qiblaBearingFromCurrentLocation() async {
    final position = await locationService.currentPosition();
    return qiblaBearing(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  double qiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = _degToRad(latitude);
    final lat2 = _degToRad(kaabaLatitude);
    final dLon = _degToRad(kaabaLongitude - longitude);

    final y = sin(dLon);
    final x = cos(lat1) * tan(lat2) - sin(lat1) * cos(dLon);
    final bearing = _radToDeg(atan2(y, x));

    return (bearing + 360) % 360;
  }

  double _degToRad(double deg) => deg * pi / 180;
  double _radToDeg(double rad) => rad * 180 / pi;
}
