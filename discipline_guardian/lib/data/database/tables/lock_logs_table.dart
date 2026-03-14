/// lock_logs 表 — 应用锁定/解锁日志
///
/// 字段说明：
///   id             TEXT PRIMARY KEY — UUID 字符串
///   app_id         TEXT             — 关联 apps.id（外键，应用删除时置 NULL）
///   locked_at      TEXT             — 锁定时间 ISO-8601
///   unlocked_at    TEXT             — 解锁时间 ISO-8601（未解锁时为 NULL）
///   unlock_method  TEXT             — 使用的解锁方式（password/question/math/delay）
///   is_completed   INTEGER DEFAULT 0 — 是否成功解锁 (1=已解锁 0=未解锁/放弃)
///
/// 索引：
///   idx_lock_logs_app       — 按应用查询
///   idx_lock_logs_locked_at — 按时间查询
class LockLogsTable {
  static const String tableName = 'lock_logs';

  static const String columnId = 'id';
  static const String columnAppId = 'app_id';
  static const String columnLockedAt = 'locked_at';
  static const String columnUnlockedAt = 'unlocked_at';
  static const String columnUnlockMethod = 'unlock_method';
  static const String columnIsCompleted = 'is_completed';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnAppId TEXT,
      $columnLockedAt TEXT NOT NULL,
      $columnUnlockedAt TEXT,
      $columnUnlockMethod TEXT,
      $columnIsCompleted INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY ($columnAppId) REFERENCES apps (id) ON DELETE SET NULL
    )
  ''';

  static const String createIndexApp = '''
    CREATE INDEX idx_lock_logs_app ON $tableName ($columnAppId)
  ''';

  static const String createIndexLockedAt = '''
    CREATE INDEX idx_lock_logs_locked_at ON $tableName ($columnLockedAt)
  ''';
}
