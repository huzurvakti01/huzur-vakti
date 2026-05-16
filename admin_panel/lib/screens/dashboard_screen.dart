import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/admin_theme.dart';
import '../services/ai_autopilot_service.dart';
import '../services/kill_switch_service.dart';
import '../services/user_matrix_service.dart';
import '../shared/widgets/glass_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool aiLoading = false;
  Map<String, dynamic>? aiSummary;

  Future<void> _generateAiSummary() async {
    setState(() => aiLoading = true);

    try {
      final result = await context.read<AiAutopilotService>().generateDashboardSummary();
      if (mounted) setState(() => aiSummary = result);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = context.read<UserMatrixService>().watchFirestoreUsers();

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          'God Mode Dashboard',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text('Canlı sistem durumu, kullanıcı sinyalleri ve acil kumanda özeti.', style: TextStyle(color: AdminTheme.muted)),
        const SizedBox(height: 24),
        StreamBuilder(
          stream: usersStream,
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];
            final premium = users.where((u) => u.isPremium || u.isVip).length;
            final cloudActive = users.where((u) => u.lastSeenAt != null).length;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _MetricCard(title: 'Toplam Kullanıcı', value: '${users.length}', icon: Icons.people_rounded),
                _MetricCard(title: 'Premium / VIP', value: '$premium', icon: Icons.workspace_premium_rounded),
                _MetricCard(title: 'Aktif Senkron', value: '$cloudActive', icon: Icons.cloud_done_rounded),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_alt_rounded, color: AdminTheme.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Anomali ve İstatistik Asistanı',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: aiLoading ? null : _generateAiSummary,
                    icon: aiLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text('AI Özet Üret'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (aiSummary == null)
                const Text('OpenAI ile kullanıcı, dua ve AI işlem verilerini yorumlatıp aksiyon önerisi alabilirsiniz.', style: TextStyle(color: AdminTheme.muted))
              else
                SelectableText(aiSummary.toString()),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StreamBuilder(
          stream: context.read<KillSwitchService>().watchConfig(),
          builder: (context, snapshot) {
            final config = snapshot.data;

            return GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acil Durum Özeti', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  if (config == null)
                    const LinearProgressIndicator()
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StatusChip(label: 'Force Update', active: config.forceUpdateEnabled),
                        _StatusChip(label: 'AI Sohbet', active: config.aiChatEnabled),
                        _StatusChip(label: 'Zikirmatik', active: config.zikirmatikEnabled),
                        _StatusChip(label: 'Dua Topluluğu', active: config.duaCommunityEnabled),
                        _StatusChip(label: 'Cloud Sync', active: config.cloudSyncEnabled),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: GlassPanel(
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AdminTheme.emerald.withOpacity(.22),
              child: Icon(icon, color: AdminTheme.mint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AdminTheme.muted)),
                  Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: ${active ? 'Açık' : 'Kapalı'}'),
      avatar: Icon(active ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18),
      backgroundColor: (active ? AdminTheme.emerald : AdminTheme.danger).withOpacity(.18),
      side: BorderSide(color: Colors.white.withOpacity(.08)),
    );
  }
}
