import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KidsModeService extends ChangeNotifier {
  static const _key = 'kids_mode_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    _enabled = value;
    notifyListeners();
  }
}
