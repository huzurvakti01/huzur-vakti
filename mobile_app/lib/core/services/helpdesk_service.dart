import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class HelpdeskService {
  HelpdeskService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> createTicket({
    required String subject,
    required String message,
  }) async {
    final trimmedSubject = subject.trim();
    final trimmedMessage = message.trim();

    if (trimmedSubject.isEmpty || trimmedMessage.isEmpty) {
      throw const AppException(
        AppStrings.helpdeskEmpty,
        code: 'helpdesk_empty',
      );
    }

    try {
      final user = _auth.currentUser;

      await _firestore.collection('support_tickets').add({
        'uid': user?.uid,
        'email': user?.email,
        'subject': trimmedSubject,
        'message': trimmedMessage,
        'status': 'open',
        'priority': 'normal',
        'source': 'mobile_app',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logHelpdeskTicketFailed,
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        'Destek talebi gönderilemedi. Bağlantınızı kontrol edip tekrar deneyin.',
        cause: error,
        stackTrace: stackTrace,
        code: 'helpdesk_ticket_failed',
      );
    }
  }
}
