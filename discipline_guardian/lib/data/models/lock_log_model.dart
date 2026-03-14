/// 锁定日志模型。
class LockLogModel {
  final String id;
  final String? appId;
  final DateTime lockedAt;
  final DateTime? unlockedAt;
  final String? unlockMethod;
  final bool isCompleted;

  const LockLogModel({
    required this.id,
    required this.appId,
    required this.lockedAt,
    this.unlockedAt,
    this.unlockMethod,
    required this.isCompleted,
  });

  factory LockLogModel.fromMap(Map<String, dynamic> map) {
    return LockLogModel(
      id: map['id'] as String,
      appId: map['app_id'] as String?,
      lockedAt: DateTime.parse(map['locked_at'] as String),
      unlockedAt: (map['unlocked_at'] as String?) != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
      unlockMethod: map['unlock_method'] as String?,
      isCompleted: ((map['is_completed'] as int?) ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_id': appId,
      'locked_at': lockedAt.toIso8601String(),
      'unlocked_at': unlockedAt?.toIso8601String(),
      'unlock_method': unlockMethod,
      'is_completed': isCompleted ? 1 : 0,
    };
  }
}
