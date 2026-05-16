import 'package:cloud_firestore/cloud_firestore.dart';

class DuaRequest {
  final String id;
  final String text;
  final String category;
  final String ownerUid;
  final int aminCount;
  final bool isReported;
  final DateTime createdAt;

  const DuaRequest({
    required this.id,
    required this.text,
    required this.category,
    required this.ownerUid,
    required this.aminCount,
    required this.isReported,
    required this.createdAt,
  });

  factory DuaRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    return DuaRequest(
      id: doc.id,
      text: (data['text'] ?? '').toString(),
      category: (data['category'] ?? 'Genel').toString(),
      ownerUid: (data['ownerUid'] ?? '').toString(),
      aminCount: (data['aminCount'] ?? 0) as int,
      isReported: (data['isReported'] ?? false) as bool,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
