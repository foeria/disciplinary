/// 使用记录数据模型
class UsageLogModel {
  final String id;
  final String appId;
  final String date;
  final int usedMinutes;
  final int openCount;
  final int unlockCount;

  const UsageLogModel({
    required this.id,
    required this.appId,
    required this.date,
    required this.usedMinutes,
    this.openCount = 0,
    required this.unlockCount,
  });

  factory UsageLogModel.fromMap(Map<String, dynamic> map) {
    return UsageLogModel(
      id: map['id'] as String,
      appId: map['app_id'] as String,
      date: map['date'] as String,
      usedMinutes: map['used_minutes'] as int,
      openCount: (map['open_count'] as int?) ?? 0,
      unlockCount: (map['unlock_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_id': appId,
      'date': date,
      'used_minutes': usedMinutes,
      'open_count': openCount,
      'unlock_count': unlockCount,
    };
  }

  UsageLogModel copyWith({
    String? id,
    String? appId,
    String? date,
    int? usedMinutes,
    int? openCount,
    int? unlockCount,
  }) {
    return UsageLogModel(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      date: date ?? this.date,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      openCount: openCount ?? this.openCount,
      unlockCount: unlockCount ?? this.unlockCount,
    );
  }
}
