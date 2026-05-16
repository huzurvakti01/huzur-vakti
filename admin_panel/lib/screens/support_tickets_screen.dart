import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../services/auth_service.dart';
import '../services/support_ticket_service.dart';
import '../shared/widgets/glass_panel.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  Future<void> _reply(BuildContext context, Map<String, dynamic> ticket) async {
    final controller = TextEditingController(text: (ticket['adminReply'] ?? '').toString());

    final reply = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Destek Talebini Yanıtla'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(labelText: 'Cevap'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Gönder')),
        ],
      ),
    );

    controller.dispose();

    if (reply == null || reply.trim().isEmpty || !context.mounted) return;

    try {
      await context.read<SupportTicketService>().reply(
            ticketId: ticket['id'].toString(),
            reply: reply,
            adminEmail: context.read<AuthService>().admin?.email ?? 'admin',
          );
    } catch (error) {
      if (context.mounted) ErrorPresenter.snack(context, error);
    }
  }

  Future<void> _close(BuildContext context, Map<String, dynamic> ticket) async {
    try {
      await context.read<SupportTicketService>().close(
            ticketId: ticket['id'].toString(),
            adminEmail: context.read<AuthService>().admin?.email ?? 'admin',
          );
    } catch (error) {
      if (context.mounted) ErrorPresenter.snack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          'Destek Talepleri',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mobil uygulamadan gelen helpdesk ticket’larını yanıtla ve kapat.',
          style: TextStyle(color: AdminTheme.muted),
        ),
        const SizedBox(height: 22),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: context.read<SupportTicketService>().watchTickets(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return GlassPanel(child: Text(ErrorPresenter.message(snapshot.error!)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final tickets = snapshot.data!;
            if (tickets.isEmpty) return const GlassPanel(child: Text('Açık destek talebi yok.'));

            return Column(
              children: tickets.map((ticket) {
                final status = (ticket['status'] ?? 'open').toString();

                return GlassPanel(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(status)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (ticket['subject'] ?? '').toString(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText((ticket['message'] ?? '').toString()),
                      const SizedBox(height: 12),
                      SelectableText('UID: ${ticket['uid'] ?? '-'} • Email: ${ticket['email'] ?? '-'}'),
                      if ((ticket['adminReply'] ?? '').toString().isNotEmpty) ...[
                        const Divider(),
                        SelectableText('Cevap: ${ticket['adminReply']}'),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _reply(context, ticket),
                            icon: const Icon(Icons.reply_rounded),
                            label: const Text('Yanıtla'),
                          ),
                          TextButton.icon(
                            onPressed: () => _close(context, ticket),
                            icon: const Icon(Icons.done_all_rounded),
                            label: const Text('Kapat'),
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
