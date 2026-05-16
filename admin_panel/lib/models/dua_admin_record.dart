import 'package:cloud_firestore/cloud_firestore.dart';

class DuaAdminRecord {
  final String id;
  final String uid;
  final String text;
  final String category;
  final bool reported;
  final int aminCount;
  final DateTime createdAt;

  const DuaAdminRecord({
    required this.id,
    required this.uid,
    required this.text,
    required this.category,
    required this.reported,
    required this.aminCount,
    required this.createdAt,
  });

  factory DuaAdminRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return DuaAdminRecord(
      id: doc.id,
      uid: (data['uid'] ?? data['userId'] ?? data['authorUid'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      reported: (data['isReported'] ?? data['reported'] ?? false) as bool,
      aminCount: (data['aminCount'] as num?)?.toInt() ?? 0,
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
