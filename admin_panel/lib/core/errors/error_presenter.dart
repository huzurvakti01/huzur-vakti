import 'package:flutter/material.dart';

import 'app_exception.dart';

class ErrorPresenter {
  ErrorPresenter._();

  static void snack(BuildContext context, Object error, {String? fallback}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Text(message(error, fallback: fallback)),
        ),
      );
  }

  static String message(Object error, {String? fallback}) {
    if (error is AppException) return error.message;

    final raw = error.toString().toLowerCase();
    if (raw.contains('permission-denied')) return 'Bu işlem için admin yetkiniz yok.';
    if (raw.contains('network') || raw.contains('socket')) return 'Bağlantı hatası. İnternetinizi kontrol edin.';
    return fallback ?? 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
  }
}
