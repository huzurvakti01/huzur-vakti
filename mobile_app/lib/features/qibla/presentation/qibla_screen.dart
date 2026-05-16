import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';

import '../../../core/services/qibla_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/constants/app_strings.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  static const screenKey = 'qibla';

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaBearing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBearing();
  }

  Future<void> _loadBearing() async {
    try {
      final bearing = await context.read<QiblaService>().qiblaBearingFromCurrentLocation();
      if (!mounted) return;
      setState(() {
        _qiblaBearing = bearing;
        _error = null;
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logQiblaBearingFailed,
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _error = ErrorPresenter.readableMessage(error));
      ErrorPresenter.showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qibla = _qiblaBearing;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.qiblaTitle),
        actions: [
          IconButton(onPressed: _loadBearing, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          final heading = snapshot.data?.heading;
          final sensorMissing = heading == null;
          final rotation = qibla == null || heading == null
              ? 0.0
              : ((heading - qibla) * (pi / 180) * -1);

          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Text(
                      AppStrings.qiblaCompass,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))
                    else
                      Text(
                        qibla == null
                            ? AppStrings.qiblaLoading
                            : AppStrings.format(AppStrings.qiblaBearing, {'degree': qibla.toStringAsFixed(1)}),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 28),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      turns: rotation / (2 * pi),
                      child: Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.deepEmerald, AppTheme.emerald],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.emerald.withOpacity(.24),
                              blurRadius: 46,
                              offset: const Offset(0, 22),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(.22)),
                              ),
                            ),
                            const Icon(Icons.navigation_rounded, color: AppTheme.gold, size: 106),
                            const Positioned(
                              bottom: 34,
                              child: Text(AppStrings.qiblaKaaba, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      sensorMissing
                          ? AppStrings.qiblaSensorMissing
                          : AppStrings.format(AppStrings.qiblaHeading, {'degree': heading.toStringAsFixed(1)}),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: sensorMissing ? Colors.redAccent : null,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.qiblaHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
