import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/women_calendar_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class WomenCalendarScreen extends StatefulWidget {
  const WomenCalendarScreen({super.key});

  static const screenKey = 'women_calendar';

  @override
  State<WomenCalendarScreen> createState() => _WomenCalendarScreenState();
}

class _WomenCalendarScreenState extends State<WomenCalendarScreen> {
  late WomenCalendarState state;
  final cycle = TextEditingController();
  final period = TextEditingController();
  DateTime selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    state = context.read<WomenCalendarService>().load();
    selected = state.startDate;
    cycle.text = '${state.cycleLength}';
    period.text = '${state.periodLength}';
  }

  @override
  void dispose() {
    cycle.dispose();
    period.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) setState(() => selected = date);
  }

  Future<void> _save() async {
    final next = await context.read<WomenCalendarService>().save(
          startDate: selected,
          cycleLength: int.tryParse(cycle.text) ?? 28,
          periodLength: int.tryParse(period.text) ?? 6,
        );

    if (!mounted) return;
    setState(() => state = next);
    context.read<AdService>().trackButtonTap(
          context: context,
          currentScreenKey: WomenCalendarScreen.screenKey,
        );
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.womenCalendarTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.worshipPaused, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text(AppStrings.cycleStartDate),
                  subtitle: Text(format.format(selected)),
                  onTap: _pickDate,
                ),
                TextField(
                  controller: cycle,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: AppStrings.cycleLength),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: period,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: AppStrings.periodLength),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text(AppStrings.saveCycle)),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              children: [
                Icon(
                  state.worshipPausedToday ? Icons.pause_circle_rounded : Icons.check_circle_rounded,
                  size: 46,
                ),
                const SizedBox(height: 12),
                Text(
                  state.worshipPausedToday ? AppStrings.worshipPaused : AppStrings.dndDisabled,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.format(AppStrings.nextCycleEstimate, {'date': format.format(state.nextStartDate)}),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SafeBannerAd(screenKey: WomenCalendarScreen.screenKey),
        ],
      ),
    );
  }
}
