import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/prayer_dnd_service.dart';
import '../../../shared/widgets/dnd_permission_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class PrayerDndScreen extends StatefulWidget {
  const PrayerDndScreen({super.key});

  static const screenKey = 'prayer_dnd';

  @override
  State<PrayerDndScreen> createState() => _PrayerDndScreenState();
}

class _PrayerDndScreenState extends State<PrayerDndScreen> {
  bool enabled = false;

  @override
  void initState() {
    super.initState();
    context.read<PrayerDndService>().isEnabled().then((value) {
      if (mounted) setState(() => enabled = value);
    });
  }

  Future<void> _set(bool value) async {
    try {
      await context.read<PrayerDndService>().setEnabled(value);
      if (!mounted) return;
      setState(() => enabled = value);
      context.read<AdService>().trackButtonTap(context: context, currentScreenKey: PrayerDndScreen.screenKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? AppStrings.dndEnabled : AppStrings.dndDisabled)),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _test() async {
    try {
      await context.read<PrayerDndService>().activateForPrayerWindow();
      if (!mounted) return;
      context.read<AdService>().trackButtonTap(context: context, currentScreenKey: PrayerDndScreen.screenKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.dndEnabled)));
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.prayerDndTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const DndPermissionCard(),
          GlassCard(
            child: SwitchListTile(
              value: enabled,
              onChanged: _set,
              title: const Text(AppStrings.prayerDndTitle),
              subtitle: const Text(AppStrings.prayerDndSubtitle),
              secondary: const Icon(Icons.do_not_disturb_on_rounded),
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(AppStrings.dndPermissionNeeded),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _test,
                  icon: const Icon(Icons.notifications_paused_rounded),
                  label: const Text(AppStrings.dndActivateNow),
                ),
              ],
            ),
          ),
          const SafeBannerAd(screenKey: PrayerDndScreen.screenKey),
        ],
      ),
    );
  }
}
