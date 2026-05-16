import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../models/kill_switch_config.dart';
import '../services/kill_switch_service.dart';
import '../shared/widgets/glass_panel.dart';

class KillSwitchScreen extends StatefulWidget {
  const KillSwitchScreen({super.key});

  @override
  State<KillSwitchScreen> createState() => _KillSwitchScreenState();
}

class _KillSwitchScreenState extends State<KillSwitchScreen> {
  final minVersion = TextEditingController();
  KillSwitchConfig? draft;
  bool saving = false;

  @override
  void dispose() {
    minVersion.dispose();
    super.dispose();
  }

  void _hydrate(KillSwitchConfig config) {
    draft ??= config;
    if (minVersion.text.isEmpty) {
      minVersion.text = '${config.minVersionCode}';
    }
  }

  Future<void> _save() async {
    final current = draft ?? KillSwitchConfig.defaults();
    final version = int.tryParse(minVersion.text.trim()) ?? current.minVersionCode;

    if (version < 1) {
      ErrorPresenter.snack(context, const FormatException('Min. versiyon kodu 1 veya üstü olmalı.'));
      return;
    }

    setState(() => saving = true);

    try {
      await context.read<KillSwitchService>().publish(
            current.copyWith(minVersionCode: version),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kill Switch & Remote Config yayınlandı.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<KillSwitchService>();

    return StreamBuilder<KillSwitchConfig>(
      stream: service.watchConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? KillSwitchConfig.defaults();
        _hydrate(config);
        final current = draft ?? config;

        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Text('Kill Switch & Force Update', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Acil durumda uygulama modüllerini kapat, minimum versiyonu zorunlu kıl ve Remote Config’e yayınla.', style: TextStyle(color: AdminTheme.muted)),
            const SizedBox(height: 24),
            GlassPanel(
              child: Column(
                children: [
                  SwitchListTile(
                    value: current.forceUpdateEnabled,
                    onChanged: (value) => setState(() => draft = current.copyWith(forceUpdateEnabled: value)),
                    title: const Text('Zorunlu Güncelleme'),
                    subtitle: const Text('Açıldığında min. versiyon kodunun altındaki uygulamalar bloke edilir.'),
                    secondary: const Icon(Icons.system_update_alt_rounded),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: minVersion,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min. Versiyon Kodu',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassPanel(
              child: Column(
                children: [
                  _SwitchRow(
                    title: 'AI Sohbet',
                    value: current.aiChatEnabled,
                    onChanged: (value) => setState(() => draft = current.copyWith(aiChatEnabled: value)),
                  ),
                  _SwitchRow(
                    title: 'Zikirmatik',
                    value: current.zikirmatikEnabled,
                    onChanged: (value) => setState(() => draft = current.copyWith(zikirmatikEnabled: value)),
                  ),
                  _SwitchRow(
                    title: 'Dua Topluluğu',
                    value: current.duaCommunityEnabled,
                    onChanged: (value) => setState(() => draft = current.copyWith(duaCommunityEnabled: value)),
                  ),
                  _SwitchRow(
                    title: 'Premium Ses Kütüphanesi',
                    value: current.premiumLibraryEnabled,
                    onChanged: (value) => setState(() => draft = current.copyWith(premiumLibraryEnabled: value)),
                  ),
                  _SwitchRow(
                    title: 'Cloud Sync',
                    value: current.cloudSyncEnabled,
                    onChanged: (value) => setState(() => draft = current.copyWith(cloudSyncEnabled: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded),
              label: const Text('Firestore + Remote Config Yayınla'),
            ),
          ],
        );
      },
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
