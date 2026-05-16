import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/dua_request.dart';

class DuaBrotherhoodService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  DuaBrotherhoodService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _duas =>
      firestore.collection('dua_requests');

  Future<User> ensureUser() async {
    final current = auth.currentUser;
    if (current != null) return current;

    final cred = await auth.signInAnonymously();
    if (cred.user == null) throw Exception('Anonim kullanıcı oluşturulamadı.');
    return cred.user!;
  }

  Future<bool> isBanned() async {
    final user = await ensureUser();
    final doc = await firestore.collection('banned_users').doc(user.uid).get();
    return doc.exists;
  }

  Stream<List<DuaRequest>> watchDuas() async* {
    await ensureUser();

    await for (final snap in _duas
        .where('isReported', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()) {
      yield snap.docs.map(DuaRequest.fromDoc).toList();
    }
  }

  Future<void> create({
    required String text,
    required String category,
  }) async {
    final user = await ensureUser();

    if (await isBanned()) {
      throw Exception('Bu cihaz/kullanıcı topluluk paylaşımından engellenmiş.');
    }

    final clean = _sanitize(text);
    if (clean.length < 8) throw Exception('Dua isteği en az 8 karakter olmalı.');

    await _duas.add({
      'text': clean.length > 600 ? clean.substring(0, 600) : clean,
      'category': category.trim().isEmpty ? 'Genel' : category.trim(),
      'ownerUid': user.uid,
      'aminCount': 0,
      'isReported': false,
      'reportCount': 0,
      'blockedByOwnerUids': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> amin(String id) async {
    await _duas.doc(id).update({'aminCount': FieldValue.increment(1)});
  }

  Future<void> report(String id, String reason) async {
    final user = await ensureUser();
    await firestore.collection('dua_reports').add({
      'requestId': id,
      'reason': reason.trim().isEmpty ? 'Uygunsuz içerik' : reason.trim(),
      'reporterUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _duas.doc(id).update({
      'isReported': true,
      'reportCount': FieldValue.increment(1),
      'lastReportedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String requestId,
    required String targetUid,
  }) async {
    final user = await ensureUser();

    if (targetUid.isEmpty) return;

    await firestore.collection('dua_blocks').add({
      'requestId': requestId,
      'blockedUid': targetUid,
      'blockerUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _duas.doc(requestId).update({
      'blockedByOwnerUids': FieldValue.arrayUnion([user.uid]),
    });
  }

  String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
