import 'package:cloud_firestore/cloud_firestore.dart';

import 'functions_service.dart';

class AiAutopilotService {
  AiAutopilotService({
    FirebaseFirestore? firestore,
    FunctionsService? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FunctionsService();

  final FirebaseFirestore _firestore;
  final FunctionsService _functions;

  Stream<List<Map<String, dynamic>>> watchAiLogs() {
    return _firestore
        .collection('ai_action_logs')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> watchDailyContent() {
    return _firestore
        .collection('daily_content')
        .orderBy('date', descending: true)
        .limit(60)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<Map<String, dynamic>> analyzeDua({
    required String duaId,
    required String text,
  }) {
    return _functions.analyzeDuaText(
      duaId: duaId,
      text: text,
    );
  }

  Future<Map<String, dynamic>> generateDailyContent(String theme) {
    return _functions.generateDailyIslamicContent(theme: theme);
  }

  Future<Map<String, dynamic>> generateDashboardSummary() {
    return _functions.generateDashboardAiSummary();
  }
}
