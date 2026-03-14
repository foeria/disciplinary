import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../database/tables/lock_logs_table.dart';
import '../models/lock_log_model.dart';

/// 锁定日志数据仓库。
class LockLogRepository {
  LockLogRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  Future<LockLogModel> createLockLog({
    required String appId,
    required String unlockMethod,
  }) async {
    final model = LockLogModel(
      id: _uuid.v4(),
      appId: appId,
      lockedAt: DateTime.now(),
      unlockMethod: unlockMethod,
      isCompleted: false,
    );

    await _databaseHelper.insert(LockLogsTable.tableName, model.toMap());
    return model;
  }

  Future<void> markUnlockCompleted({
    required String logId,
  }) async {
    await _databaseHelper.update(
      LockLogsTable.tableName,
      {
        LockLogsTable.columnUnlockedAt: DateTime.now().toIso8601String(),
        LockLogsTable.columnIsCompleted: 1,
      },
      where: '${LockLogsTable.columnId} = ?',
      whereArgs: [logId],
    );
  }

  Future<List<LockLogModel>> getRecentLogs({
    String? appId,
    int limit = 50,
  }) async {
    final db = await _databaseHelper.database;
    final hasAppId = appId != null && appId.isNotEmpty;
    final rows = await db.query(
      LockLogsTable.tableName,
      where: hasAppId ? '${LockLogsTable.columnAppId} = ?' : null,
      whereArgs: hasAppId ? [appId] : null,
      orderBy: '${LockLogsTable.columnLockedAt} DESC',
      limit: limit,
    );
    return rows.map(LockLogModel.fromMap).toList(growable: false);
  }

  Future<Map<String, int>> getSummaryByLockedDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_lock_count,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) AS completed_unlock_count
      FROM ${LockLogsTable.tableName}
      WHERE substr(${LockLogsTable.columnLockedAt}, 1, 10) >= ?
        AND substr(${LockLogsTable.columnLockedAt}, 1, 10) <= ?
      ''',
      [startDate, endDate],
    );

    final row = rows.isEmpty ? const <String, Object?>{} : rows.first;
    return {
      'total_lock_count': (row['total_lock_count'] as int?) ?? 0,
      'completed_unlock_count': (row['completed_unlock_count'] as int?) ?? 0,
    };
  }

  Future<int> getAverageUnlockMinutesByLockedDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        AVG((julianday(${LockLogsTable.columnUnlockedAt}) - julianday(${LockLogsTable.columnLockedAt})) * 24 * 60) AS avg_unlock_minutes
      FROM ${LockLogsTable.tableName}
      WHERE ${LockLogsTable.columnIsCompleted} = 1
        AND ${LockLogsTable.columnUnlockedAt} IS NOT NULL
        AND substr(${LockLogsTable.columnLockedAt}, 1, 10) >= ?
        AND substr(${LockLogsTable.columnLockedAt}, 1, 10) <= ?
      ''',
      [startDate, endDate],
    );

    final row = rows.isEmpty ? const <String, Object?>{} : rows.first;
    final raw = row['avg_unlock_minutes'];
    if (raw is num) {
      return raw.round();
    }
    return 0;
  }

  Future<LockLogModel?> getLatestIncompleteLogByAppId(String appId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      LockLogsTable.tableName,
      where:
          '${LockLogsTable.columnAppId} = ? AND ${LockLogsTable.columnIsCompleted} = ?',
      whereArgs: [appId, 0],
      orderBy: '${LockLogsTable.columnLockedAt} DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LockLogModel.fromMap(rows.first);
  }
}
