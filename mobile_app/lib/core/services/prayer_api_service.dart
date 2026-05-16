import 'package:http/http.dart' as http;

import '../config/app_constants.dart';
import '../models/prayer_times.dart';
import 'data_repository_hub.dart';

class PrayerApiService {
  PrayerApiService({
    DataRepositoryHub? repositoryHub,
  }) : _hub = repositoryHub ?? DataRepositoryHub();

  final DataRepositoryHub _hub;

  Future<PrayerTimes> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    int? calculationMethod,
    int hijriOffset = 0,
  }) async {
    final formatted = '${date.day}-${date.month}-${date.year}';
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings/$formatted',
    ).replace(
      queryParameters: {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'method': '${calculationMethod ?? AppConstants.aladhanMethod}',
        if (hijriOffset != 0) 'adjustment': '$hijriOffset',
      },
    );

    final result = await _hub.fetchPrayerTimesWithFallback(
      networkUri: uri,
      date: date,
    );

    return result.data;
  }
}
