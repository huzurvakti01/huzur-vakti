import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/models/dua_request.dart';
import '../../../core/services/dua_brotherhood_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';
import '../../../core/constants/app_strings.dart';

class DuaBrotherhoodScreen extends StatefulWidget {
  const DuaBrotherhoodScreen({super.key});

  static const screenKey = 'dua_brotherhood';

  @override
  State<DuaBrotherhoodScreen> createState() => _DuaBrotherhoodScreenState();
}

class _DuaBrotherhoodScreenState extends State<DuaBrotherhoodScreen> {
  final _text = TextEditingController();
  String _category = AppStrings.communityGeneral;

  Future<void> _share() async {
    try {
      await context.read<DuaBrotherhoodService>().create(
            text: _text.text,
            category: _category,
          );
      _text.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.communityShared),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logDuaCreateFailed,
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<DuaBrotherhoodService>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.communityTitle)),
      body: StreamBuilder<List<DuaRequest>>(
        stream: service.watchDuas(),
        builder: (context, snapshot) {
          final duas = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _text,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: AppStrings.communityInputLabel,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            items: [AppStrings.communityGeneral, AppStrings.communityHealth, AppStrings.communityFamily, AppStrings.communityRizq, AppStrings.communityPeace]
                                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                                .toList(),
                            onChanged: (v) => setState(() => _category = v ?? AppStrings.communityGeneral),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(onPressed: _share, child: const Text(AppStrings.communityShare)),
                      ],
                    ),
                  ],
                ),
              ),
              if (snapshot.hasError)
                GlassCard(child: Text(AppStrings.format(AppStrings.communityListFailed, {'error': snapshot.error ?? ''})))
              else if (!snapshot.hasData)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else
                ...duas.map(
                  (dua) => GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Chip(label: Text(dua.category)),
                          const Spacer(),
                          const Text(AppStrings.communityAnonymous),
                        ]),
                        const SizedBox(height: 10),
                        Text(dua.text, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.45)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                try {
                                  await service.amin(dua.id);
                                } catch (error, stackTrace) {
                                  AppLogger.error(
                                    AppStrings.logAminFailed,
                                    error: error,
                                    stackTrace: stackTrace,
                                    context: {'duaId': dua.id},
                                  );
                                  if (context.mounted) ErrorPresenter.showSnackBar(context, error);
                                }
                              },
                              icon: const Icon(Icons.favorite_rounded),
                              label: Text(AppStrings.format(AppStrings.communityAmin, {'count': dua.aminCount})),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  await service.report(dua.id, AppStrings.communityReportReason);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        content: const Text(AppStrings.communityReported),
                                      ),
                                    );
                                  }
                                } catch (error, stackTrace) {
                                  AppLogger.error(
                                    AppStrings.logDuaReportFailed,
                                    error: error,
                                    stackTrace: stackTrace,
                                    context: {'duaId': dua.id},
                                  );
                                  if (context.mounted) ErrorPresenter.showSnackBar(context, error);
                                }
                              },
                              icon: const Icon(Icons.report_rounded),
                              label: const Text(AppStrings.communityReport),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SafeBannerAd(screenKey: DuaBrotherhoodScreen.screenKey),
            ],
          );
        },
      ),
    );
  }
}
