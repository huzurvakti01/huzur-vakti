import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/kids_mode_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_strings.dart';

class KidsModeScreen extends StatefulWidget {
  const KidsModeScreen({super.key});

  static const screenKey = 'kids_mode';

  @override
  State<KidsModeScreen> createState() => _KidsModeScreenState();
}

class _KidsModeScreenState extends State<KidsModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final lessons = const [
    _Lesson(AppStrings.kidsWudu, AppStrings.kidsWuduSubtitle, Icons.water_drop_rounded, KidsTheme.sky),
    _Lesson(AppStrings.kidsShortSurahs, AppStrings.kidsShortSurahsSubtitle, Icons.menu_book_rounded, KidsTheme.orange),
    _Lesson(AppStrings.kidsManners, AppStrings.kidsMannersSubtitle, Icons.favorite_rounded, KidsTheme.mint),
    _Lesson(AppStrings.kidsPrayer, AppStrings.kidsPrayerSubtitle, Icons.mosque_rounded, KidsTheme.sun),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(_Lesson lesson) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _LessonScreen(lesson: lesson)));
  }

  @override
  Widget build(BuildContext context) {
    final kids = context.watch<KidsModeService>();

    return Theme(
      data: KidsTheme.light(),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(painter: _KidsBg(progress: _controller.value)),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded)),
                      Expanded(
                        child: Text(
                          AppStrings.kidsTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Switch(value: kids.enabled, onChanged: kids.setEnabled),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [KidsTheme.sky, KidsTheme.orange]),
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.child_care_rounded, color: Colors.white, size: 62),
                        SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            AppStrings.kidsHero,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: .88,
                    children: lessons.map((lesson) => _LessonCard(lesson: lesson, onTap: () => _open(lesson))).toList(),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: KidsTheme.sun.withOpacity(.25),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: KidsTheme.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.kidsCoppaNotice,
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final _Lesson lesson;
  final VoidCallback onTap;

  const _LessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.88),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: lesson.color.withOpacity(.18), borderRadius: BorderRadius.circular(24)),
              child: Icon(lesson.icon, color: lesson.color, size: 36),
            ),
            const Spacer(),
            Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, height: 1.05)),
            const SizedBox(height: 8),
            Text(lesson.subtitle, style: TextStyle(color: Colors.black.withOpacity(.58))),
          ]),
        ),
      ),
    );
  }
}

class _LessonScreen extends StatelessWidget {
  final _Lesson lesson;

  const _LessonScreen({required this.lesson});

  List<String> get steps {
    if (lesson.title == AppStrings.kidsWudu) {
      return AppStrings.wuduSteps;
    }
    if (lesson.title == AppStrings.kidsShortSurahs) {
      return AppStrings.shortSurahSteps;
    }
    if (lesson.title == AppStrings.kidsManners) {
      return AppStrings.mannersSteps;
    }
    return AppStrings.prayerSteps;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: KidsTheme.light(),
      child: Scaffold(
        appBar: AppBar(title: Text(lesson.title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(lesson.icon, size: 82, color: lesson.color),
            const SizedBox(height: 18),
            ...steps.asMap().entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: lesson.color, foregroundColor: Colors.white, child: Text(AppStrings.formatIndex(entry.key + 1))),
                    const SizedBox(width: 14),
                    Expanded(child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w800))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _KidsBg extends CustomPainter {
  final double progress;

  _KidsBg({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [KidsTheme.cream, Color(0xFFE9F8FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final paint = Paint();
    final circles = [
      (KidsTheme.sun, Offset(size.width * .18, size.height * .14), 68.0),
      (KidsTheme.sky, Offset(size.width * .86, size.height * .22), 76.0),
      (KidsTheme.orange, Offset(size.width * .76, size.height * .78), 90.0),
      (KidsTheme.mint, Offset(size.width * .12, size.height * .82), 76.0),
    ];

    for (var i = 0; i < circles.length; i++) {
      final c = circles[i];
      paint.color = c.$1.withOpacity(.16);
      canvas.drawCircle(c.$2.translate(0, sin(progress * 2 * pi + i) * 10), c.$3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KidsBg oldDelegate) => oldDelegate.progress != progress;
}

class _Lesson {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _Lesson(this.title, this.subtitle, this.icon, this.color);
}
