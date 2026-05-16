import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../models/admin_user_matrix.dart';
import '../services/user_matrix_service.dart';
import '../shared/widgets/glass_panel.dart';

class UserMatrixScreen extends StatefulWidget {
  const UserMatrixScreen({super.key});

  @override
  State<UserMatrixScreen> createState() => _UserMatrixScreenState();
}

class _UserMatrixScreenState extends State<UserMatrixScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _edit(AdminUserMatrix user) async {
    final updated = await showDialog<AdminUserMatrix>(
      context: context,
      builder: (_) => _UserEditDialog(user: user),
    );

    if (updated == null || !mounted) return;

    try {
      await context.read<UserMatrixService>().updateUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı güncellendi.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  Future<void> _delete(AdminUserMatrix user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hard Delete'),
        content: Text('${user.email.isEmpty ? user.uid : user.email} hesabı Auth + Firestore üzerinden tamamen silinsin mi? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kalıcı Sil'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await context.read<UserMatrixService>().hardDelete(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı kalıcı olarak silindi.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }


  Future<void> _resetPassword(AdminUserMatrix user) async {
    if (user.email.isEmpty) {
      ErrorPresenter.snack(context, const FormatException('Bu kullanıcıda email yok.'));
      return;
    }

    try {
      final link = await context.read<UserMatrixService>().resetPassword(user.email);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Şifre Sıfırlama Linki'),
          content: SelectableText(link),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
          ],
        ),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  Future<void> _banDevice(AdminUserMatrix user) async {
    final controller = TextEditingController();

    final deviceId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihazı Kalıcı Banla'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device ID',
            helperText: 'Mobil uygulamanın deviceId alanından gelen kimlik',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Banla')),
        ],
      ),
    );

    controller.dispose();

    if (deviceId == null || deviceId.isEmpty || !mounted) return;

    try {
      await context.read<UserMatrixService>().banDevice(uid: user.uid, deviceId: deviceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cihaz kalıcı olarak banlandı.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<UserMatrixService>();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User Matrix', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Auth ve Firestore kullanıcılarını tek yerden denetle, premium/ibadet verilerine müdahale et.', style: TextStyle(color: AdminTheme.muted)),
              const SizedBox(height: 18),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'UID, email veya ad ara',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AdminUserMatrix>>(
            stream: service.watchFirestoreUsers(search: search.text),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text(ErrorPresenter.message(snapshot.error!)));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final users = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: GlassPanel(
                  padding: EdgeInsets.zero,
                  child: DataTable(
                    columnSpacing: 28,
                    headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(.06)),
                    columns: const [
                      DataColumn(label: Text('Kullanıcı')),
                      DataColumn(label: Text('Premium')),
                      DataColumn(label: Text('Zikir')),
                      DataColumn(label: Text('Streak')),
                      DataColumn(label: Text('Son Görülme')),
                      DataColumn(label: Text('Aksiyon')),
                    ],
                    rows: users.map((user) {
                      final seen = user.lastSeenAt == null ? '-' : dateFormat.format(user.lastSeenAt!);

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(user.email.isEmpty ? 'Email yok' : user.email, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  Text(user.uid, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AdminTheme.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Chip(label: Text((user.isPremium || user.isVip) ? 'Aktif' : 'Free'))),
                          DataCell(Text('${user.dhikrToday}')),
                          DataCell(Text('${user.streakDays} gün')),
                          DataCell(Text(seen)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(onPressed: () => _edit(user), icon: const Icon(Icons.edit_rounded)),
                                IconButton(onPressed: () => _resetPassword(user), icon: const Icon(Icons.password_rounded, color: AdminTheme.gold)),
                                IconButton(onPressed: () => _banDevice(user), icon: const Icon(Icons.phonelink_erase_rounded, color: AdminTheme.danger)),
                                IconButton(onPressed: () => _delete(user), icon: const Icon(Icons.delete_forever_rounded, color: AdminTheme.danger)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserEditDialog extends StatefulWidget {
  final AdminUserMatrix user;

  const _UserEditDialog({required this.user});

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  late bool premium;
  late bool vip;
  late TextEditingController dhikr;
  late TextEditingController streak;
  late TextEditingController premiumExpiresAt;
  late TextEditingController bannedDeviceIds;
  late bool deviceBanned;
  final qazaControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    premium = widget.user.isPremium;
    vip = widget.user.isVip;
    dhikr = TextEditingController(text: '${widget.user.dhikrToday}');
    streak = TextEditingController(text: '${widget.user.streakDays}');
    premiumExpiresAt = TextEditingController(text: widget.user.premiumExpiresAt);
    bannedDeviceIds = TextEditingController(text: widget.user.bannedDeviceIds.join(','));
    deviceBanned = widget.user.deviceBanned;

    final keys = {
      'Sabah',
      'Öğle',
      'İkindi',
      'Akşam',
      'Yatsı',
      ...widget.user.qazaCounts.keys,
    };

    for (final key in keys) {
      qazaControllers[key] = TextEditingController(text: '${widget.user.qazaCounts[key] ?? 0}');
    }
  }

  @override
  void dispose() {
    dhikr.dispose();
    streak.dispose();
    premiumExpiresAt.dispose();
    bannedDeviceIds.dispose();
    for (final controller in qazaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final counts = qazaControllers.map((key, controller) {
      return MapEntry(key, int.tryParse(controller.text.trim()) ?? 0);
    });

    Navigator.pop(
      context,
      AdminUserMatrix(
        uid: widget.user.uid,
        email: widget.user.email,
        displayName: widget.user.displayName,
        disabled: widget.user.disabled,
        isPremium: premium,
        isVip: vip,
        qazaCounts: counts,
        dhikrToday: int.tryParse(dhikr.text.trim()) ?? 0,
        streakDays: int.tryParse(streak.text.trim()) ?? 0,
        createdAt: widget.user.createdAt,
        lastSeenAt: widget.user.lastSeenAt,
        premiumExpiresAt: premiumExpiresAt.text.trim(),
        deviceBanned: deviceBanned,
        bannedDeviceIds: bannedDeviceIds.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      ),
    );
  }


  Future<void> _resetPassword(AdminUserMatrix user) async {
    if (user.email.isEmpty) {
      ErrorPresenter.snack(context, const FormatException('Bu kullanıcıda email yok.'));
      return;
    }

    try {
      final link = await context.read<UserMatrixService>().resetPassword(user.email);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Şifre Sıfırlama Linki'),
          content: SelectableText(link),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
          ],
        ),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  Future<void> _banDevice(AdminUserMatrix user) async {
    final controller = TextEditingController();

    final deviceId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihazı Kalıcı Banla'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device ID',
            helperText: 'Mobil uygulamanın deviceId alanından gelen kimlik',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Banla')),
        ],
      ),
    );

    controller.dispose();

    if (deviceId == null || deviceId.isEmpty || !mounted) return;

    try {
      await context.read<UserMatrixService>().banDevice(uid: user.uid, deviceId: deviceId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cihaz kalıcı olarak banlandı.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kullanıcıyı Düzenle'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SwitchListTile(
                value: premium,
                onChanged: (value) => setState(() => premium = value),
                title: const Text('Premium'),
              ),
              SwitchListTile(
                value: vip,
                onChanged: (value) => setState(() => vip = value),
                title: const Text('VIP / Lifetime'),
              ),
              SwitchListTile(
                value: deviceBanned,
                onChanged: (value) => setState(() => deviceBanned = value),
                title: const Text('Cihaz/Hesap Banlı'),
              ),
              TextField(
                controller: premiumExpiresAt,
                decoration: const InputDecoration(
                  labelText: 'Premium Bitiş Tarihi',
                  helperText: 'ISO format: 2026-12-31T23:59:00. Lifetime için boş bırakın.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bannedDeviceIds,
                decoration: const InputDecoration(
                  labelText: 'Banlı Device ID Listesi',
                  helperText: 'Virgülle ayırın',
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: dhikr, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Zikir Sayısı')),
              const SizedBox(height: 12),
              TextField(controller: streak, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Günlük Seri')),
              const SizedBox(height: 12),
              ...qazaControllers.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: entry.value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: '${entry.key} Kaza'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}
