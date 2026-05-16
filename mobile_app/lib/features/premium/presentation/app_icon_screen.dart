import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/app_icon_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class AppIconScreen extends StatefulWidget {
  const AppIconScreen({super.key});

  static const screenKey = 'app_icon';

  @override
  State<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends State<AppIconScreen> {
  String selectedId = 'default';
  bool loading = true;
  bool changing = false;

  @override
  void initState() {
    super.initState();
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final id = await context.read<AppIconService>().selectedIconId();
    if (mounted) {
      setState(() {
        selectedId = id;
        loading = false;
      });
    }
  }

  Future<void> _changeIcon(AppIconOption option) async {
    final isPremium = context.read<PurchaseService>().isPremium;

    if (!isPremium) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: const Text(AppStrings.premiumTitle),
          content: const Text(AppStrings.appIconLocked),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.later),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/premium');
              },
              child: const Text(AppStrings.upgradeToPremium),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => changing = true);

    try {
      await context.read<AppIconService>().changeIcon(
            option: option,
            isPremium: true,
          );

      if (!mounted) return;
      setState(() => selectedId = option.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Text(AppStrings.format(AppStrings.appIconChanged, {'name': option.title})),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAppIconChangeFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'iconId': option.id},
      );
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) setState(() => changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseService>().isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appIconTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          GlassCard(
            child: Row(
              children: [
                Icon(
                  isPremium ? Icons.workspace_premium_rounded : Icons.lock_rounded,
                  color: isPremium ? AppTheme.gold : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPremium ? AppStrings.appIconSubtitle : AppStrings.appIconLocked,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (!isPremium)
                  TextButton(
                    onPressed: () => context.push('/premium'),
                    child: const Text(AppStrings.upgradeToPremium),
                  ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()))
          else
            ...AppIconService.options.map((option) {
              return GlassCard(
                onTap: changing ? null : () => _changeIcon(option),
                child: ListTile(
                  leading: _IconPreview(option: option),
                  title: Text(option.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(option.id == selectedId ? AppStrings.appIconSelected : AppStrings.appIconTapToApply),
                  trailing: option.id == selectedId
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.emerald)
                      : const Icon(Icons.chevron_right_rounded),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _IconPreview extends StatelessWidget {
  final AppIconOption option;

  const _IconPreview({required this.option});

  @override
  Widget build(BuildContext context) {
    final colors = switch (option.id) {
      'gold' => [AppTheme.gold, const Color(0xFF7A5A12)],
      'dark' => [const Color(0xFF08110F), const Color(0xFF263A35)],
      _ => [AppTheme.emerald, AppTheme.deepEmerald],
    };

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        option.id == 'dark' ? Icons.dark_mode_rounded : Icons.mosque_rounded,
        color: Colors.white,
      ),
    );
  }
}
