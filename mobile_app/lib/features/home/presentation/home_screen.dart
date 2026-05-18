import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/services/religious_content_service.dart';
import '../../../core/services/traveler_mode_service.dart';
import '../../../core/state/prayer_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/god_mode_text.dart';
import '../../../widgets/dashboard_native_ad.dart';
import '../../../core/config/app_god_mode_resolver.dart';
import '../../../core/constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const screenKey = 'home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _suggestedTraveler = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showTravelerSuggestionOnce();
  }


  Future<void> _showTravelerSuggestionOnce() async {
    if (_suggestedTraveler) return;

    final traveler = context.read<TravelerModeService>();
    await traveler.refresh();

    if (!mounted || !traveler.shouldSuggest) return;

    _suggestedTraveler = true;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.luggage_rounded, size: 54, color: AppTheme.gold),
            const SizedBox(height: 12),
            Text(
              AppStrings.travelerSuggestionTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.format(
                AppStrings.travelerSuggestionMessage,
                {'distance': traveler.distanceKm?.toStringAsFixed(1) ?? '-'},
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(AppStrings.later),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      traveler.setActive(true);
                      Navigator.pop(context);
                    },
                    child: const Text(AppStrings.open),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerController>();
    final traveler = context.watch<TravelerModeService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            onPressed: prayer.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.nightBlue, AppTheme.night, Color(0xFF102A43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: prayer.load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
            if (traveler.active)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _TravelerBadge(),
              ),
            if (prayer.loading && prayer.times == null)
              const SizedBox(height: 420, child: Center(child: CircularProgressIndicator()))
            else if (prayer.error != null && prayer.times == null)
              GlassCard(
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 42),
                    const SizedBox(height: 12),
                    Text(ErrorPresenter.readableMessage(prayer.error!), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: prayer.load, child: const Text(AppStrings.retry)),
                  ],
                ),
              )
            else ...[
              _HeroPrayerCard(),
              const _InspirationStories(),
              if (traveler.active)
                const GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.gold),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.travelerModeNote,
                        ),
                      ),
                    ],
                  ),
                ),
              _QuickActions(),
              const DashboardNativeAd(),
              _PrayerListCard(),
            ],
          ],
        ),
      ),
    );
  }
}


class _HeroPrayerCard extends StatefulWidget {
  @override
  State<_HeroPrayerCard> createState() => _HeroPrayerCardState();
}

