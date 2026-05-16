import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../models/qaza_progress.dart';

class CloudSyncService {
  CloudSyncService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool canSync(User? user) => user != null && !user.isAnonymous;

  DocumentReference<Map<String, dynamic>> progressRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cloud_sync')
        .doc('ibadah_progress');
  }

  Future<void> backupProgress({
    required QazaProgress progress,
    required User? user,
  }) async {
    if (!canSync(user)) {
      AppLogger.info(
        AppStrings.logCloudSyncSkipped,
        context: {'reason': 'signed_in_user_required'},
      );
      return;
    }

    try {
      final uid = user!.uid;

      await progressRef(uid).set({
        ...progress.toMap(),
        'uid': uid,
        'email': user.email,
        'schemaVersion': 2,
        'cloudUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'cloudSyncEnabled': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logCloudBackupFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'uid': user?.uid},
      );

      throw AppException(
        AppStrings.cloudBackupFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'cloud_sync_backup_failed',
      );
    }
  }

  Future<QazaProgress?> restoreProgress({
    required User? user,
  }) async {
    if (!canSync(user)) {
      AppLogger.info(
        AppStrings.logCloudSyncSkipped,
        context: {'reason': 'signed_in_user_required'},
      );
      return null;
    }

    try {
      final uid = user!.uid;
      final doc = await progressRef(uid).get();

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'cloudSyncEnabled': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!doc.exists || doc.data() == null) return null;

      return QazaProgress.fromMap(doc.data()!);
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logCloudRestoreFailed,
        error: error,
        stackTrace: stackTrace,
        context: {'uid': user?.uid},
      );

      throw AppException(
        AppStrings.cloudRestoreFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'cloud_sync_restore_failed',
      );
    }
  }
}
