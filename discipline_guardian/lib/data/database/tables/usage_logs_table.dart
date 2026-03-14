/// usage_logs 表 — 每日应用使用记录
///
/// 字段说明：
///   id            TEXT PRIMARY KEY — UUID 字符串
///   app_id        TEXT             — 关联 apps.id（外键，级联删除）
///   date          TEXT             — 记录日期 YYYY-MM-DD
///   used_minutes  INTEGER DEFAULT 0 — 当日使用时长（分钟）
///   open_count    INTEGER DEFAULT 0 — 当日打开次数
///   unlock_count  INTEGER DEFAULT 0 — 当日解锁次数（因超时锁定后主动解锁）
///
/// 索引：
///   idx_usage_logs_date  — 按日期查询
///   idx_usage_logs_app   — 按应用查询
///   idx_usage_logs_app_date — 组合索引（唯一键，同一应用同一天只有一条记录）
class UsageLogsTable {
  static const String tableName = 'usage_logs';

  static const String columnId = 'id';
  static const String columnAppId = 'app_id';
  static const String columnDate = 'date';
  static const String columnUsedMinutes = 'used_minutes';
  static const String columnOpenCount = 'open_count';
  static const String columnUnlockCount = 'unlock_count';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnAppId TEXT NOT NULL,
      $columnDate TEXT NOT NULL,
      $columnUsedMinutes INTEGER NOT NULL DEFAULT 0,
      $columnOpenCount INTEGER NOT NULL DEFAULT 0,
      $columnUnlockCount INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($columnAppId) REFERENCES apps (id) ON DELETE CASCADE,
      UNIQUE ($columnAppId, $columnDate)
    )
  ''';

  static const String createIndexDate = '''
    CREATE INDEX idx_usage_logs_date ON $tableName ($columnDate)
  ''';

  static const String createIndexApp = '''
    CREATE INDEX idx_usage_logs_app ON $tableName ($columnAppId)
  ''';
}