class _HeroPrayerCardState extends State<_HeroPrayerCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerController>();
    final next = prayer.next;
    final times = prayer.times;

    if (next == null || times == null) return const SizedBox.shrink();

    final remaining = next.time.difference(DateTime.now());
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    final ordered = times.ordered;
    final currentIndex = ordered.indexWhere((item) => item.name == next.name);
    final previous = currentIndex <= 0 ? ordered.last : ordered[currentIndex - 1];
    final totalWindow = next.time.difference(previous.time).inSeconds.abs().clamp(1, 86400);
    final progress = 1 - (remaining.inSeconds.clamp(0, totalWindow) / totalWindow);

    return GlassCard(
      opacity: .18,
      blur: 24,
      padding: const EdgeInsets.all(18),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.mysticBlue.withOpacity(.96),
              AppTheme.nightBlue.withOpacity(.96),
              AppTheme.deepEmerald.withOpacity(.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(.12)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withOpacity(.16),
              blurRadius: 44,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        child: Column(
          children: [
            Text(
              AppStrings.homeNextPrayerRemaining,
              style: TextStyle(
                color: Colors.white.withOpacity(.76),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 240,
              height: 240,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _PrayerRingPainter(
                      progress: progress.clamp(0.0, 1.0),
                      pulse: _pulse.value,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mosque_rounded, color: AppTheme.gold, size: 34),
                          const SizedBox(height: 8),
                          Text(
                            next.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.formatDurationClock(hours: h, minutes: m, seconds: s),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerRingPainter extends CustomPainter {
  final double progress;
  final double pulse;

  const _PrayerRingPainter({
    required this.progress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 14;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(.10);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22 + (math.sin(pulse * math.pi * 2) + 1) * 2
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.gold.withOpacity(.08);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [AppTheme.gold, Color(0xFFFFFFFF), AppTheme.emerald, AppTheme.gold],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * progress, false, glow);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * progress, false, fg);

    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.emerald.withOpacity(.10);
    final wavePath = Path();
    final waveTop = center.dy + radius * .55 - progress * radius * 1.1;
    wavePath.moveTo(center.dx - radius, center.dy + radius);
    wavePath.lineTo(center.dx - radius, waveTop);
    for (var x = -radius; x <= radius; x += 6) {
      final y = waveTop + math.sin((x / radius * math.pi * 2) + pulse * math.pi * 2) * 5;
      wavePath.lineTo(center.dx + x, y);
    }
    wavePath.lineTo(center.dx + radius, center.dy + radius);
    wavePath.close();
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 24)));
    canvas.drawPath(wavePath, wavePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PrayerRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}


class _InspirationStories extends StatelessWidget {
  const _InspirationStories();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DashboardReligiousContent>>(
      future: context.read<ReligiousContentService>().fetchDashboardContent(context.locale.languageCode),
      builder: (context, snapshot) {
        final items = snapshot.data ?? ReligiousContentService.fallback;

        return GlassCard(
          opacity: .16,
          blur: 20,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: GodModeText(
                  'dashboardStoriesTitle',
                  AppStrings.dashboardStoriesTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 152,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () => context.push(item.route),
                      child: Container(
                        width: 255,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(.16),
                              AppTheme.gold.withOpacity(index == 1 ? .16 : .08),
                              AppTheme.emerald.withOpacity(index == 2 ? .18 : .08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withOpacity(.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              index == 0
                                  ? Icons.auto_stories_rounded
                                  : index == 1
                                      ? Icons.format_quote_rounded
                                      : Icons.article_rounded,
                              color: AppTheme.gold,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.type,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                Text(
                                  item.source,
                                  style: TextStyle(color: Colors.white.withOpacity(.54), fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                item.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withOpacity(.78), height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppTheme.gold.withOpacity(.8),
                    backgroundColor: Colors.white.withOpacity(.12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  final actions = const [
    (AppStrings.quickAiGuide, Icons.smart_toy_rounded, '/ai', 'ai'),
    (AppStrings.quickKids, Icons.child_care_rounded, '/kids', 'kids_mode'),
    (AppStrings.quickQaza, Icons.emoji_events_rounded, '/gamification', 'gamification'),
    (AppStrings.quickTraveler, Icons.luggage_rounded, '/traveler', 'traveler_settings'),
    (AppStrings.quickTahajjud, Icons.dark_mode_rounded, '/sleep', 'tahajjud_sleep'),
    (AppStrings.quickZakat, Icons.calculate_rounded, '/zakat', 'zakat'),
    (AppStrings.quickPremium, Icons.workspace_premium_rounded, '/premium', 'premium'),
  ];

  @override
  Widget build(BuildContext context) {
    final godMode = context.watch<AppGodModeResolver>();
    return GlassCard(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: .88,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: actions.where((a) => godMode.flags.routeEnabled(a.$3)).map((a) {
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(a.$3),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.emerald.withOpacity(.08),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.$2, color: AppTheme.emerald),
                  const SizedBox(height: 8),
                  Text(
                    a.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrayerListCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final times = context.watch<PrayerController>().times;
    if (times == null) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        children: times.ordered.map((item) {
          final time = AppStrings.formatClock(hour: item.time.hour, minute: item.time.minute);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_rounded),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)),
            trailing: Text(time, style: const TextStyle(fontWeight: FontWeight.w900)),
          );
        }).toList(),
      ),
    );
  }
}

class _TravelerBadge extends StatelessWidget {
  const _TravelerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withOpacity(.50)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.luggage_rounded, color: AppTheme.gold),
          SizedBox(width: 8),
          Text(AppStrings.travelerModeActive, style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
