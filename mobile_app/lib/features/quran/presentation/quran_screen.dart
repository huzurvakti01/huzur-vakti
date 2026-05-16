// zorunlu degisiklik testi
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/models/quran_models.dart';
import '../../../core/services/quran_api_service.dart';
import '../../../core/services/quran_audio_service.dart';
import '../../../shared/widgets/glass_card.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  static const screenKey = 'quran';

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
bool _audioPlaying = false;
  late Future<List<QuranSurah>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<QuranApiService>().fetchSurahs();
  }

  Future<void> _reload() async {
    setState(() {
      _future = context.read<QuranApiService>().fetchSurahs();
    });
    await _future;
  }

  void _openSurah(QuranSurah surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(surah: surah),
      ),
    );
  }


  Future<void> _toggleAudio(List<String> urls) async {
    if (_audioPlaying) {
      await context.read<QuranAudioService>().stop();
      if (mounted) setState(() => _audioPlaying = false);
      return;
    }

    final first = urls.where((url) => url.isNotEmpty).isEmpty ? '' : urls.firstWhere((url) => url.isNotEmpty);
    await context.read<QuranAudioService>().playUrl(first);
    if (mounted) setState(() => _audioPlaying = true);
  }

  @override
  void dispose() {
    context.read<QuranAudioService>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.quranTitle),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<QuranSurah>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return  ListView(
                children: [
                  SizedBox(height: 360, child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            if (snapshot.hasError) {
              final message = ErrorPresenter.readableMessage(snapshot.error!);
              return ListView(
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 42),
                        const SizedBox(height: 12),
                        Text(message, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final surahs = snapshot.data ?? const <QuranSurah>[];

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 28),
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surah = surahs[index];
                return GlassCard(
                  onTap: () => _openSurah(surah),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(AppStrings.formatIndex(surah.number))),
                    title: Text(
                      surah.englishName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(AppStrings.format(AppStrings.verses, {'count': surah.ayahCount})),
                    trailing: Text(
                      surah.name,
                      style: const TextStyle(fontSize: 24),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class QuranReaderScreen extends StatefulWidget {
  final QuranSurah surah;

  const QuranReaderScreen({
    super.key,
    required this.surah,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late Future<QuranSurahDetail> _future;
  late Future<List<String>> _translationFuture;
  late Future<List<String>> _audioFuture;
  bool _audioPlaying = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<QuranApiService>().fetchSurahDetail(widget.surah);
    _translationFuture = context.read<QuranApiService>().fetchSurahTranslationForLocale(widget.surah.number, context.locale.languageCode);
    _audioFuture = context.read<QuranApiService>().fetchSurahAudioAlafasy(widget.surah.number);
  }

  Future<void> _reload() async {
    setState(() {
      _future = context.read<QuranApiService>().fetchSurahDetail(widget.surah);
      _translationFuture = context.read<QuranApiService>().fetchSurahTranslationForLocale(widget.surah.number, context.locale.languageCode);
      _audioFuture = context.read<QuranApiService>().fetchSurahAudioAlafasy(widget.surah.number);
    });
    await _future;
  }


  Future<void> _toggleAudio(List<String> urls) async {
    if (_audioPlaying) {
      await context.read<QuranAudioService>().stop();
      if (mounted) setState(() => _audioPlaying = false);
      return;
    }

    final first = urls.where((url) => url.isNotEmpty).isEmpty ? '' : urls.firstWhere((url) => url.isNotEmpty);
    await context.read<QuranAudioService>().playUrl(first);
    if (mounted) setState(() => _audioPlaying = true);
  }

  @override
  void dispose() {
    context.read<QuranAudioService>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.englishName),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<QuranSurahDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return  ListView(
                children: [
                  SizedBox(height: 360, child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            if (snapshot.hasError) {
              AppLogger.error(
                AppStrings.logQuranDetailFailed,
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
                context: {'surah': widget.surah.number},
              );

              return ListView(
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 42),
                        const SizedBox(height: 12),
                        Text(ErrorPresenter.readableMessage(snapshot.error!), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final detail = snapshot.data!;

            return FutureBuilder<List<String>>(
              future: _translationFuture,
              builder: (context, translationSnapshot) {
                final translations = translationSnapshot.data ?? const <String>[];

                return FutureBuilder<List<String>>(
                  future: _audioFuture,
                  builder: (context, audioSnapshot) {
                    final audioUrls = audioSnapshot.data ?? const <String>[];

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 28),
                      itemCount: detail.ayahs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return GlassCard(
                            child: FilledButton.icon(
                              onPressed: audioUrls.isEmpty ? null : () => _toggleAudio(audioUrls),
                              icon: Icon(_audioPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                              label: Text(_audioPlaying ? AppStrings.quranAudioStop : AppStrings.quranAudioPlay),
                            ),
                          );
                        }

                        final ayah = detail.ayahs[index - 1];
                        final meal = index - 1 < translations.length ? translations[index - 1] : '';
                        final tafsir = meal.isEmpty ? '' : '${AppStrings.quranTafsir}: $meal';

                        return GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                ayah.text,
                                style: const TextStyle(fontSize: 30, height: 1.9),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${AppStrings.quranTranslation}: $meal',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              if (tafsir.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(tafsir),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                AppStrings.formatIndex(ayah.numberInSurah),
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
