import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/khutbah_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class KhutbahMoonScreen extends StatefulWidget {
  const KhutbahMoonScreen({super.key});

  static const screenKey = 'khutbah';

  @override
  State<KhutbahMoonScreen> createState() => _KhutbahMoonScreenState();
}

class _KhutbahMoonScreenState extends State<KhutbahMoonScreen> {
  late Future<KhutbahContent> future;
  final moon = MoonPhaseService();

  @override
  void initState() {
    super.initState();
    future = KhutbahService().fetchLatest();
  }

  Future<void> _reload() async {
    setState(() => future = KhutbahService().fetchLatest());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final phase = moon.phaseName(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.khutbahTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.nights_stay_rounded, size: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(AppStrings.moonPhaseTitle, style: TextStyle(fontWeight: FontWeight.w900)),
                        Text(phase),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<KhutbahContent>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const GlassCard(child: Center(child: CircularProgressIndicator()));
                }

                if (snapshot.hasError) {
                  return GlassCard(
                    child: Column(
                      children: [
                        Text(ErrorPresenter.readableMessage(snapshot.error!, fallback: AppStrings.khutbahUnavailable)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _reload, child: const Text(AppStrings.retry)),
                      ],
                    ),
                  );
                }

                final khutbah = snapshot.data!;

                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(khutbah.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Text(khutbah.summary),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => launchUrl(khutbah.source, mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text(AppStrings.openSource),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SafeBannerAd(screenKey: KhutbahMoonScreen.screenKey),
          ],
        ),
      ),
    );
  }
}
