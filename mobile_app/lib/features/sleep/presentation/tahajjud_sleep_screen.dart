import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_api_service.dart';
import '../../../core/services/tahajjud_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/constants/app_strings.dart';

class TahajjudSleepScreen extends StatefulWidget {
  const TahajjudSleepScreen({super.key});

  static const screenKey = 'tahajjud_sleep';

  @override
  State<TahajjudSleepScreen> createState() => _TahajjudSleepScreenState();
}

class _TahajjudSleepScreenState extends State<TahajjudSleepScreen> {
  TahajjudPlan? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loc = await context.read<LocationService>().currentPosition();
      final api = context.read<PrayerApiService>();
      final today = await api.fetchPrayerTimes(latitude: loc.latitude, longitude: loc.longitude, date: DateTime.now());
      final tomorrow = await api.fetchPrayerTimes(latitude: loc.latitude, longitude: loc.longitude, date: DateTime.now().add(const Duration(days: 1)));
      _plan = context.read<TahajjudService>().build(today: today, tomorrow: tomorrow);
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logTahajjudLoadFailed,
        error: error,
        stackTrace: stackTrace,
      );
      _error = ErrorPresenter.readableMessage(
        error,
        fallback: AppStrings.tahajjudFailed,
      );
      if (mounted) {
        ErrorPresenter.showSnackBar(context, error, fallback: _error);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('HH:mm', 'tr_TR');

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFF050A18),
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFFE2B659)),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.tahajjudTitle), foregroundColor: Colors.white),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      GlassCard(
                        child: Column(
                          children: [
                            const Icon(Icons.nightlight_round, size: 82, color: Color(0xFFE2B659)),
                            const SizedBox(height: 16),
                            Text(
                              f.format(_plan!.lastThirdStart),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: const Color(0xFFE2B659),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(AppStrings.tahajjudLastThird, style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(child: _Mini(label: AppStrings.tahajjudSleep, time: f.format(_plan!.sleepSuggestion))),
                          Expanded(child: _Mini(label: AppStrings.tahajjudWake, time: f.format(_plan!.wakeSuggestion))),
                        ],
                      ),
                      const GlassCard(
                        child: Text(
                          AppStrings.tahajjudNoAds,
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String time;

  const _Mini({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
        ],
      ),
    );
  }
}
