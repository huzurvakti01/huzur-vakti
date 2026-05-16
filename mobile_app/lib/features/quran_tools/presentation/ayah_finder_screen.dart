import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/ayah_finder_service.dart';
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
  final recorder = AudioRecorder();
  late AnimationController radar;
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
    recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final permission = await Permission.microphone.request();

    if (!permission.isGranted) {
      if (mounted) ErrorPresenter.showSnackBar(context, const Exception(AppStrings.microphonePermissionNeeded));
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/ayah_finder_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      listening = true;
      status = AppStrings.ayahRadarListening;
    });
  }

  Future<void> _stop() async {
    final path = await recorder.stop();
    setState(() => listening = false);

    if (path == null) return;

    try {
      await context.read<AyahFinderService>().uploadAudio(File(path));

      if (!mounted) return;
      setState(() => status = AppStrings.ayahUploadDraft);
      context.read<AdService>().trackButtonTap(context: context, currentScreenKey: AyahFinderScreen.screenKey);
    } catch (error) {
      if (mounted) {
        setState(() => status = ErrorPresenter.readableMessage(error, fallback: AppStrings.ayahUploadDraft));
      }
    }
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
                      return CustomPaint(
                        painter: _RadarPainter(progress: radar.value, listening: listening),
                        child: const Center(
                          child: Icon(Icons.mic_rounded, size: 64, color: AppTheme.gold),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  status ?? AppStrings.ayahFinderSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: listening ? _stop : _start,
                  icon: Icon(listening ? Icons.stop_rounded : Icons.hearing_rounded),
                  label: Text(listening ? AppStrings.stopListening : AppStrings.startListening),
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

class _RadarPainter extends CustomPainter {
  final double progress;
  final bool listening;

  const _RadarPainter({
    required this.progress,
    required this.listening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = (listening ? AppTheme.emerald : AppTheme.gold).withOpacity(.32);

    for (var i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1;
      canvas.drawCircle(center, 38 + p * 76, paint..color = paint.color.withOpacity(1 - p));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.listening != listening;
  }
}
