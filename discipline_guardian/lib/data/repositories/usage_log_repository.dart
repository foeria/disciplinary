import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/tables/usage_logs_table.dart';
import '../models/usage_log_model.dart';

/// 使用统计仓库。
class UsageLogRepository {
  UsageLogRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<void> saveDailyUsage(UsageLogModel model) async {
    final db = await _databaseHelper.database;
    await db.insert(
      UsageLogsTable.tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UsageLogModel?> getLogByAppAndDate({
    required String appId,
    required String date,
  }) async {
    final rows = await _databaseHelper.queryByCondition(
      UsageLogsTable.tableName,
      where:
          '${UsageLogsTable.columnAppId} = ? AND ${UsageLogsTable.columnDate} = ?',
      whereArgs: [appId, date],
    );
    if (rows.isEmpty) {
      return null;
    }
    return UsageLogModel.fromMap(rows.first);
  }

  Future<List<UsageLogModel>> getLogsByDate(String date) async {
    final rows = await _databaseHelper.queryByCondition(
      UsageLogsTable.tableName,
      where: '${UsageLogsTable.columnDate} = ?',
      whereArgs: [date],
      orderBy: '${UsageLogsTable.columnAppId} ASC',
    );
    return rows.map(UsageLogModel.fromMap).toList(growable: false);
  }

  Future<List<UsageLogModel>> getLogsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final rows = await _databaseHelper.queryByCondition(
      UsageLogsTable.tableName,
      where: '${UsageLogsTable.columnDate} >= ? AND ${UsageLogsTable.columnDate} <= ?',
      whereArgs: [startDate, endDate],
      orderBy: '${UsageLogsTable.columnDate} ASC',
    );
    return rows.map(UsageLogModel.fromMap).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getAppRankingByDateRange({
    required String startDate,
    required String endDate,
    int limit = 10,
  }) async {
    final db = await _databaseHelper.database;
    return db.rawQuery(
      '''
      SELECT
        a.id AS app_id,
        a.app_name AS app_name,
        a.package_name AS package_name,
        a.installed_at AS installed_at,
        a.is_hundred_day_plan AS is_hundred_day_plan,
        COALESCE(SUM(u.used_minutes), 0) AS total_used_minutes,
        COALESCE(SUM(u.open_count), 0) AS total_open_count,
        COALESCE(SUM(u.unlock_count), 0) AS total_unlock_count
      FROM apps a
      LEFT JOIN usage_logs u
        ON a.id = u.app_id
        AND u.date >= ?
        AND u.date <= ?
      WHERE a.is_monitored = 1
      GROUP BY a.id, a.app_name, a.package_name, a.installed_at, a.is_hundred_day_plan
      ORDER BY total_used_minutes DESC
      LIMIT ?
      ''',
      [startDate, endDate, limit],
    );
  }

  Future<void> incrementUnlockCount({
    required String appId,
    required String date,
    required int usedMinutes,
  }) async {
    final existing = await getLogByAppAndDate(appId: appId, date: date);
    await saveDailyUsage(
      (existing ??
              UsageLogModel(
                id: '${appId}_$date',
                appId: appId,
                date: date,
                usedMinutes: usedMinutes,
                unlockCount: 0,
              ))
          .copyWith(
        usedMinutes: usedMinutes,
        unlockCount: (existing?.unlockCount ?? 0) + 1,
      ),
    );
  }
}
