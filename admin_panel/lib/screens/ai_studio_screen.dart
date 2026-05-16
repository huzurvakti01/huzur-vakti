import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../services/ai_autopilot_service.dart';
import '../shared/widgets/glass_panel.dart';

class AiStudioScreen extends StatefulWidget {
  const AiStudioScreen({super.key});

  @override
  State<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends State<AiStudioScreen> {
  final theme = TextEditingController(text: 'huzur, şükür, ibadet bilinci');
  bool generating = false;
  Map<String, dynamic>? lastResult;

  @override
  void dispose() {
    theme.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => generating = true);

    try {
      final result = await context.read<AiAutopilotService>().generateDailyContent(theme.text.trim());
      if (!mounted) return;

      setState(() => lastResult = result);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI günlük içerik üretti ve Firestore daily_content koleksiyonuna yazdı.')),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<AiAutopilotService>();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text('AI Otopilot Studio', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('OpenAI ile günlük ayet/hadis/dua içerikleri üret, AI işlem geçmişini izle ve otomasyon akışını denetle.', style: TextStyle(color: AdminTheme.muted)),
        const SizedBox(height: 24),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('AI İçerik Üretici', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              TextField(
                controller: theme,
                decoration: const InputDecoration(
                  labelText: 'Tema / Yönlendirme',
                  helperText: 'Örn: Ramazan, sabır, şükür, gençlere yönelik manevi motivasyon',
                  prefixIcon: Icon(Icons.auto_awesome_rounded),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: generating ? null : _generate,
                icon: generating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bolt_rounded),
                label: const Text('Tek Tuşla Günlük İçerik Üret'),
              ),
              if (lastResult != null) ...[
                const SizedBox(height: 16),
                SelectableText(lastResult.toString()),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Daily Content', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.watchDailyContent(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return GlassPanel(child: Text(ErrorPresenter.message(snapshot.error!)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!;
            if (docs.isEmpty) return const GlassPanel(child: Text('Henüz AI içerik yok.'));

            return Column(
              children: docs.map((doc) {
                final date = (doc['date'] ?? doc['id'] ?? '').toString();
                final ayah = Map<String, dynamic>.from(doc['ayah'] as Map? ?? {});
                final hadith = Map<String, dynamic>.from(doc['hadith'] as Map? ?? {});
                final dua = Map<String, dynamic>.from(doc['dua'] as Map? ?? {});

                return GlassPanel(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(label: Text(date)),
                      const SizedBox(height: 10),
                      Text('Ayet: ${ayah['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      SelectableText((ayah['body'] ?? '').toString()),
                      const SizedBox(height: 8),
                      Text('Hadis: ${hadith['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      SelectableText((hadith['body'] ?? '').toString()),
                      const SizedBox(height: 8),
                      Text('Dua: ${dua['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      SelectableText((dua['body'] ?? '').toString()),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        Text('AI İşlem Geçmişi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.watchAiLogs(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return GlassPanel(child: Text(ErrorPresenter.message(snapshot.error!)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final logs = snapshot.data!;
            if (logs.isEmpty) return const GlassPanel(child: Text('AI işlem geçmişi boş.'));

            return Column(
              children: logs.map((log) {
                final type = (log['type'] ?? '').toString();
                final score = log['toxicityScore'];
                final createdAt = log['createdAt'];
                final created = createdAt is dynamic && createdAt.toString().contains('Timestamp')
                    ? createdAt.toString()
                    : '';

                return GlassPanel(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        type.contains('deleted') ? Icons.delete_forever_rounded : Icons.auto_awesome_rounded,
                        color: type.contains('deleted') ? AdminTheme.danger : AdminTheme.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          '$type • score: ${score ?? '-'} • ${log['duaId'] ?? log['targetDoc'] ?? ''}',
                        ),
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
