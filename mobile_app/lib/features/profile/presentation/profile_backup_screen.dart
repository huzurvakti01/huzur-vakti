import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class ProfileBackupScreen extends StatelessWidget {
  const ProfileBackupScreen({super.key});

  static const screenKey = AppStrings.profileBackupAdScreen;

  Future<void> _afterCompleted(BuildContext context) async {
    final isPremium = context.read<PurchaseService>().isPremium;
    if (isPremium || !context.mounted) return;

    context.read<AdService>().trackCompletedAction(
          context: context,
          screenKey: screenKey,
        );
  }

  Future<void> _backupNow(BuildContext context) async {
    try {
      await context.read<GamificationService>().backupNow();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.profileBackupCompleted),
        ),
      );

      await _afterCompleted(context);
    } catch (error) {
      if (context.mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      await context.read<AuthService>().signInWithGoogle();
      await context.read<GamificationService>().restoreFromCloudIfNewer();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.profileBackupLoginCompleted),
        ),
      );

      await _afterCompleted(context);
    } catch (error) {
      if (context.mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _loginWithApple(BuildContext context) async {
    try {
      await context.read<AuthService>().signInWithApple();
      await context.read<GamificationService>().restoreFromCloudIfNewer();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.profileBackupLoginCompleted),
        ),
      );

      await _afterCompleted(context);
    } catch (error) {
      if (context.mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final gamification = context.watch<GamificationService>();
    final premium = context.watch<PurchaseService>();
    final signedIn = auth.isSignedIn;
    final guest = auth.isGuest;

    final message = signedIn
        ? AppStrings.profileBackupSignedIn
        : guest
            ? AppStrings.profileBackupGuest
            : AppStrings.profileBackupSignedOut;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileBackupTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Row(
              children: [
                Icon(
                  signedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: signedIn ? AppTheme.emerald : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (signedIn && auth.user?.email != null)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                AppStrings.format(AppStrings.signedInAs, {'email': auth.user!.email!}),
              ),
            ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.profileBackupSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                if (gamification.cloudSyncing)
                  const Center(child: CircularProgressIndicator())
                else if (signedIn)
                  FilledButton.icon(
                    onPressed: () => _backupNow(context),
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text(AppStrings.profileBackupNow),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: () => _loginWithGoogle(context),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                    label: const Text(AppStrings.signInWithGoogle),
                  ),
                  if (Platform.isIOS || Platform.isMacOS) ...[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _loginWithApple(context),
                      icon: const Icon(Icons.apple_rounded),
                      label: const Text(AppStrings.signInWithApple),
                    ),
                  ],
                ],
                if (signedIn && gamification.lastCloudSyncAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.format(
                      AppStrings.cloudSyncLast,
                      {'time': gamification.lastCloudSyncAt!.toLocal().toString().split('.').first},
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (premium.isPremium) ...[
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.premiumActiveNoAds,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          if (!signedIn)
            const GlassCard(
              child: Text(AppStrings.guestSyncWarning),
            ),
          const SafeBannerAd(screenKey: screenKey),
        ],
      ),
    );
  }
}
