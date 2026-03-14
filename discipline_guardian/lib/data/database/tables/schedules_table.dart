/// schedules 表 — 监控时段配置
///
/// 设计：使用单条记录（id='default'）保存工作日/周末两组时段，
/// 与前端 SchedulePage 的状态结构完全对应。
///
/// 字段说明：
///   id              TEXT PRIMARY KEY  — 固定为 'default'
///   is_enabled      INTEGER DEFAULT 0 — 是否启用时段限制 (1=启用 0=关闭)
///   workday_start   TEXT DEFAULT '09:00' — 工作日开始时间 HH:mm
///   workday_end     TEXT DEFAULT '22:00' — 工作日结束时间 HH:mm
///   weekend_start   TEXT DEFAULT '08:00' — 周末开始时间 HH:mm
///   weekend_end     TEXT DEFAULT '23:00' — 周末结束时间 HH:mm
///   updated_at      TEXT               — 最后修改时间 ISO-8601
class SchedulesTable {
  static const String tableName = 'schedules';

  static const String columnId = 'id';
  static const String columnIsEnabled = 'is_enabled';
  static const String columnWorkdayStart = 'workday_start';
  static const String columnWorkdayEnd = 'workday_end';
  static const String columnWeekendStart = 'weekend_start';
  static const String columnWeekendEnd = 'weekend_end';
  static const String columnUpdatedAt = 'updated_at';

  /// 默认记录行 ID
  static const String defaultId = 'default';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnIsEnabled INTEGER NOT NULL DEFAULT 0,
      $columnWorkdayStart TEXT NOT NULL DEFAULT '09:00',
      $columnWorkdayEnd TEXT NOT NULL DEFAULT '22:00',
      $columnWeekendStart TEXT NOT NULL DEFAULT '08:00',
      $columnWeekendEnd TEXT NOT NULL DEFAULT '23:00',
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';

  /// 默认数据（第一次建库时插入）
  static Map<String, dynamic> get defaultRow {
    return {
      columnId: defaultId,
      columnIsEnabled: 0,
      columnWorkdayStart: '09:00',
      columnWorkdayEnd: '22:00',
      columnWeekendStart: '08:00',
      columnWeekendEnd: '23:00',
      columnUpdatedAt: DateTime.now().toIso8601String(),
    };
  }
}
