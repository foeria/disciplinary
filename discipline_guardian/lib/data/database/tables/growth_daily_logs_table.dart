/// growth_daily_logs 表 - 每日成长结算日志
class GrowthDailyLogsTable {
  static const String tableName = 'growth_daily_logs';

  static const String columnId = 'id';
  static const String columnDate = 'date';
  static const String columnGainedExp = 'gained_exp';
  static const String columnBaseExp = 'base_exp';
  static const String columnStreakBonusExp = 'streak_bonus_exp';
  static const String columnPlanBonusExp = 'plan_bonus_exp';
  static const String columnQualifiedAppsCount = 'qualified_apps_count';
  static const String columnFailedAppsCount = 'failed_apps_count';
  static const String columnRankAfterSettlement = 'rank_after_settlement';
  static const String columnGuardPointsAfterSettlement =
      'guard_points_after_settlement';
  static const String columnCreatedAt = 'created_at';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnDate TEXT NOT NULL UNIQUE,
      $columnGainedExp INTEGER NOT NULL DEFAULT 0,
      $columnBaseExp INTEGER NOT NULL DEFAULT 0,
      $columnStreakBonusExp INTEGER NOT NULL DEFAULT 0,
      $columnPlanBonusExp INTEGER NOT NULL DEFAULT 0,
      $columnQualifiedAppsCount INTEGER NOT NULL DEFAULT 0,
      $columnFailedAppsCount INTEGER NOT NULL DEFAULT 0,
      $columnRankAfterSettlement INTEGER NOT NULL DEFAULT 1,
      $columnGuardPointsAfterSettlement INTEGER NOT NULL DEFAULT 0,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';

  static const String createIndexDate = '''
    CREATE INDEX idx_growth_daily_logs_date ON $tableName ($columnDate)
  ''';

  static const String createIndexCreatedAt = '''
    CREATE INDEX idx_growth_daily_logs_created_at ON $tableName ($columnCreatedAt)
  ''';
}
