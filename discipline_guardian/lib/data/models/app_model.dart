/// 应用数据模型
class AppModel {
  final String id;
  final String appName;
  final String packageName;
  final String? iconPath;
  final int dailyLimitMinutes;
  final int usedMinutesToday;
  final bool isMonitored;
  final bool isLocked;
  final bool isHundredDayPlan;
  final String? planId;
  final DateTime? installedAt;
  final DateTime? growthNormalJoinBonusAwardedAt;
  final DateTime? growthPlanStartedAt;
  final DateTime? growthPlanJoinBonusAwardedAt;
  final int? unlockLimitOverrideMinutes;
  final String? unlockLimitOverrideDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppModel({
    required this.id,
    required this.appName,
    required this.packageName,
    this.iconPath,
    required this.dailyLimitMinutes,
    this.usedMinutesToday = 0,
    required this.isMonitored,
    this.isLocked = false,
    this.isHundredDayPlan = false,
    this.planId,
    this.installedAt,
    this.growthNormalJoinBonusAwardedAt,
    this.growthPlanStartedAt,
    this.growthPlanJoinBonusAwardedAt,
    this.unlockLimitOverrideMinutes,
    this.unlockLimitOverrideDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppModel.fromMap(Map<String, dynamic> map) {
    return AppModel(
      id: map['id'] as String,
      appName: map['app_name'] as String,
      packageName: map['package_name'] as String,
      iconPath: map['icon_path'] as String?,
      dailyLimitMinutes: map['daily_limit_minutes'] as int,
      usedMinutesToday: (map['used_minutes_today'] as int?) ?? 0,
      isMonitored: (map['is_monitored'] as int) == 1,
      isLocked: ((map['is_locked'] as int?) ?? 0) == 1,
      isHundredDayPlan:
          ((map['is_hundred_day_plan'] as int?) ?? 0) == 1 ||
          (map['plan_id'] as String?) != null,
      planId: map['plan_id'] as String?,
      installedAt: (map['installed_at'] as String?) != null
          ? DateTime.parse(map['installed_at'] as String)
          : null,
      growthNormalJoinBonusAwardedAt:
          (map['growth_normal_join_bonus_awarded_at'] as String?) != null
              ? DateTime.parse(
                  map['growth_normal_join_bonus_awarded_at'] as String,
                )
              : null,
      growthPlanStartedAt: (map['growth_plan_started_at'] as String?) != null
          ? DateTime.parse(map['growth_plan_started_at'] as String)
          : null,
      growthPlanJoinBonusAwardedAt:
          (map['growth_plan_join_bonus_awarded_at'] as String?) != null
              ? DateTime.parse(
                  map['growth_plan_join_bonus_awarded_at'] as String,
                )
              : null,
      unlockLimitOverrideMinutes: map['unlock_limit_override_minutes'] as int?,
      unlockLimitOverrideDate: map['unlock_limit_override_date'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_name': appName,
      'package_name': packageName,
      'icon_path': iconPath,
      'daily_limit_minutes': dailyLimitMinutes,
      'used_minutes_today': usedMinutesToday,
      'is_monitored': isMonitored ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'is_hundred_day_plan': (planId != null || isHundredDayPlan) ? 1 : 0,
      'plan_id': planId,
      'installed_at': installedAt?.toIso8601String(),
      'growth_normal_join_bonus_awarded_at':
          growthNormalJoinBonusAwardedAt?.toIso8601String(),
      'growth_plan_started_at': growthPlanStartedAt?.toIso8601String(),
      'growth_plan_join_bonus_awarded_at':
          growthPlanJoinBonusAwardedAt?.toIso8601String(),
      'unlock_limit_override_minutes': unlockLimitOverrideMinutes,
      'unlock_limit_override_date': unlockLimitOverrideDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppModel copyWith({
    String? id,
    String? appName,
    String? packageName,
    String? iconPath,
    int? dailyLimitMinutes,
    int? usedMinutesToday,
    bool? isMonitored,
    bool? isLocked,
    bool? isHundredDayPlan,
    String? planId,
    DateTime? installedAt,
    DateTime? growthNormalJoinBonusAwardedAt,
    DateTime? growthPlanStartedAt,
    DateTime? growthPlanJoinBonusAwardedAt,
    int? unlockLimitOverrideMinutes,
    String? unlockLimitOverrideDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      iconPath: iconPath ?? this.iconPath,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      isMonitored: isMonitored ?? this.isMonitored,
      isLocked: isLocked ?? this.isLocked,
      isHundredDayPlan:
          isHundredDayPlan ?? ((planId ?? this.planId) != null || this.isHundredDayPlan),
      planId: planId ?? this.planId,
      installedAt: installedAt ?? this.installedAt,
      growthNormalJoinBonusAwardedAt: growthNormalJoinBonusAwardedAt ??
          this.growthNormalJoinBonusAwardedAt,
      growthPlanStartedAt: growthPlanStartedAt ?? this.growthPlanStartedAt,
      growthPlanJoinBonusAwardedAt:
          growthPlanJoinBonusAwardedAt ?? this.growthPlanJoinBonusAwardedAt,
      unlockLimitOverrideMinutes:
          unlockLimitOverrideMinutes ?? this.unlockLimitOverrideMinutes,
      unlockLimitOverrideDate:
          unlockLimitOverrideDate ?? this.unlockLimitOverrideDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
