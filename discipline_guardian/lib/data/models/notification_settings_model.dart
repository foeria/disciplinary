/// 通知设置模型（对应 notification_settings 单行记录）。
class NotificationSettingsModel {
  final String id;
  final bool reminderEnabled;
  final int reminderMinutes;
  final bool liveActivityEnabled;
  final bool soundEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final DateTime updatedAt;

  const NotificationSettingsModel({
    required this.id,
    required this.reminderEnabled,
    required this.reminderMinutes,
    required this.liveActivityEnabled,
    required this.soundEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.updatedAt,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      id: map['id'] as String,
      reminderEnabled: ((map['reminder_enabled'] as int?) ?? 1) == 1,
      reminderMinutes: (map['reminder_minutes'] as int?) ?? 5,
      liveActivityEnabled: ((map['live_activity_enabled'] as int?) ?? 1) == 1,
      soundEnabled: ((map['sound_enabled'] as int?) ?? 1) == 1,
      quietHoursStart: map['quiet_hours_start'] as String?,
      quietHoursEnd: map['quiet_hours_end'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_minutes': reminderMinutes,
      'live_activity_enabled': liveActivityEnabled ? 1 : 0,
      'sound_enabled': soundEnabled ? 1 : 0,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationSettingsModel copyWith({
    String? id,
    bool? reminderEnabled,
    int? reminderMinutes,
    bool? liveActivityEnabled,
    bool? soundEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      liveActivityEnabled: liveActivityEnabled ?? this.liveActivityEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
