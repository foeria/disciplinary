/// plans 表 — 用户创建的计划
class PlansTable {
  static const String tableName = 'plans';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnDurationDays = 'duration_days';
  static const String columnStartDate = 'start_date';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT NOT NULL,
      $columnDurationDays INTEGER NOT NULL DEFAULT 100,
      $columnStartDate TEXT NOT NULL,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';

  static const String createIndexUpdatedAt = '''
    CREATE INDEX idx_plans_updated_at ON $tableName ($columnUpdatedAt)
  ''';
}
