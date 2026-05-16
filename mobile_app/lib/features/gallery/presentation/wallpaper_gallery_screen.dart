import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/gallery_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class WallpaperGalleryScreen extends StatefulWidget {
  const WallpaperGalleryScreen({super.key});

  static const screenKey = 'wallpaper_gallery';

  @override
  State<WallpaperGalleryScreen> createState() => _WallpaperGalleryScreenState();
}

class _WallpaperGalleryScreenState extends State<WallpaperGalleryScreen> {
  late Future<List<GalleryImage>> future;

  @override
  void initState() {
    super.initState();
    future = GalleryService().fetchIslamicWallpapers();
  }

  Future<void> _reload() async {
    setState(() => future = GalleryService().fetchIslamicWallpapers());
    await future;
  }

  Future<void> _share(GalleryImage image) async {
    await Share.share('${image.title}\n${image.imageUrl}\n${image.sourceUrl}');
  }


  Future<void> _saveToDevice(GalleryImage image) async {
    try {
      await GalleryService().saveImageToDevice(image);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.wallpaperSavedToDevice),
        ),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  Future<void> _openImageActions(GalleryImage image) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.wallpaper_rounded),
                title: Text(image.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(image.author),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text(AppStrings.wallpaperSaveToDevice),
                onTap: () {
                  Navigator.pop(context);
                  _saveToDevice(image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.draw_rounded),
                title: const Text(AppStrings.wallpaperMakeCard),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/greeting-card', extra: image.imageUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text(AppStrings.shareCard),
                onTap: () {
                  Navigator.pop(context);
                  _share(image);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.wallpaperTitle),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<GalleryImage>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return  ListView(children: [SizedBox(height: 360, child: Center(child: CircularProgressIndicator()))]);
            }

            final images = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              itemCount: images.length + 1,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemBuilder: (context, index) {
                if (index == images.length) {
                  return const SafeBannerAd(screenKey: WallpaperGalleryScreen.screenKey);
                }

                final image = images[index];

                return GlassCard(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  onTap: () => _openImageActions(image),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(image.imageUrl, fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black.withOpacity(.72)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(image.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              Text(image.author, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _share(image),
                                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                                  ),
                                  IconButton(
                                    onPressed: () => launchUrl(Uri.parse(image.sourceUrl), mode: LaunchMode.externalApplication),
                                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
