import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/kill_switch_config.dart';
import 'functions_service.dart';

class KillSwitchService {
  KillSwitchService({
    FirebaseFirestore? firestore,
    FunctionsService? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FunctionsService();

  final FirebaseFirestore _firestore;
  final FunctionsService _functions;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('admin_settings').doc('kill_switch');

  Stream<KillSwitchConfig> watchConfig() {
    return _ref.snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return KillSwitchConfig.defaults();
      return KillSwitchConfig.fromMap(data);
    });
  }

  Future<void> publish(KillSwitchConfig config) async {
    final next = config.copyWith(updatedAt: DateTime.now());

    await _ref.set(next.toMap(), SetOptions(merge: true));
    await _functions.publishKillSwitchConfig(next.toMap());
  }
}
