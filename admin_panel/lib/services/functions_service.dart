import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  FunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> assertAdmin() async {
    final result = await _functions.httpsCallable('assertGodModeAdmin').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Map<String, dynamic>>> listAuthUsers({
    int limit = 100,
    String? pageToken,
  }) async {
    final result = await _functions.httpsCallable('listAuthUsers').call({
      'limit': limit,
      'pageToken': pageToken,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final users = data['users'] as List<dynamic>? ?? [];
    return users.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> updateUserGodMode({
    required String uid,
    required bool isPremium,
    required bool isVip,
    required int dhikrToday,
    required int streakDays,
    required Map<String, int> qazaCounts,
    required String premiumExpiresAt,
    required bool deviceBanned,
    required List<String> bannedDeviceIds,
  }) async {
    await _functions.httpsCallable('updateUserGodMode').call({
      'uid': uid,
      'isPremium': isPremium,
      'isVip': isVip,
      'dhikrToday': dhikrToday,
      'streakDays': streakDays,
      'qazaCounts': qazaCounts,
      'premiumExpiresAt': premiumExpiresAt,
      'deviceBanned': deviceBanned,
      'bannedDeviceIds': bannedDeviceIds,
    });
  }

  Future<void> hardDeleteUser(String uid) async {
    await _functions.httpsCallable('hardDeleteUser').call({'uid': uid});
  }

  Future<String> resetUserPassword(String email) async {
    final result = await _functions.httpsCallable('resetUserPassword').call({'email': email});
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['link'] ?? '').toString();
  }

  Future<void> banUserDevice({
    required String uid,
    required String deviceId,
  }) async {
    await _functions.httpsCallable('banUserDevice').call({
      'uid': uid,
      'deviceId': deviceId,
    });
  }

  Future<Map<String, dynamic>> analyzeDuaText({
    required String duaId,
    required String text,
  }) async {
    final result = await _functions.httpsCallable('analyzeDuaText').call({
      'duaId': duaId,
      'text': text,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> generateDailyIslamicContent({
    required String theme,
  }) async {
    final result = await _functions.httpsCallable('generateDailyIslamicContent').call({
      'theme': theme,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> generateDashboardAiSummary() async {
    final result = await _functions.httpsCallable('generateDashboardAiSummary').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> publishKillSwitchConfig(Map<String, dynamic> config) async {
    await _functions.httpsCallable('publishKillSwitchConfig').call(config);
  }

  Future<void> publishRemoteConfigValues(Map<String, dynamic> values) async {
    await _functions.httpsCallable('publishRemoteConfigValues').call({
      'values': values,
    });
  }
}
