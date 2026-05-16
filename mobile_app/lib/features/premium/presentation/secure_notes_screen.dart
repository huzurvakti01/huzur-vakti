import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/models/secure_note.dart';
import '../../../core/services/biometric_lock_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/services/secure_notes_service.dart';
import '../../../shared/widgets/glass_card.dart';

class SecureNotesScreen extends StatefulWidget {
  const SecureNotesScreen({super.key});

  static const screenKey = 'secure_notes';

  @override
  State<SecureNotesScreen> createState() => _SecureNotesScreenState();
}

class _SecureNotesScreenState extends State<SecureNotesScreen> {
  final controller = TextEditingController();
  List<SecureNote> notes = [];
  bool loading = true;
  bool unlocked = false;

  @override
  void initState() {
    super.initState();
    _unlockAndLoad();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _unlockAndLoad() async {
    final isPremium = context.read<PurchaseService>().isPremium;

    if (!isPremium) {
      setState(() => loading = false);
      return;
    }

    try {
      final ok = await context.read<BiometricLockService>().authenticate();

      if (!ok) {
        setState(() {
          unlocked = false;
          loading = false;
        });
        return;
      }

      final loaded = await context.read<SecureNotesService>().loadNotes(isPremium: true);

      if (!mounted) return;
      setState(() {
        notes = loaded;
        unlocked = true;
        loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => loading = false);
        ErrorPresenter.showSnackBar(context, error);
      }
    }
  }

  Future<void> _save() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    try {
      await context.read<SecureNotesService>().addNote(
            text: text,
            isPremium: context.read<PurchaseService>().isPremium,
          );

      controller.clear();
      final loaded = await context.read<SecureNotesService>().loadNotes(isPremium: true);

      if (!mounted) return;
      setState(() => notes = loaded);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.secureNoteSaved),
        ),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseService>().isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.secureNotesTitle)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      Icon(isPremium ? Icons.lock_open_rounded : Icons.lock_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPremium ? AppStrings.secureNotesSubtitle : AppStrings.biometricLocked,
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
                if (isPremium && unlocked) ...[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: controller,
                          minLines: 3,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText: AppStrings.secureNoteHint,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _save,
                          child: const Text(AppStrings.save),
                        ),
                      ],
                    ),
                  ),
                  if (notes.isEmpty)
                    const GlassCard(child: Text(AppStrings.secureNotesEmpty))
                  else
                    ...notes.map((note) {
                      return GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.createdAt.toLocal().toString().split('.').first,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            SelectableText(note.text),
                          ],
                        ),
                      );
                    }),
                ],
              ],
            ),
    );
  }
}
