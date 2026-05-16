import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/ai_chat_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../shared/widgets/glass_card.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  static const screenKey = 'ai';

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final List<(String, bool)> _messages = [
    (AppStrings.aiGreeting, false),
  ];
  bool _loading = false;
  AiChatLimitStatus? _limitStatus;

  @override
  void initState() {
    super.initState();
    _loadLimitStatus();
  }

  Future<void> _loadLimitStatus() async {
    try {
      final status = await context.read<AiChatService>().limitStatus(
            isPremium: context.read<PurchaseService>().isPremium,
          );
      if (mounted) setState(() => _limitStatus = status);
    } catch (error, stackTrace) {
      AppLogger.warning(
        AppStrings.logAiLimitCheckFailed,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final isPremium = context.read<PurchaseService>().isPremium;
    final service = context.read<AiChatService>();
    final status = await service.limitStatus(isPremium: isPremium);

    if (status.exhausted) {
      await _showPremiumLimitDialog();
      return;
    }

    setState(() {
      _messages.add((text, true));
      _loading = true;
      _controller.clear();
    });

    try {
      final answer = await service.sendMessage(
        question: text,
        isPremium: isPremium,
        languageCode: context.locale.languageCode,
      );

      _messages.add((answer, false));
      await _loadLimitStatus();
    } on AppException catch (error) {
      if (error.code == 'ai_daily_limit_exceeded') {
        await _showPremiumLimitDialog();
      } else {
        _messages.add((ErrorPresenter.readableMessage(error), false));
        if (mounted) ErrorPresenter.showSnackBar(context, error);
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAiChatFailed,
        error: error,
        stackTrace: stackTrace,
      );

      final message = ErrorPresenter.readableMessage(
        error,
        fallback: AppStrings.aiUnavailable,
      );

      _messages.add((message, false));
      if (mounted) ErrorPresenter.showSnackBar(context, error, fallback: message);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showPremiumLimitDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text(AppStrings.aiDailyLimitTitle),
        content: const Text(AppStrings.aiDailyLimitMessage),
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
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PurchaseService>().isPremium;
    final status = _limitStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.aiTitle),
      ),
      body: Column(
        children: [
          const GlassCard(
            margin: EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded),
                SizedBox(width: 10),
                Expanded(child: Text(AppStrings.aiDisclaimer)),
              ],
            ),
          ),
          if (!premium && status != null)
            GlassCard(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.format(
                        AppStrings.aiRemainingLimit,
                        {'remaining': status.remaining},
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/premium'),
                    child: const Text(AppStrings.upgradeToPremium),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.$2 ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: msg.$2 ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg.$1,
                      style: TextStyle(color: msg.$2 ? Colors.white : null),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: AppStrings.aiInputHint,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _send,
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
