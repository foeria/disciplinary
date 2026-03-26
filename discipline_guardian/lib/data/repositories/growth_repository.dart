import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../database/tables/growth_app_logs_table.dart';
import '../database/tables/growth_daily_logs_table.dart';
import '../database/tables/growth_profile_table.dart';
import '../models/growth_app_log_model.dart';
import '../models/growth_daily_log_model.dart';
import '../models/growth_profile_model.dart';

class GrowthRepository {
  GrowthRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  Future<GrowthProfileModel?> getProfile() async {
    final rows = await _databaseHelper.queryAll(GrowthProfileTable.tableName);
    if (rows.isEmpty) {
      return null;
    }
    return GrowthProfileModel.fromMap(rows.first);
  }

  Future<void> saveProfile(GrowthProfileModel model) async {
    final db = await _databaseHelper.database;
    await db.insert(
      GrowthProfileTable.tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<GrowthProfileModel> ensureProfile({
    required String initialRankName,
  }) async {
    final existing = await getProfile();
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final model = GrowthProfileModel(
      id: 'primary',
      totalExp: 0,
      currentRankIndex: 1,
      currentRankName: initialRankName,
      guardPoints: 0,
      guardStars: 0,
      currentStreakDays: 0,
      bestStreakDays: 0,
      lastSettlementDate: null,
      createdAt: now,
      updatedAt: now,
    );
    await saveProfile(model);
    return model;
  }

  Future<GrowthDailyLogModel?> getDailyLogByDate(String date) async {
    final rows = await _databaseHelper.queryByCondition(
      GrowthDailyLogsTable.tableName,
      where: '${GrowthDailyLogsTable.columnDate} = ?',
      whereArgs: [date],
      orderBy: '${GrowthDailyLogsTable.columnCreatedAt} DESC',
    );
    if (rows.isEmpty) {
      return null;
    }
    return GrowthDailyLogModel.fromMap(rows.first);
  }

  Future<List<GrowthDailyLogModel>> getDailyLogsCreatedOn(String date) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      GrowthDailyLogsTable.tableName,
      where: 'substr(${GrowthDailyLogsTable.columnCreatedAt}, 1, 10) = ?',
      whereArgs: [date],
      orderBy:
          '${GrowthDailyLogsTable.columnCreatedAt} DESC, ${GrowthDailyLogsTable.columnDate} DESC',
    );
    return rows.map(GrowthDailyLogModel.fromMap).toList(growable: false);
  }

  Future<GrowthDailyLogModel?> getLatestDailyLog() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      GrowthDailyLogsTable.tableName,
      orderBy:
          '${GrowthDailyLogsTable.columnCreatedAt} DESC, ${GrowthDailyLogsTable.columnDate} DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return GrowthDailyLogModel.fromMap(rows.first);
  }

  Future<void> saveDailyLog(GrowthDailyLogModel model) async {
    final db = await _databaseHelper.database;
    await db.insert(
      GrowthDailyLogsTable.tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAppLogsForDate({
    required String date,
    required List<GrowthAppLogModel> logs,
  }) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        GrowthAppLogsTable.tableName,
        where: '${GrowthAppLogsTable.columnDate} = ?',
        whereArgs: [date],
      );
      for (final log in logs) {
        await txn.insert(
          GrowthAppLogsTable.tableName,
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<GrowthAppLogModel>> getAppLogsCreatedOn(String date) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      GrowthAppLogsTable.tableName,
      where: 'substr(${GrowthAppLogsTable.columnCreatedAt}, 1, 10) = ?',
      whereArgs: [date],
      orderBy:
          '${GrowthAppLogsTable.columnCreatedAt} DESC, ${GrowthAppLogsTable.columnExpGained} DESC',
    );
    return rows.map(GrowthAppLogModel.fromMap).toList(growable: false);
  }

  String nextLogId() => _uuid.v4();
}
