import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation_method.dart';
import '../models/country_profile.dart';

class GlobalSettingsService extends ChangeNotifier {
  static const _calculationMethod = 'global_calculation_method';
  static const _hijriOffset = 'global_hijri_offset';
  static const _countryCode = 'global_country_code';
  static const _languageCountrySetupCompleted = 'language_country_setup_completed_v1';

  CalculationMethod _method = CalculationMethod.diyanet;
  int _offset = 0;
  CountryProfile _country = CountryProfile.fallback();
  bool _setupCompleted = false;

  CalculationMethod get method => _method;
  int get hijriOffset => _offset;
  CountryProfile get country => _country;
  bool get languageCountrySetupCompleted => _setupCompleted;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _country = CountryProfile.byCode(
      prefs.getString(_countryCode) ?? CountryProfile.fallback().code,
    );
    _method = CalculationMethod.byId(
      prefs.getInt(_calculationMethod) ?? _country.method.id,
    );
    _offset = (prefs.getInt(_hijriOffset) ?? 0).clamp(-2, 2);
    _setupCompleted = prefs.getBool(_languageCountrySetupCompleted) ?? false;

    notifyListeners();
  }

  Future<void> setCalculationMethod(CalculationMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calculationMethod, method.id);
    _method = method;
    notifyListeners();
  }

  Future<void> setHijriOffset(int offset) async {
    final safe = offset.clamp(-2, 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hijriOffset, safe);
    _offset = safe;
    notifyListeners();
  }

  Future<void> setCountry(CountryProfile country) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_countryCode, country.code);
    await prefs.setInt(_calculationMethod, country.method.id);

    _country = country;
    _method = country.method;

    notifyListeners();
  }

  Future<void> completeLanguageCountrySetup({
    required CountryProfile country,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_countryCode, country.code);
    await prefs.setInt(_calculationMethod, country.method.id);
    await prefs.setBool(_languageCountrySetupCompleted, true);

    _country = country;
    _method = country.method;
    _setupCompleted = true;

    notifyListeners();
  }

  Future<void> resetLanguageCountrySetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageCountrySetupCompleted, false);
    _setupCompleted = false;
    notifyListeners();
  }

  Future<CalculationMethod> autoSelectCalculationMethod({
    required double latitude,
    required double longitude,
  }) async {
    final country = CountryProfile.byCoordinates(latitude, longitude);
    await setCountry(country);
    return country.method;
  }

  Future<CountryProfile> autoSelectCountry({
    required double latitude,
    required double longitude,
  }) async {
    final country = CountryProfile.byCoordinates(latitude, longitude);
    await setCountry(country);
    return country;
  }
}
