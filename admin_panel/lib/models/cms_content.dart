import 'package:cloud_firestore/cloud_firestore.dart';

class CmsContent {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime? updatedAt;

  const CmsContent({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.updatedAt,
  });

  factory CmsContent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CmsContent(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      type: (data['type'] ?? 'text').toString(),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
