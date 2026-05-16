import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../models/dua_admin_record.dart';
import '../services/ai_autopilot_service.dart';
import '../services/auth_service.dart';
import '../services/moderation_service.dart';
import '../shared/widgets/glass_panel.dart';

class AbsoluteModerationScreen extends StatefulWidget {
  const AbsoluteModerationScreen({super.key});

  @override
  State<AbsoluteModerationScreen> createState() => _AbsoluteModerationScreenState();
}

class _AbsoluteModerationScreenState extends State<AbsoluteModerationScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _edit(DuaAdminRecord dua) async {
    final controller = TextEditingController(text: dua.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duayı Düzenle'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 12,
            decoration: const InputDecoration(labelText: 'Dua metni'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Kaydet')),
        ],
      ),
    );

    controller.dispose();

    if (result == null || !mounted) return;

    try {
      await context.read<ModerationService>().updateDua(
            id: dua.id,
            text: result,
            adminEmail: context.read<AuthService>().admin!.email ?? 'admin',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dua güncellendi.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }


  Future<void> _analyze(DuaAdminRecord dua) async {
    try {
      final result = await context.read<AiAutopilotService>().analyzeDua(
            duaId: dua.id,
            text: dua.text,
          );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Moderasyon Sonucu'),
          content: SizedBox(
            width: 560,
            child: SelectableText(result.toString()),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
          ],
        ),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  Future<void> _delete(DuaAdminRecord dua) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duayı Sil'),
        content: const Text('Bu paylaşım kalıcı olarak silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await context.read<ModerationService>().deleteDua(
            id: dua.id,
            adminEmail: context.read<AuthService>().admin!.email ?? 'admin',
          );
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<ModerationService>();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Absolute Moderation', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Şikayet edilmese bile tüm dua paylaşımlarını gör, metni düzenle ve gerçek UID bilgisini incele.', style: TextStyle(color: AdminTheme.muted)),
              const SizedBox(height: 18),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Dua metni, kategori veya UID ara',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<DuaAdminRecord>>(
            stream: service.watchAllDuas(search: search.text),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text(ErrorPresenter.message(snapshot.error!)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final duas = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                itemCount: duas.length,
                itemBuilder: (context, index) {
                  final dua = duas[index];

                  return GlassPanel(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(dua.reported ? 'Şikayetli' : 'Normal'),
                              backgroundColor: (dua.reported ? AdminTheme.danger : AdminTheme.emerald).withOpacity(.18),
                            ),
                            const SizedBox(width: 8),
                            Chip(label: Text(dua.category.isEmpty ? 'Kategori yok' : dua.category)),
                            const Spacer(),
                            Text(dateFormat.format(dua.createdAt), style: const TextStyle(color: AdminTheme.muted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectableText(dua.text, style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.45)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                'Author UID: ${dua.uid.isEmpty ? 'yok' : dua.uid}',
                                style: const TextStyle(color: AdminTheme.gold, fontWeight: FontWeight.w800),
                              ),
                            ),
                            TextButton.icon(onPressed: () => _analyze(dua), icon: const Icon(Icons.psychology_alt_rounded), label: const Text('AI Analiz')),
                            TextButton.icon(onPressed: () => _edit(dua), icon: const Icon(Icons.edit_rounded), label: const Text('Edit')),
                            TextButton.icon(
                              onPressed: () => _delete(dua),
                              icon: const Icon(Icons.delete_rounded),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(foregroundColor: AdminTheme.danger),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
