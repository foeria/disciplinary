/// settings 表 — 用户配置键值对
///
/// 字段说明：
///   key        TEXT PRIMARY KEY — 配置键名，预定义值见常量
///   value      TEXT             — 配置值（以字符串存储）
///   updated_at TEXT             — 最后修改时间 ISO-8601
///
/// 预定义键：
///   unlock_method  解锁方式：question
///   unlock_question_count 知识问答解锁所需题数
///   theme          主题颜色：pink / blue / lavender / mint / yellow / purple
///   password_hash  密码哈希（BCrypt），unlock_method=password 时使用
///   delay_minutes  延迟解锁等待分钟数，unlock_method=delay 时使用
///   unlock_extension_minutes 解锁后延长可用时长（分钟）
///   reset_strategy 使用时间重置策略：daily / weekly（暂未开放）
///   onboarding_completed 首次引导是否已经完成
class SettingsTable {
  static const String tableName = 'settings';

  static const String columnKey = 'key';
  static const String columnValue = 'value';
  static const String columnUpdatedAt = 'updated_at';

  // 预定义键名
  static const String keyUnlockMethod = 'unlock_method';
  static const String keyUnlockQuestionCount = 'unlock_question_count';
  static const String keyTheme = 'theme';
  static const String keyPasswordHash = 'password_hash';
  static const String keyDelayMinutes = 'delay_minutes';
  static const String keyUnlockExtensionMinutes = 'unlock_extension_minutes';
  static const String keyResetStrategy = 'reset_strategy';
  static const String keyWhitelistEnabled = 'whitelist_enabled';
  static const String keyOnboardingCompleted = 'onboarding_completed';

  // unlock_method 合法值
  static const String methodQuestion = 'question';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnKey TEXT PRIMARY KEY,
      $columnValue TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';

  /// 默认数据（第一次建库时插入）
  static List<Map<String, dynamic>> get defaultRows {
    final now = DateTime.now().toIso8601String();
    return [
      {
        columnKey: keyUnlockMethod,
        columnValue: methodQuestion,
        columnUpdatedAt: now,
      },
      {
        columnKey: keyUnlockQuestionCount,
        columnValue: '3',
        columnUpdatedAt: now,
      },
      {columnKey: keyTheme, columnValue: 'pink', columnUpdatedAt: now},
      {columnKey: keyDelayMinutes, columnValue: '5', columnUpdatedAt: now},
      {
        columnKey: keyUnlockExtensionMinutes,
        columnValue: '15',
        columnUpdatedAt: now,
      },
      {columnKey: keyResetStrategy, columnValue: 'daily', columnUpdatedAt: now},
      {columnKey: keyWhitelistEnabled, columnValue: '0', columnUpdatedAt: now},
      {
        columnKey: keyOnboardingCompleted,
        columnValue: '0',
        columnUpdatedAt: now,
      },
    ];
  }
}
