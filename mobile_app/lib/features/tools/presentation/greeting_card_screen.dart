import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/gallery_service.dart';
import '../../../core/services/greeting_card_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class GreetingCardScreen extends StatefulWidget {
  final String? initialImageUrl;

  const GreetingCardScreen({super.key, this.initialImageUrl});

  static const screenKey = 'greeting_card';

  @override
  State<GreetingCardScreen> createState() => _GreetingCardScreenState();
}

class _GreetingCardScreenState extends State<GreetingCardScreen> {
  final message = TextEditingController(text: 'Hayırlı Cumalar');
  int backgroundIndex = 0;
  File? generated;
  bool loading = false;
  late Future<List<GalleryImage>> galleryFuture;

  @override
  void initState() {
    super.initState();
    galleryFuture = context.read<GalleryService>().fetchIslamicWallpapers();
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => loading = true);

    try {
      final file = await context.read<GreetingCardService>().createCard(
            message: message.text,
              backgroundIndex: backgroundIndex,
            backgroundUrl: widget.initialImageUrl,
          );

      if (!mounted) return;
      setState(() => generated = file);
      context.read<AdService>().trackButtonTap(context: context, currentScreenKey: GreetingCardScreen.screenKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.cardCreated)));
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _share() async {
    if (generated == null) return;

    await Share.shareXFiles(
      [XFile(generated!.path)],
      text: AppStrings.appName,
    );

    if (mounted) {
      context.read<AdService>().trackButtonTap(context: context, currentScreenKey: GreetingCardScreen.screenKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previews = [AppTheme.emerald, AppTheme.gold, AppTheme.deepEmerald];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.greetingCardTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: message,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: AppStrings.cardMessageHint,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (widget.initialImageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(widget.initialImageUrl!, height: 148, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                FutureBuilder<List<GalleryImage>>(
                  future: galleryFuture,
                  builder: (context, snapshot) {
                    final images = snapshot.data ?? const <GalleryImage>[];
                    return SizedBox(
                      height: images.isEmpty ? 0 : 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.take(6).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final image = images[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(image.imageUrl, width: 72, height: 92, fit: BoxFit.cover),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: List.generate(previews.length, (index) {
                    return ChoiceChip(
                      selected: backgroundIndex == index,
                      onSelected: (_) => setState(() => backgroundIndex = index),
                      label: Text('${index + 1}'),
                      avatar: CircleAvatar(backgroundColor: previews[index]),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: loading ? null : _create,
                  icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image_rounded),
                  label: const Text(AppStrings.createCard),
                ),
              ],
            ),
          ),
          if (generated != null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.file(generated!, height: 360, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text(AppStrings.shareCard),
                  ),
                ],
              ),
            ),
          const SafeBannerAd(screenKey: GreetingCardScreen.screenKey),
        ],
      ),
    );
  }
}
