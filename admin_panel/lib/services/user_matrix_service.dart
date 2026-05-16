import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_user_matrix.dart';
import 'functions_service.dart';

class UserMatrixService {
  UserMatrixService({
    FirebaseFirestore? firestore,
    FunctionsService? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FunctionsService();

  final FirebaseFirestore _firestore;
  final FunctionsService _functions;

  Stream<List<AdminUserMatrix>> watchFirestoreUsers({String search = ''}) {
    return _firestore
        .collection('users')
        .orderBy('lastSeenAt', descending: true)
        .limit(300)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs.map(AdminUserMatrix.fromDoc).toList();
      final needle = search.trim().toLowerCase();

      if (needle.isEmpty) return users;

      return users.where((user) {
        return user.uid.toLowerCase().contains(needle) ||
            user.email.toLowerCase().contains(needle) ||
            user.displayName.toLowerCase().contains(needle);
      }).toList();
    });
  }

  Future<List<AdminUserMatrix>> loadAuthUsers({String search = ''}) async {
    final raw = await _functions.listAuthUsers(limit: 100);
    final needle = search.trim().toLowerCase();

    return raw.map(AdminUserMatrix.fromMap).where((user) {
      if (needle.isEmpty) return true;
      return user.uid.toLowerCase().contains(needle) ||
          user.email.toLowerCase().contains(needle) ||
          user.displayName.toLowerCase().contains(needle);
    }).toList();
  }

  Future<void> updateUser(AdminUserMatrix user) async {
    await _functions.updateUserGodMode(
      uid: user.uid,
      isPremium: user.isPremium,
      isVip: user.isVip,
      dhikrToday: user.dhikrToday,
      streakDays: user.streakDays,
      qazaCounts: user.qazaCounts,
      premiumExpiresAt: user.premiumExpiresAt,
      deviceBanned: user.deviceBanned,
      bannedDeviceIds: user.bannedDeviceIds,
    );
  }

  Future<void> hardDelete(String uid) => _functions.hardDeleteUser(uid);

  Future<String> resetPassword(String email) => _functions.resetUserPassword(email);

  Future<void> banDevice({
    required String uid,
    required String deviceId,
  }) {
    return _functions.banUserDevice(uid: uid, deviceId: deviceId);
  }
}
