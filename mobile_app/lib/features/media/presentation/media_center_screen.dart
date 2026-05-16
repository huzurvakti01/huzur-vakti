import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/media_center_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../shared/widgets/glass_card.dart';

class MediaCenterScreen extends StatefulWidget {
  const MediaCenterScreen({super.key});

  static const screenKey = 'media_center';

  @override
  State<MediaCenterScreen> createState() => _MediaCenterScreenState();
}

class _MediaCenterScreenState extends State<MediaCenterScreen> {
  YoutubePlayerController? controller;
  String? activeId;
  bool backgroundRadio = false;

  @override
  void dispose() {
    controller?.dispose();
    context.read<MediaCenterService>().stop();
    super.dispose();
  }

  Future<void> _open(MediaStreamItem item) async {
    if (item.youtube) {
      await context.read<MediaCenterService>().stop();
      final id = YoutubePlayer.convertUrlToId(item.url);
      if (id == null) return;

      controller?.dispose();
      setState(() {
        activeId = item.id;
        controller = YoutubePlayerController(
          initialVideoId: id,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: false,
          ),
        );
      });
      return;
    }

    try {
      controller?.pause();
      setState(() => activeId = item.id);
      await context.read<MediaCenterService>().playRadio(
            url: item.url,
            isPremium: context.read<PurchaseService>().isPremium,
            background: backgroundRadio,
          );
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _stop() async {
    controller?.pause();
    await context.read<MediaCenterService>().stop();
    if (mounted) setState(() => activeId = null);
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PurchaseService>().isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mediaCenterTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const GlassCard(
            child: Row(
              children: [
                Icon(Icons.no_adult_content_rounded),
                SizedBox(width: 12),
                Expanded(child: Text(AppStrings.mediaNoAds)),
              ],
            ),
          ),
          if (controller != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: YoutubePlayer(controller: controller!),
              ),
            ),
          GlassCard(
            child: SwitchListTile(
              value: backgroundRadio,
              onChanged: premium ? (value) => setState(() => backgroundRadio = value) : null,
              title: const Text(AppStrings.backgroundAudioPremiumOnly),
              secondary: const Icon(Icons.workspace_premium_rounded),
            ),
          ),
          ...MediaCenterService.streams.map(
            (item) => GlassCard(
              child: ListTile(
                leading: Icon(item.youtube ? Icons.live_tv_rounded : Icons.radio_rounded),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(item.subtitle),
                trailing: activeId == item.id
                    ? IconButton(onPressed: _stop, icon: const Icon(Icons.stop_circle_rounded))
                    : IconButton(onPressed: () => _open(item), icon: const Icon(Icons.play_circle_fill_rounded)),
              ),
            ),
          ),
          GlassCard(
            child: FilledButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text(AppStrings.stopPlayback),
            ),
          ),
        ],
      ),
    );
  }
}
