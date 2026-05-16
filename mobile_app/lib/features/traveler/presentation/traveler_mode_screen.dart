import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/traveler_mode_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';
import '../../../core/constants/app_strings.dart';

class TravelerModeScreen extends StatelessWidget {
  const TravelerModeScreen({super.key});

  static const screenKey = 'traveler_settings';

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TravelerModeService>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.travelerTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Column(
              children: [
                Text(
                  AppStrings.format(AppStrings.travelerDistance, {'distance': service.distanceKm?.toStringAsFixed(1) ?? '-'}),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Slider(
                  min: 70,
                  max: 120,
                  divisions: 10,
                  value: service.thresholdKm,
                  label: AppStrings.formatKm(service.thresholdKm.round()),
                  onChanged: service.setThreshold,
                ),
                SwitchListTile(
                  value: service.active,
                  onChanged: service.setActive,
                  title: const Text(AppStrings.travelerSwitchTitle),
                  subtitle: const Text(AppStrings.travelerSwitchSubtitle),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.read<AdService>().trackButtonTap(
                                context: context,
                                currentScreenKey: screenKey,
                              );
                          service.saveCurrentAsHome().then((_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                content: const Text(AppStrings.travelerHomeSaved),
                              ),
                            );
                          }).catchError((Object error, StackTrace stackTrace) {
                            AppLogger.error(
                              AppStrings.logHomeLocationSaveFailed,
                              error: error,
                              stackTrace: stackTrace,
                            );
                            if (context.mounted) ErrorPresenter.showSnackBar(context, error);
                          });
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: const Text(AppStrings.travelerSaveHome),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      onPressed: service.refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SafeBannerAd(screenKey: TravelerModeScreen.screenKey),
        ],
      ),
    );
  }
}
