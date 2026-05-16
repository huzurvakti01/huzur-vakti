import 'package:flutter/material.dart';

import 'app_exception.dart';

class ErrorPresenter {
  ErrorPresenter._();

  static void showSnackBar(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    if (!context.mounted) return;

    final message = readableMessage(error, fallback: fallback);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Text(message),
          action: SnackBarAction(
            label: 'Tamam',
            onPressed: () {},
          ),
        ),
      );
  }

  static Future<void> showDialogMessage(
    BuildContext context,
    Object error, {
    String title = 'Bir sorun oluştu',
    String? fallback,
  }) async {
    if (!context.mounted) return;

    final message = readableMessage(error, fallback: fallback);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static String readableMessage(Object error, {String? fallback}) {
    if (error is AppException) return error.message;
    final raw = error.toString().toLowerCase();

    if (raw.contains('socket') ||
        raw.contains('timeout') ||
        raw.contains('network') ||
        raw.contains('connection') ||
        raw.contains('host lookup')) {
      return 'Bağlantı koptu, lütfen internetinizi kontrol edin.';
    }

    if (raw.contains('permission') || raw.contains('denied')) {
      return 'Gerekli izin verilmedi. Lütfen ayarlardan izinleri kontrol edin.';
    }

    return fallback ?? 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
  }
}
