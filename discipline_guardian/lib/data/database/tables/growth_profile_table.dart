/// growth_profile 表 - 用户成长档案
class GrowthProfileTable {
  static const String tableName = 'growth_profile';

  static const String columnId = 'id';
  static const String columnTotalExp = 'total_exp';
  static const String columnCurrentRankIndex = 'current_rank_index';
  static const String columnCurrentRankName = 'current_rank_name';
  static const String columnGuardPoints = 'guard_points';
  static const String columnGuardStars = 'guard_stars';
  static const String columnCurrentStreakDays = 'current_streak_days';
  static const String columnBestStreakDays = 'best_streak_days';
  static const String columnLastSettlementDate = 'last_settlement_date';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnTotalExp INTEGER NOT NULL DEFAULT 0,
      $columnCurrentRankIndex INTEGER NOT NULL DEFAULT 1,
      $columnCurrentRankName TEXT NOT NULL,
      $columnGuardPoints INTEGER NOT NULL DEFAULT 0,
      $columnGuardStars INTEGER NOT NULL DEFAULT 0,
      $columnCurrentStreakDays INTEGER NOT NULL DEFAULT 0,
      $columnBestStreakDays INTEGER NOT NULL DEFAULT 0,
      $columnLastSettlementDate TEXT,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';
}
