import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserMatrix {
  final String uid;
  final String email;
  final String displayName;
  final bool disabled;
  final bool isPremium;
  final bool isVip;
  final Map<String, int> qazaCounts;
  final int dhikrToday;
  final int streakDays;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final String premiumExpiresAt;
  final bool deviceBanned;
  final List<String> bannedDeviceIds;

  const AdminUserMatrix({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.disabled,
    required this.isPremium,
    required this.isVip,
    required this.qazaCounts,
    required this.dhikrToday,
    required this.streakDays,
    this.createdAt,
    this.lastSeenAt,
    required this.premiumExpiresAt,
    required this.deviceBanned,
    required this.bannedDeviceIds,
  });

  factory AdminUserMatrix.fromMap(Map<String, dynamic> map) {
    final progress = Map<String, dynamic>.from(map['progress'] as Map? ?? {});
    final countsRaw = Map<String, dynamic>.from(progress['qazaCounts'] as Map? ?? map['qazaCounts'] as Map? ?? {});

    return AdminUserMatrix(
      uid: (map['uid'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: (map['displayName'] ?? '').toString(),
      disabled: (map['disabled'] ?? false) as bool,
      isPremium: (map['isPremium'] ?? false) as bool,
      isVip: (map['isVip'] ?? false) as bool,
      qazaCounts: countsRaw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      dhikrToday: (progress['dhikrToday'] as num?)?.toInt() ?? (map['dhikrToday'] as num?)?.toInt() ?? 0,
      streakDays: (progress['streakDays'] as num?)?.toInt() ?? (map['streakDays'] as num?)?.toInt() ?? 0,
      createdAt: _toDate(map['createdAt']),
      lastSeenAt: _toDate(map['lastSeenAt']),
      premiumExpiresAt: (map['premiumExpiresAt'] ?? '').toString(),
      deviceBanned: (map['deviceBanned'] ?? false) as bool,
      bannedDeviceIds: (map['bannedDeviceIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  factory AdminUserMatrix.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminUserMatrix.fromMap({
      'uid': doc.id,
      ...data,
    });
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
