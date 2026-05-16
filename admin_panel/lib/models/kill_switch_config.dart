class KillSwitchConfig {
  final bool forceUpdateEnabled;
  final int minVersionCode;
  final bool aiChatEnabled;
  final bool zikirmatikEnabled;
  final bool duaCommunityEnabled;
  final bool premiumLibraryEnabled;
  final bool cloudSyncEnabled;
  final DateTime? updatedAt;

  const KillSwitchConfig({
    required this.forceUpdateEnabled,
    required this.minVersionCode,
    required this.aiChatEnabled,
    required this.zikirmatikEnabled,
    required this.duaCommunityEnabled,
    required this.premiumLibraryEnabled,
    required this.cloudSyncEnabled,
    this.updatedAt,
  });

  factory KillSwitchConfig.defaults() {
    return const KillSwitchConfig(
      forceUpdateEnabled: false,
      minVersionCode: 1,
      aiChatEnabled: true,
      zikirmatikEnabled: true,
      duaCommunityEnabled: true,
      premiumLibraryEnabled: true,
      cloudSyncEnabled: true,
    );
  }

  factory KillSwitchConfig.fromMap(Map<String, dynamic> map) {
    return KillSwitchConfig(
      forceUpdateEnabled: (map['forceUpdateEnabled'] ?? false) as bool,
      minVersionCode: (map['minVersionCode'] as num?)?.toInt() ?? 1,
      aiChatEnabled: (map['aiChatEnabled'] ?? true) as bool,
      zikirmatikEnabled: (map['zikirmatikEnabled'] ?? true) as bool,
      duaCommunityEnabled: (map['duaCommunityEnabled'] ?? true) as bool,
      premiumLibraryEnabled: (map['premiumLibraryEnabled'] ?? true) as bool,
      cloudSyncEnabled: (map['cloudSyncEnabled'] ?? true) as bool,
      updatedAt: map['updatedAt'] is String ? DateTime.tryParse(map['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'forceUpdateEnabled': forceUpdateEnabled,
      'minVersionCode': minVersionCode,
      'aiChatEnabled': aiChatEnabled,
      'zikirmatikEnabled': zikirmatikEnabled,
      'duaCommunityEnabled': duaCommunityEnabled,
      'premiumLibraryEnabled': premiumLibraryEnabled,
      'cloudSyncEnabled': cloudSyncEnabled,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  KillSwitchConfig copyWith({
    bool? forceUpdateEnabled,
    int? minVersionCode,
    bool? aiChatEnabled,
    bool? zikirmatikEnabled,
    bool? duaCommunityEnabled,
    bool? premiumLibraryEnabled,
    bool? cloudSyncEnabled,
    DateTime? updatedAt,
  }) {
    return KillSwitchConfig(
      forceUpdateEnabled: forceUpdateEnabled ?? this.forceUpdateEnabled,
      minVersionCode: minVersionCode ?? this.minVersionCode,
      aiChatEnabled: aiChatEnabled ?? this.aiChatEnabled,
      zikirmatikEnabled: zikirmatikEnabled ?? this.zikirmatikEnabled,
      duaCommunityEnabled: duaCommunityEnabled ?? this.duaCommunityEnabled,
      premiumLibraryEnabled: premiumLibraryEnabled ?? this.premiumLibraryEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
