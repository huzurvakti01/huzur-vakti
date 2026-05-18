import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/models/calculation_method.dart';
import '../../../core/services/global_settings_service.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/audio/adhan_audio_service.dart';
import '../../../core/services/biometric_lock_service.dart';
import '../../../core/services/hard_wake_service.dart';
import '../../../core/services/kids_mode_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';
import '../../../core/constants/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const screenKey = 'settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedAdhanId;
  final Set<String> _downloading = {};
  bool biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    context.read<AdhanAudioService>().selectedSource().then((value) {
      if (mounted) setState(() => selectedAdhanId = value.id);
    });
    context.read<BiometricLockService>().isEnabled().then((value) {
      if (mounted) setState(() => biometricEnabled = value);
    });
  }

  Future<void> _selectAudio(source) async {
    try {
      await context.read<AdhanAudioService>().select(source);
      if (!mounted) return;

      setState(() => selectedAdhanId = source.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Text(AppStrings.format(AppStrings.adhanSelected, {'title': source.title})),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAdhanSelectionFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'sourceId': source.id},
      );

      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _previewAudio(source) async {
    try {
      await context.read<AdhanAudioService>().preview(source);
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAdhanPreviewFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'sourceId': source.id},
      );

      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _downloadAudio(source) async {
    final isPremium = context.read<PurchaseService>().isPremium;

    if (!isPremium) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: const Text(AppStrings.premiumTitle),
          content: const Text(AppStrings.premiumAdhanDownloadLocked),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.later),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/premium');
              },
              child: const Text(AppStrings.upgradeToPremium),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _downloading.add(source.id));

    try {
      await context.read<AdhanAudioService>().downloadForPremium(
            source: source,
            isPremium: true,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: Rounded