/// apps 表 — 监控应用
///
/// 字段说明：
///   id                   TEXT PRIMARY KEY   — UUID 字符串
///   app_name             TEXT               — 应用显示名称
///   package_name         TEXT UNIQUE        — 应用包名
///   icon_path            TEXT               — 图标路径（可为空）
///   daily_limit_minutes  INTEGER DEFAULT 60 — 每日使用上限（分钟）
///   used_minutes_today   INTEGER DEFAULT 0  — 今日已用时间（分钟），每日重置
///   is_monitored         INTEGER DEFAULT 1  — 是否处于监控中 (1=是 0=否)
///   is_locked            INTEGER DEFAULT 0  — 当前是否被锁定 (1=是 0=否)
///   unlock_limit_override_minutes INTEGER   — 当日解锁后临时放宽的分钟上限
///   unlock_limit_override_date    TEXT      — 临时上限生效日期 yyyy-MM-dd
///   created_at           TEXT               — 创建时间 ISO-8601
///   updated_at           TEXT               — 最后修改时间 ISO-8601
class AppsTable {
  static const String tableName = 'apps';

  static const String columnId = 'id';
  static const String columnAppName = 'app_name';
  static const String columnPackageName = 'package_name';
  static const String columnIconPath = 'icon_path';
  static const String columnDailyLimitMinutes = 'daily_limit_minutes';
  static const String columnUsedMinutesToday = 'used_minutes_today';
  static const String columnIsMonitored = 'is_monitored';
  static const String columnIsLocked = 'is_locked';
  static const String columnIsHundredDayPlan = 'is_hundred_day_plan';
  static const String columnPlanId = 'plan_id';
  static const String columnInstalledAt = 'installed_at';
  static const String columnUnlockLimitOverrideMinutes =
      'unlock_limit_override_minutes';
  static const String columnUnlockLimitOverrideDate =
      'unlock_limit_override_date';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnAppName TEXT NOT NULL,
      $columnPackageName TEXT NOT NULL UNIQUE,
      $columnIconPath TEXT,
      $columnDailyLimitMinutes INTEGER NOT NULL DEFAULT 60,
      $columnUsedMinutesToday INTEGER NOT NULL DEFAULT 0,
      $columnIsMonitored INTEGER NOT NULL DEFAULT 1,
      $columnIsLocked INTEGER NOT NULL DEFAULT 0,
      $columnIsHundredDayPlan INTEGER NOT NULL DEFAULT 0,
      $columnPlanId TEXT,
      $columnInstalledAt TEXT,
      $columnUnlockLimitOverrideMinutes INTEGER,
      $columnUnlockLimitOverrideDate TEXT,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';

  static const String createIndexPackage = '''
    CREATE INDEX idx_apps_package ON $tableName ($columnPackageName)
  ''';
}
