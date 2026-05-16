import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cms_content.dart';

class CmsService {
  CmsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<CmsContent>> watchContent() {
    return _firestore
        .collection('cms_content')
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CmsContent.fromDoc).toList());
  }

  Future<void> upsertContent({
    required String id,
    required String title,
    required String body,
    required String type,
    required String adminEmail,
  }) async {
    await _firestore.collection('cms_content').doc(id).set({
      'title': title.trim(),
      'body': body.trim(),
      'type': type.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminEmail,
    }, SetOptions(merge: true));

    await _firestore.collection('admin_audit_logs').add({
      'type': 'cms_content_upserted',
      'contentId': id,
      'adminEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteContent({
    required String id,
    required String adminEmail,
  }) async {
    await _firestore.collection('cms_content').doc(id).delete();

    await _firestore.collection('admin_audit_logs').add({
      'type': 'cms_content_deleted',
      'contentId': id,
      'adminEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
