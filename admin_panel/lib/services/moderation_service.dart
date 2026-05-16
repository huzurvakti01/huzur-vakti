import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dua_admin_record.dart';

class ModerationService {
  ModerationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<DuaAdminRecord>> watchAllDuas({String search = ''}) {
    return _firestore
        .collection('dua_requests')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) {
      final duas = snapshot.docs.map(DuaAdminRecord.fromDoc).toList();
      final needle = search.trim().toLowerCase();

      if (needle.isEmpty) return duas;

      return duas.where((dua) {
        return dua.text.toLowerCase().contains(needle) ||
            dua.uid.toLowerCase().contains(needle) ||
            dua.category.toLowerCase().contains(needle);
      }).toList();
    });
  }

  Future<void> updateDua({
    required String id,
    required String text,
    required String adminEmail,
  }) async {
    await _firestore.collection('dua_requests').doc(id).set({
      'text': text.trim(),
      'editedByAdmin': true,
      'editedBy': adminEmail,
      'editedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('admin_audit_logs').add({
      'type': 'dua_edited',
      'duaId': id,
      'adminEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDua({
    required String id,
    required String adminEmail,
  }) async {
    await _firestore.collection('dua_requests').doc(id).delete();

    await _firestore.collection('admin_audit_logs').add({
      'type': 'dua_deleted',
      'duaId': id,
      'adminEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
