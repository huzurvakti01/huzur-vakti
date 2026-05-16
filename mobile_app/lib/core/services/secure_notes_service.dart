import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../models/secure_note.dart';

class SecureNotesService {
  static const _notesKey = 'premium_secure_notes';

  Future<List<SecureNote>> loadNotes({
    required bool isPremium,
  }) async {
    if (!isPremium) {
      throw const AppException(
        AppStrings.biometricLocked,
        code: 'premium_required_secure_notes',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesKey);

    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => SecureNote.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addNote({
    required String text,
    required bool isPremium,
  }) async {
    if (!isPremium) {
      throw const AppException(
        AppStrings.biometricLocked,
        code: 'premium_required_secure_notes',
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await loadNotes(isPremium: isPremium);
      final next = [
        SecureNote(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text.trim(),
          createdAt: DateTime.now(),
        ),
        ...current,
      ];

      await prefs.setString(
        _notesKey,
        jsonEncode(next.map((item) => item.toJson()).toList()),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logSecureNoteSaveFailed,
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.genericError,
        cause: error,
        stackTrace: stackTrace,
        code: 'secure_note_save_failed',
      );
    }
  }
}
