import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/error_presenter.dart';
import '../../core/services/prayer_dnd_service.dart';
import '../../core/theme/app_theme.dart';
import 'glass_card.dart';

class DndPermissionCard extends StatefulWidget {
  const DndPermissionCard({super.key});

  @override
  State<DndPermissionCard> createState() => _DndPermissionCardState();
}

class _DndPermissionCardState extends State<DndPermissionCard> {
  bool? granted;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final value = await context.read<PrayerDndService>().hasPolicyAccess();
    if (mounted) setState(() => granted = value);
  }

  Future<void> _openSettings() async {
    setState(() => loading = true);

    try {
      await context.read<PrayerDndService>().openPolicySettings();
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() => loading = false);
        await _check();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = granted == true;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allowed ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: allowed ? AppTheme.emerald : AppTheme.gold,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allowed ? AppStrings.dndPermissionGranted : AppStrings.dndPermissionMissing,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  allowed
                      ? AppStrings.prayerDndSubtitle
                      : 'Android, Rahatsız Etmeyin erişimini güvenlik nedeniyle manuel onaylatır.',
                ),
                if (!allowed) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: loading ? null : _openSettings,
                    icon: loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.settings_rounded),
                    label: const Text(AppStrings.dndOpenPolicySettings),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
