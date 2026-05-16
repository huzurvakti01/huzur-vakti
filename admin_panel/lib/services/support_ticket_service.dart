import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketService {
  SupportTicketService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> watchTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> reply({
    required String ticketId,
    required String reply,
    required String adminEmail,
  }) async {
    await _firestore.collection('support_tickets').doc(ticketId).set({
      'adminReply': reply.trim(),
      'status': 'answered',
      'answeredBy': adminEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('admin_audit_logs').add({
      'type': 'support_ticket_answered',
      'ticketId': ticketId,
      'adminEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> close({
    required String ticketId,
    required String adminEmail,
  }) async {
    await _firestore.collection('support_tickets').doc(ticketId).set({
      'status': 'closed',
      'closedBy': adminEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
