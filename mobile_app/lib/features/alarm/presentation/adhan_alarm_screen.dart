import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/services/hard_wake_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../shared/widgets/glass_card.dart';

class AdhanAlarmScreen extends StatefulWidget {
  const AdhanAlarmScreen({
    super.key,
    this.prayerName = AppStrings.prayerFajr,
  });

  static const screenKey = 'adhan_alarm';

  final String prayerName;

  @override
  State<AdhanAlarmScreen> createState() => _AdhanAlarmScreenState();
}

class _AdhanAlarmScreenState extends State<AdhanAlarmScreen> {
  late HardWakeMathChallenge challenge;
  final answer = TextEditingController();
  String? message;

  @override
  void initState() {
    super.initState();
    challenge = context.read<HardWakeService>().newMathChallenge();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hardWake = context.read<HardWakeService>();
      final isPremium = context.read<PurchaseService>().isPremium;

      if (isPremium && hardWake.enabled && hardWake.mode == HardWakeChallengeMode.shake) {
        hardWake.startShakeChallenge(onCompleted: _stopAlarm);
      }
    });
  }

  @override
  void dispose() {
    answer.dispose();
    context.read<HardWakeService>().stopShakeChallenge();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    await context.read<AlarmService>().stopAdhan();

    if (!mounted) return;
    setState(() => message = AppStrings.hardWakeCompleted);
    Navigator.of(context).maybePop();
  }

  void _checkMath() {
    final value = int.tryParse(answer.text.trim());

    if (value == challenge.answer) {
      _stopAlarm();
      return;
    }

    setState(() => message = AppStrings.hardWakeWrongAnswer);
  }

  @override
  Widget build(BuildContext context) {
    final hardWake = context.watch<HardWakeService>();
    final isPremium = context.watch<PurchaseService>().isPremium;
    final challengeActive = isPremium && hardWake.enabled;

    return Scaffold(
      backgroundColor: const Color(0xFF08110F),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 40),
            Icon(Icons.mosque_rounded, size: 86, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 18),
            Text(
              widget.prayerName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.adhanRinging,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 28),
            if (challengeActive && hardWake.mode == HardWakeChallengeMode.shake)
              GlassCard(
                child: Column(
                  children: [
                    const Icon(Icons.vibration_rounded, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      AppStrings.hardWakeShakeMode,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: hardWake.shakeCount / HardWakeService.requiredShakeCount,
                      minHeight: 14,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.format(
                        AppStrings.hardWakeShakeProgress,
                        {'count': hardWake.shakeCount},
                      ),
                    ),
                  ],
                ),
              )
            else if (challengeActive && hardWake.mode == HardWakeChallengeMode.math)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.format(
                        AppStrings.hardWakeMathQuestion,
                        {'a': challenge.a, 'b': challenge.b},
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: answer,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _checkMath,
                      child: const Text(AppStrings.ok),
                    ),
                  ],
                ),
              )
            else
              GlassCard(
                child: FilledButton.icon(
                  onPressed: _stopAlarm,
                  icon: const Icon(Icons.stop_circle_rounded),
                  label: const Text(AppStrings.ok),
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
