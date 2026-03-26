class GrowthDailyLogModel {
  final String id;
  final String date;
  final int gainedExp;
  final int baseExp;
  final int streakBonusExp;
  final int planBonusExp;
  final int qualifiedAppsCount;
  final int failedAppsCount;
  final int rankAfterSettlement;
  final int guardPointsAfterSettlement;
  final DateTime createdAt;

  const GrowthDailyLogModel({
    required this.id,
    required this.date,
    required this.gainedExp,
    required this.baseExp,
    required this.streakBonusExp,
    required this.planBonusExp,
    required this.qualifiedAppsCount,
    required this.failedAppsCount,
    required this.rankAfterSettlement,
    required this.guardPointsAfterSettlement,
    required this.createdAt,
  });

  factory GrowthDailyLogModel.fromMap(Map<String, dynamic> map) {
    return GrowthDailyLogModel(
      id: map['id'] as String,
      date: map['date'] as String,
      gainedExp: (map['gained_exp'] as int?) ?? 0,
      baseExp: (map['base_exp'] as int?) ?? 0,
      streakBonusExp: (map['streak_bonus_exp'] as int?) ?? 0,
      planBonusExp: (map['plan_bonus_exp'] as int?) ?? 0,
      qualifiedAppsCount: (map['qualified_apps_count'] as int?) ?? 0,
      failedAppsCount: (map['failed_apps_count'] as int?) ?? 0,
      rankAfterSettlement: (map['rank_after_settlement'] as int?) ?? 1,
      guardPointsAfterSettlement:
          (map['guard_points_after_settlement'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'gained_exp': gainedExp,
      'base_exp': baseExp,
      'streak_bonus_exp': streakBonusExp,
      'plan_bonus_exp': planBonusExp,
      'qualified_apps_count': qualifiedAppsCount,
      'failed_apps_count': failedAppsCount,
      'rank_after_settlement': rankAfterSettlement,
      'guard_points_after_settlement': guardPointsAfterSettlement,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
