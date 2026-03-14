/// notification_settings 表 — 通知设置
///
/// 设计：使用单条记录（id='default'）保存所有通知配置，
/// 与前端 NotificationPage 的状态结构完全对应。
///
/// 字段说明：
///   id                    TEXT PRIMARY KEY  — 固定为 'default'
///   reminder_enabled      INTEGER DEFAULT 1 — 使用提醒总开关 (1=开 0=关)
///   reminder_minutes      INTEGER DEFAULT 5 — 提前提醒时间（分钟）：5 / 3 / 1
///   live_activity_enabled INTEGER DEFAULT 1 — 灵动岛实时活动开关（iOS）
///   sound_enabled         INTEGER DEFAULT 1 — 解锁提示音开关
///   quiet_hours_start     TEXT              — 免打扰开始时间 HH:mm（NULL=未启用）
///   quiet_hours_end       TEXT              — 免打扰结束时间 HH:mm（NULL=未启用）
///   updated_at            TEXT              — 最后修改时间 ISO-8601
class NotificationSettingsTable {
  static const String tableName = 'notification_settings';

  static const String columnId = 'id';
  static const String columnReminderEnabled = 'reminder_enabled';
  static const String columnReminderMinutes = 'reminder_minutes';
  static const String columnLiveActivityEnabled = 'live_activity_enabled';
  static const String columnSoundEnabled = 'sound_enabled';
  static const String columnQuietHoursStart = 'quiet_hours_start';
  static const String columnQuietHoursEnd = 'quiet_hours_end';
  static const String columnUpdatedAt = 'updated_at';

  /// 默认记录行 ID
  static const String defaultId = 'default';

  /// reminder_minutes 允许的值
  static const List<int> validReminderMinutes = [1, 3, 5];

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnReminderEnabled INTEGER NOT NULL DEFAULT 1,
      $columnReminderMinutes INTEGER NOT NULL DEFAULT 5,
      $columnLiveActivityEnabled INTEGER NOT NULL DEFAULT 1,
      $columnSoundEnabled INTEGER NOT NULL DEFAULT 1,
      $columnQuietHoursStart TEXT,
      $columnQuietHoursEnd TEXT,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';

  /// 默认数据（第一次建库时插入）
  static Map<String, dynamic> get defaultRow {
    return {
      columnId: defaultId,
      columnReminderEnabled: 1,
      columnReminderMinutes: 5,
      columnLiveActivityEnabled: 1,
      columnSoundEnabled: 1,
      columnQuietHoursStart: null,
      columnQuietHoursEnd: null,
      columnUpdatedAt: DateTime.now().toIso8601String(),
    };
  }
}
