import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/global_settings_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dynamic_splash_image.dart';
import '../../../shared/widgets/god_mode_text.dart';
import '../../../shared/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const screenKey = 'onboarding';
  static const completedKey = 'onboarding_completed_v1';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

  static Future<bool> completed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKey, true);
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool loading = false;

  Future<void> _start() async {
    setState(() => loading = true);

    await Permission.locationWhenInUse.request();
    await Permission.notification.request();

    try {
      final pos = await context.read<LocationService>().currentPosition();
      await context.read<GlobalSettingsService>().autoSelectCalculationMethod(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
    } catch (_) {}

    if (Theme.of(context).platform == TargetPlatform.android) {
      await Permission.locationAlways.request();
    }

    await OnboardingScreen.markCompleted();

    if (!mounted) return;
    setState(() => loading = false);
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _OnboardingItem(
        icon: Icons.location_on_rounded,
        title: AppStrings.onboardingLocationTitle,
        body: AppStrings.onboardingLocationBody,
      ),
      _OnboardingItem(
        icon: Icons.notifications_active_rounded,
        title: AppStrings.onboardingNotificationTitle,
        body: AppStrings.onboardingNotificationBody,
      ),
      _OnboardingItem(
        icon: Icons.verified_user_rounded,
        title: 'Gizlilik',
        body: AppStrings.onboardingPrivacyBody,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.deepEmerald, Color(0xFF0E7C66), Color(0xFFF4E7C5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const SizedBox(height: 36),
              const DynamicSplashImage(width: 132),
              const SizedBox(height: 18),
              GodModeText(
                'onboardingTitle',
                AppStrings.onboardingTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 20),
              ...cards,
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: loading ? null : _start,
                icon: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded),
                label: const Text(AppStrings.startSetup),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        await OnboardingScreen.markCompleted();
                        if (context.mounted) context.go('/auth');
                      },
                child: const Text(AppStrings.continueToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 34, color: AppTheme.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                Text(body, style: const TextStyle(color: Colors.white70, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
