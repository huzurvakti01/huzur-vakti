import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

class TravelerModeService extends ChangeNotifier {
  final LocationService locationService;

  TravelerModeService({required this.locationService});

  static const _latKey = 'home_lat';
  static const _lonKey = 'home_lon';
  static const _activeKey = 'traveler_active';
  static const _thresholdKey = 'traveler_threshold';

  double? _homeLat;
  double? _homeLon;
  double _thresholdKm = 90;
  double? _distanceKm;
  bool _active = false;

  double? get distanceKm => _distanceKm;
  double get thresholdKm => _thresholdKm;
  bool get active => _active;
  bool get hasHome => _homeLat != null && _homeLon != null;
  bool get shouldSuggest => hasHome && !_active && ((_distanceKm ?? 0) >= _thresholdKm);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _homeLat = prefs.getDouble(_latKey);
    _homeLon = prefs.getDouble(_lonKey);
    _thresholdKm = prefs.getDouble(_thresholdKey) ?? 90;
    _active = prefs.getBool(_activeKey) ?? false;
    notifyListeners();
    await refresh();
  }

  Future<void> saveCurrentAsHome() async {
    final pos = await locationService.currentPosition();
    final prefs = await SharedPreferences.getInstance();
    _homeLat = pos.latitude;
    _homeLon = pos.longitude;
    await prefs.setDouble(_latKey, _homeLat!);
    await prefs.setDouble(_lonKey, _homeLon!);
    await refresh();
  }

  Future<void> setActive(bool value) async {
    _active = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, value);
    notifyListeners();
  }

  Future<void> setThreshold(double km) async {
    _thresholdKm = km.clamp(70, 120).toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, _thresholdKm);
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    if (!hasHome) return;
    final pos = await locationService.currentPosition();
    _distanceKm = _haversine(_homeLat!, _homeLon!, pos.latitude, pos.longitude);
    if ((_distanceKm ?? 0) < _thresholdKm) _active = false;
    notifyListeners();
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0088;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}
