/// 监控时段配置模型（对应 schedules 单行记录）。
class ScheduleSettingsModel {
  final String id;
  final bool isEnabled;
  final String workdayStart;
  final String workdayEnd;
  final String weekendStart;
  final String weekendEnd;
  final DateTime updatedAt;

  const ScheduleSettingsModel({
    required this.id,
    required this.isEnabled,
    required this.workdayStart,
    required this.workdayEnd,
    required this.weekendStart,
    required this.weekendEnd,
    required this.updatedAt,
  });

  factory ScheduleSettingsModel.fromMap(Map<String, dynamic> map) {
    return ScheduleSettingsModel(
      id: map['id'] as String,
      isEnabled: ((map['is_enabled'] as int?) ?? 0) == 1,
      workdayStart: map['workday_start'] as String,
      workdayEnd: map['workday_end'] as String,
      weekendStart: map['weekend_start'] as String,
      weekendEnd: map['weekend_end'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_enabled': isEnabled ? 1 : 0,
      'workday_start': workdayStart,
      'workday_end': workdayEnd,
      'weekend_start': weekendStart,
      'weekend_end': weekendEnd,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ScheduleSettingsModel copyWith({
    String? id,
    bool? isEnabled,
    String? workdayStart,
    String? workdayEnd,
    String? weekendStart,
    String? weekendEnd,
    DateTime? updatedAt,
  }) {
    return ScheduleSettingsModel(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      workdayStart: workdayStart ?? this.workdayStart,
      workdayEnd: workdayEnd ?? this.workdayEnd,
      weekendStart: weekendStart ?? this.weekendStart,
      weekendEnd: weekendEnd ?? this.weekendEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
