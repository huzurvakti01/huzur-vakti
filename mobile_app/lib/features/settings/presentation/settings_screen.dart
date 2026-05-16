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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.adhanDownloadCompleted),
        ),
      );
    } on AppException catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAdhanDownloadFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'sourceId': source.id},
      );
      if (mounted) ErrorPresenter.showSnackBar(context, error, fallback: AppStrings.adhanDownloadFailed);
    } finally {
      if (mounted) setState(() => _downloading.remove(source.id));
    }
  }

  Future<void> _toggleHardWake(bool value) async {
    final isPremium = context.read<PurchaseService>().isPremium;

    try {
      await context.read<HardWakeService>().setEnabled(
            value: value,
            isPremium: isPremium,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Text(value ? AppStrings.hardWakeEnabled : AppStrings.hardWakeDisabled),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await _showPremiumLockedDialog(AppStrings.hardWakeLocked);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final isPremium = context.read<PurchaseService>().isPremium;

    try {
      await context.read<BiometricLockService>().setEnabled(
            value: value,
            isPremium: isPremium,
          );

      if (!mounted) return;
      setState(() => biometricEnabled = value);
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _showPremiumLockedDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text(AppStrings.premiumTitle),
        content: Text(message),
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
  }

  void _open(BuildContext context, String path, String key) {
    context.read<AdService>().trackNavigation(
          context: context,
          fromScreenKey: SettingsScreen.screenKey,
          toScreenKey: key,
        );
    context.push(path);
  }

  Future<void> _setLanguage(Locale locale) async {
    await context.setLocale(locale);
    if (mounted) setState(() {});
  }

  Future<void> _autoSelectCalculationMethod() async {
    try {
      final pos = await context.read<LocationService>().currentPosition();
      final method = await context.read<GlobalSettingsService>().autoSelectCalculationMethod(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.localizationAutoMethod}: ${method.title}')),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _openConsentForm() async {
    try {
      await context.read<ConsentService>().showPrivacyOptions();
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text(AppStrings.deleteAccountTitle),
        content: const Text(AppStrings.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.later),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.deleteAccountConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<AuthService>().deleteAccount();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteAccountDone)),
      );

      context.go('/auth');
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kids = context.watch<KidsModeService>();
    final premium = context.watch<PurchaseService>();
    final auth = context.watch<AuthService>();
    final globalSettings = context.watch<GlobalSettingsService>();

    final supportedLocales = <Locale>[
      const Locale('tr'),
      const Locale('en'),
      const Locale('ar'),
      const Locale('fr'),
      const Locale('ur'),
      const Locale('id'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: SwitchListTile(
              value: kids.enabled,
              onChanged: kids.setEnabled,
              title: const Text(AppStrings.kidsMode),
              subtitle: const Text(AppStrings.kidsModeSubtitle),
              secondary: const Icon(Icons.child_care_rounded),
            ),
          ),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.public_rounded),
              title: const Text(AppStrings.openLanguageCountrySetup, style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                '${globalSettings.country.flag} ${globalSettings.country.label(context.locale.languageCode)} • ${globalSettings.method.title}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/smart-setup?edit=1'),
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.localizationLanguage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: supportedLocales.map((locale) {
                    final selected = context.locale.languageCode == locale.languageCode;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(locale.languageCode.toUpperCase()),
                      onSelected: (_) => _setLanguage(locale),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.localizationCalculationMethod,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ...CalculationMethod.all.map(
                  (method) => RadioListTile<int>(
                    value: method.id,
                    groupValue: globalSettings.method.id,
                    onChanged: (_) async {
                      await context.read<GlobalSettingsService>().setCalculationMethod(method);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(AppStrings.globalMethodSaved)),
                        );
                      }
                    },
                    title: Text(method.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(method.subtitle),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _autoSelectCalculationMethod,
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text(AppStrings.localizationAutoMethod),
                ),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.localizationHijriOffset,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: -2, label: Text('-2')),
                    ButtonSegment(value: -1, label: Text('-1')),
                    ButtonSegment(value: 0, label: Text('0')),
                    ButtonSegment(value: 1, label: Text('+1')),
                    ButtonSegment(value: 2, label: Text('+2')),
                  ],
                  selected: {globalSettings.hijriOffset},
                  onSelectionChanged: (values) async {
                    await context.read<GlobalSettingsService>().setHijriOffset(values.first);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.hijriOffsetSaved)),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_rounded),
              title: const Text(AppStrings.localizationConsent, style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text(AppStrings.consentFormUnavailable),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openConsentForm,
            ),
          ),
          GlassCard(
            child: ListTile(
              leading: Icon(auth.isSignedIn ? Icons.verified_user_rounded : Icons.person_outline_rounded),
              title: Text(
                auth.isSignedIn && auth.user?.email != null
                    ? AppStrings.format(AppStrings.signedInAs, {'email': auth.user!.email!})
                    : AppStrings.guestSyncWarning,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(auth.isSignedIn ? AppStrings.cloudSyncFreeActive : AppStrings.cloudSyncNeedsLogin),
              trailing: auth.isSignedIn || auth.isGuest
                  ? TextButton(
                      onPressed: () async {
                        await context.read<AuthService>().signOut();
                        if (context.mounted) context.go('/auth');
                      },
                      child: const Text(AppStrings.signOut),
                    )
                  : null,
              onTap: auth.isSignedIn ? null : () => context.go('/auth'),
            ),
          ),
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: context.watch<HardWakeService>().enabled,
                  onChanged: _toggleHardWake,
                  title: const Text(AppStrings.hardWakeTitle),
                  subtitle: const Text(AppStrings.hardWakeSubtitle),
                  secondary: const Icon(Icons.alarm_rounded),
                ),
                SegmentedButton<HardWakeChallengeMode>(
                  segments: const [
                    ButtonSegment(
                      value: HardWakeChallengeMode.shake,
                      label: Text(AppStrings.hardWakeShakeMode),
                      icon: Icon(Icons.vibration_rounded),
                    ),
                    ButtonSegment(
                      value: HardWakeChallengeMode.math,
                      label: Text(AppStrings.hardWakeMathMode),
                      icon: Icon(Icons.calculate_rounded),
                    ),
                  ],
                  selected: {context.watch<HardWakeService>().mode},
                  onSelectionChanged: (values) => context.read<HardWakeService>().setMode(values.first),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: biometricEnabled,
                  onChanged: _toggleBiometric,
                  title: const Text(AppStrings.biometricTitle),
                  subtitle: const Text(AppStrings.biometricSubtitle),
                  secondary: const Icon(Icons.fingerprint_rounded),
                ),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.adhanAudioSelection,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ...AdhanAudioService.sources.map(
                  (s) => FutureBuilder<bool>(
                    future: context.read<AdhanAudioService>().isDownloaded(s),
                    builder: (context, snapshot) {
                      final downloaded = snapshot.data ?? false;
                      final downloading = _downloading.contains(s.id);

                      return RadioListTile<String>(
                        value: s.id,
                        groupValue: selectedAdhanId,
                        onChanged: (_) => _selectAudio(s),
                        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(downloaded ? AppStrings.adhanUseDownloaded : s.subtitle),
                        secondary: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow_rounded),
                              onPressed: () => _previewAudio(s),
                            ),
                            if (s.url.isNotEmpty)
                              IconButton(
                                tooltip: AppStrings.adhanDownload,
                                icon: downloading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(downloaded ? Icons.download_done_rounded : Icons.download_rounded),
                                onPressed: downloading ? null : () => _downloadAudio(s),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              children: [
                _SettingsTile(title: AppStrings.quickAiGuide, icon: Icons.smart_toy_rounded, onTap: () => _open(context, '/ai', 'ai')),
                _SettingsTile(title: AppStrings.quickQaza, icon: Icons.emoji_events_rounded, onTap: () => _open(context, '/gamification', 'gamification')),
                _SettingsTile(title: AppStrings.travelerTitle, icon: Icons.luggage_rounded, onTap: () => _open(context, '/traveler', 'traveler_settings')),
                _SettingsTile(title: AppStrings.tahajjudTitle, icon: Icons.dark_mode_rounded, onTap: () => _open(context, '/sleep', 'tahajjud_sleep')),
                _SettingsTile(title: AppStrings.zakatTitle, icon: Icons.calculate_rounded, onTap: () => _open(context, '/zakat', 'zakat')),
                _SettingsTile(title: AppStrings.profileBackupTitle, icon: Icons.cloud_sync_rounded, onTap: () => _open(context, '/profile-backup', 'profile_backup')),
                _SettingsTile(title: AppStrings.appIconTitle, icon: Icons.app_settings_alt_rounded, onTap: () => _open(context, '/app-icon', 'app_icon')),
                _SettingsTile(title: AppStrings.secureNotesTitle, icon: Icons.lock_rounded, onTap: () => _open(context, '/secure-notes', 'secure_notes')),
                _SettingsTile(title: AppStrings.premiumLibraryTitle, icon: Icons.headphones_rounded, onTap: () => _open(context, '/premium-library', 'premium_audio_library')),
                _SettingsTile(title: AppStrings.premiumTitle, icon: Icons.workspace_premium_rounded, onTap: () => _open(context, '/premium', 'premium')),
              ],
            ),
          ),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              title: const Text(AppStrings.deleteAccount, style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text(AppStrings.deleteAccountBody),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _deleteAccount,
            ),
          ),
          GlassCard(
            child: Text(premium.isPremium ? AppStrings.premiumActiveNoAds : AppStrings.freeAdsPolicy),
          ),
          const SafeBannerAd(screenKey: SettingsScreen.screenKey),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
