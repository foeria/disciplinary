/// whitelist 表 — 白名单应用（不受监控限制）
///
/// 字段说明：
///   id            TEXT PRIMARY KEY — UUID 字符串
///   app_name      TEXT             — 应用显示名称
///   package_name  TEXT UNIQUE      — 应用包名（唯一，防重复添加）
///   created_at    TEXT             — 添加时间 ISO-8601
///
/// 索引：
///   idx_whitelist_package — 按包名快速查找
class WhitelistTable {
  static const String tableName = 'whitelist';

  static const String columnId = 'id';
  static const String columnAppName = 'app_name';
  static const String columnPackageName = 'package_name';
  static const String columnCreatedAt = 'created_at';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnAppName TEXT NOT NULL,
      $columnPackageName TEXT NOT NULL UNIQUE,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';

  static const String createIndexPackage = '''
    CREATE INDEX idx_whitelist_package ON $tableName ($columnPackageName)
  ''';
}
