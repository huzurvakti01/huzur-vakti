import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../models/cms_content.dart';
import '../services/auth_service.dart';
import '../services/cms_service.dart';
import '../shared/widgets/glass_panel.dart';

class CmsStudioScreen extends StatefulWidget {
  const CmsStudioScreen({super.key});

  @override
  State<CmsStudioScreen> createState() => _CmsStudioScreenState();
}

class _CmsStudioScreenState extends State<CmsStudioScreen> {
  Future<void> _edit({CmsContent? content}) async {
    final id = TextEditingController(text: content?.id ?? '');
    final title = TextEditingController(text: content?.title ?? '');
    final body = TextEditingController(text: content?.body ?? '');
    String type = content?.type ?? 'text';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(content == null ? 'İçerik Oluştur' : 'İçeriği Düzenle'),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: id,
                      enabled: content == null,
                      decoration: const InputDecoration(
                        labelText: 'İçerik ID',
                        helperText: 'Örn: daily_ayah, daily_hadith, about_text',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Tip'),
                      items: const [
                        DropdownMenuItem(value: 'ayah', child: Text('Günün Ayeti')),
                        DropdownMenuItem(value: 'hadith', child: Text('Günün Hadisi')),
                        DropdownMenuItem(value: 'about', child: Text('Hakkımızda')),
                        DropdownMenuItem(value: 'text', child: Text('Sabit Metin')),
                      ],
                      onChanged: (value) => setDialogState(() => type = value ?? 'text'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: title, decoration: const InputDecoration(labelText: 'Başlık')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: body,
                      minLines: 6,
                      maxLines: 14,
                      decoration: const InputDecoration(labelText: 'İçerik'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
            ],
          ),
        );
      },
    );

    if (ok != true || !mounted) return;

    try {
      await context.read<CmsService>().upsertContent(
            id: id.text.trim(),
            title: title.text,
            body: body.text,
            type: type,
            adminEmail: context.read<AuthService>().admin!.email ?? 'admin',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İçerik kaydedildi.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      id.dispose();
      title.dispose();
      body.dispose();
    }
  }

  Future<void> _delete(CmsContent content) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İçeriği Sil'),
        content: Text('${content.title} silinsin mi?'),
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
      await context.read<CmsService>().deleteContent(
            id: content.id,
            adminEmail: context.read<AuthService>().admin!.email ?? 'admin',
          );
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Content Studio', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Günün ayeti, hadisi ve uygulama sabit metinlerini canlı düzenle.', style: TextStyle(color: AdminTheme.muted)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni İçerik'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        StreamBuilder<List<CmsContent>>(
          stream: context.read<CmsService>().watchContent(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return GlassPanel(child: Text(ErrorPresenter.message(snapshot.error!)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final items = snapshot.data!;

            if (items.isEmpty) {
              return const GlassPanel(child: Text('Henüz CMS içeriği yok.'));
            }

            return Column(
              children: items.map((item) {
                return GlassPanel(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(item.type)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (item.updatedAt != null)
                            Text(dateFormat.format(item.updatedAt!), style: const TextStyle(color: AdminTheme.muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(item.body, maxLines: 4),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(onPressed: () => _edit(content: item), icon: const Icon(Icons.edit_rounded), label: const Text('Düzenle')),
                          TextButton.icon(
                            onPressed: () => _delete(item),
                            icon: const Icon(Icons.delete_rounded),
                            label: const Text('Sil'),
                            style: TextButton.styleFrom(foregroundColor: AdminTheme.danger),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
