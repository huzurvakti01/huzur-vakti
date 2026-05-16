import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/helpdesk_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/safe_banner_ad.dart';

class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key});

  static const screenKey = 'helpdesk';

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen> {
  final subject = TextEditingController();
  final message = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => sending = true);

    try {
      await context.read<HelpdeskService>().createTicket(
            subject: subject.text,
            message: message.text,
          );

      if (!mounted) return;

      subject.clear();
      message.clear();
      context.read<AdService>().trackButtonTap(
            context: context,
            currentScreenKey: HelpdeskScreen.screenKey,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.helpdeskSent),
        ),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.helpdeskTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const GlassCard(
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded),
                SizedBox(width: 12),
                Expanded(child: Text(AppStrings.helpdeskSubtitle)),
              ],
            ),
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(
                    labelText: AppStrings.helpdeskSubject,
                    prefixIcon: Icon(Icons.subject_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: message,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: AppStrings.helpdeskMessage,
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: sending ? null : _send,
                  icon: sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: const Text(AppStrings.helpdeskSend),
                ),
              ],
            ),
          ),
          const SafeBannerAd(screenKey: HelpdeskScreen.screenKey),
        ],
      ),
    );
  }
}
