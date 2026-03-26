/// growth_app_logs 表 - 成长经验明细日志
class GrowthAppLogsTable {
  static const String tableName = 'growth_app_logs';

  static const String columnId = 'id';
  static const String columnDate = 'date';
  static const String columnAppId = 'app_id';
  static const String columnAppName = 'app_name';
  static const String columnPackageName = 'package_name';
  static const String columnPlanId = 'plan_id';
  static const String columnIsHundredDayPlan = 'is_hundred_day_plan';
  static const String columnLimitMinutes = 'limit_minutes';
  static const String columnUsedMinutes = 'used_minutes';
  static const String columnExpGained = 'exp_gained';
  static const String columnStatus = 'status';
  static const String columnReason = 'reason';
  static const String columnCreatedAt = 'created_at';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnDate TEXT NOT NULL,
      $columnAppId TEXT,
      $columnAppName TEXT NOT NULL,
      $columnPackageName TEXT NOT NULL,
      $columnPlanId TEXT,
      $columnIsHundredDayPlan INTEGER NOT NULL DEFAULT 0,
      $columnLimitMinutes INTEGER NOT NULL DEFAULT 0,
      $columnUsedMinutes INTEGER NOT NULL DEFAULT 0,
      $columnExpGained INTEGER NOT NULL DEFAULT 0,
      $columnStatus TEXT NOT NULL,
      $columnReason TEXT NOT NULL,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';

  static const String createIndexDate = '''
    CREATE INDEX idx_growth_app_logs_date ON $tableName ($columnDate)
  ''';

  static const String createIndexCreatedAt = '''
    CREATE INDEX idx_growth_app_logs_created_at ON $tableName ($columnCreatedAt)
  ''';

  static const String createIndexPackageDate = '''
    CREATE INDEX idx_growth_app_logs_package_date ON $tableName ($columnPackageName, $columnDate)
  ''';
}
