import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class AyahFinderScreen extends StatefulWidget {
  const AyahFinderScreen({super.key});

  static const screenKey = 'ayah_finder';

  @override
  State<AyahFinderScreen> createState() => _AyahFinderScreenState();
}

class _AyahFinderScreenState extends State<AyahFinderScreen> with SingleTickerProviderStateMixin {
  late final AnimationController radar;
  bool listening = false;
  String? status;

  @override
  void initState() {
    super.initState();
    radar = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    radar.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final permission = await Permission.microphone.request();

    if (!permission.isGranted) {
      if (mounted) {
        ErrorPresenter.showSnackBar(
          context,
          const Exception(AppStrings.microphonePermissionNeeded),
        );
      }
      return;
    }

    setState(() {
      listening = true;
      status = AppStrings.ayahRadarListening;
    });
  }

  Future<void> _stop() async {
    setState(() {
      listening = false;
      status = AppStrings.ayahUploadDraft;
    });

    context.read<AdService>().trackButtonTap(
          context: context,
          currentScreenKey: AyahFinderScreen.screenKey,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ayahFinderTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Column(
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: AnimatedBuilder(
                    animation: radar,
                    builder: (context, child) {
                      final scale = 0.65 + (radar.value * 0.55);
                      final opacity = (1 - radar.value).clamp(0.0, 1.0);

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.gold.withOpacity(.65),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.emerald.withOpacity(.14),
                              border: Border.all(color: AppTheme.gold.withOpacity(.35)),
                            ),
                            child: Icon(
                              listening ? Icons.hearing_rounded : Icons.mic_rounded,
                              color: AppTheme.gold,
                              size: 54,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  status ?? AppStrings.ayahFinderSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: listening ? _stop : _start,
                  icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
                  label: Text(listening ? AppStrings.stopListening : AppStrings.startListening),
                ),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.ayahFinderSubtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SafeBannerAd(screenKey: AyahFinderScreen.screenKey),
        ],
      ),
    );
  }
}
