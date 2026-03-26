import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../database/tables/apps_table.dart';
import '../models/app_model.dart';

/// 应用监控数据仓库。
class AppRepository {
  AppRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  Future<List<AppModel>> getMonitoredApps() async {
    final rows = await _databaseHelper.queryByCondition(
      AppsTable.tableName,
      where: '${AppsTable.columnIsMonitored} = ?',
      whereArgs: [1],
      orderBy: '${AppsTable.columnUpdatedAt} DESC',
    );
    return rows.map(AppModel.fromMap).toList(growable: false);
  }

  Future<List<AppModel>> getLockedMonitoredApps() async {
    final rows = await _databaseHelper.queryByCondition(
      AppsTable.tableName,
      where:
          '${AppsTable.columnIsMonitored} = ? AND ${AppsTable.columnIsLocked} = ?',
      whereArgs: [1, 1],
      orderBy: '${AppsTable.columnUpdatedAt} DESC',
    );
    return rows.map(AppModel.fromMap).toList(growable: false);
  }

  Future<List<AppModel>> getHundredDayPlanApps() async {
    final rows = await _databaseHelper.queryByCondition(
      AppsTable.tableName,
      where:
          '${AppsTable.columnIsMonitored} = ? AND ${AppsTable.columnIsHundredDayPlan} = ?',
      whereArgs: [1, 1],
      orderBy: '${AppsTable.columnUpdatedAt} DESC',
    );
    return rows.map(AppModel.fromMap).toList(growable: false);
  }

  Future<List<AppModel>> getAppsByPlanId(String planId) async {
    final rows = await _databaseHelper.queryByCondition(
      AppsTable.tableName,
      where:
          '${AppsTable.columnIsMonitored} = ? AND ${AppsTable.columnPlanId} = ?',
      whereArgs: [1, planId],
      orderBy: '${AppsTable.columnUpdatedAt} DESC',
    );
    return rows.map(AppModel.fromMap).toList(growable: false);
  }

  Future<AppModel?> getAppById(String id) async {
    final row = await _databaseHelper.queryById(AppsTable.tableName, id);
    if (row == null) {
      return null;
    }
    return AppModel.fromMap(row);
  }

  Future<AppModel?> getAppByPackageName(String packageName) async {
    final rows = await _databaseHelper.queryByCondition(
      AppsTable.tableName,
      where: '${AppsTable.columnPackageName} = ?',
      whereArgs: [packageName],
    );
    if (rows.isEmpty) {
      return null;
    }
    return AppModel.fromMap(rows.first);
  }

  Future<AppModel> createMonitoredApp({
    required String appName,
    required String packageName,
    String? iconPath,
    required int dailyLimitMinutes,
    DateTime? installedAt,
    String? planId,
    bool isHundredDayPlan = false,
  }) async {
    final now = DateTime.now();
    final app = AppModel(
      id: _uuid.v4(),
      appName: appName,
      packageName: packageName,
      iconPath: iconPath,
      dailyLimitMinutes: dailyLimitMinutes,
      usedMinutesToday: 0,
      isMonitored: true,
      isLocked: false,
      isHundredDayPlan: planId != null || isHundredDayPlan,
      planId: planId,
      installedAt: installedAt,
      growthNormalJoinBonusAwardedAt: null,
      growthPlanStartedAt: planId == null ? null : now,
      growthPlanJoinBonusAwardedAt: null,
      unlockLimitOverrideMinutes: null,
      unlockLimitOverrideDate: null,
      createdAt: now,
      updatedAt: now,
    );

    await saveApp(app);
    return app;
  }

  Future<void> saveApp(AppModel app) async {
    final existing = await getAppById(app.id);
    if (existing == null) {
      await _databaseHelper.insert(AppsTable.tableName, app.toMap());
      return;
    }

    await _databaseHelper.update(
      AppsTable.tableName,
      app.toMap(),
      where: '${AppsTable.columnId} = ?',
      whereArgs: [app.id],
    );
  }

  Future<void> updateDailyLimit({
    required String appId,
    required int dailyLimitMinutes,
  }) async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnDailyLimitMinutes: dailyLimitMinutes,
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> updateUsedMinutesToday({
    required String appId,
    required int usedMinutesToday,
  }) async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnUsedMinutesToday: usedMinutesToday,
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> setLockedState({
    required String appId,
    required bool isLocked,
  }) async {
    final data = <String, Object?>{
      AppsTable.columnIsLocked: isLocked ? 1 : 0,
      AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
    };
    if (isLocked) {
      data[AppsTable.columnUnlockLimitOverrideMinutes] = null;
      data[AppsTable.columnUnlockLimitOverrideDate] = null;
    }
    await _databaseHelper.update(
      AppsTable.tableName,
      data,
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> updateInstalledAt({
    required String appId,
    required DateTime installedAt,
  }) async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnInstalledAt: installedAt.toIso8601String(),
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> setHundredDayPlanMembership({
    required String appId,
    required bool enabled,
  }) async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnIsHundredDayPlan: enabled ? 1 : 0,
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> setPlanMembership({
    required String appId,
    required String? planId,
  }) async {
    final existing = await getAppById(appId);
    final now = DateTime.now();
    final isEnteringPlan = planId != null && planId.isNotEmpty;
    final shouldResetPlanWindow =
        isEnteringPlan && existing?.planId != planId;
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnPlanId: planId,
        AppsTable.columnIsHundredDayPlan: planId == null ? 0 : 1,
        if (shouldResetPlanWindow)
          AppsTable.columnGrowthPlanStartedAt: now.toIso8601String(),
        if (shouldResetPlanWindow)
          AppsTable.columnGrowthPlanJoinBonusAwardedAt: null,
        AppsTable.columnUpdatedAt: now.toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> markGrowthNormalJoinBonusAwarded({
    required String appId,
    required DateTime awardedAt,
  }) async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnGrowthNormalJoinBonusAwardedAt:
            awardedAt.toIso8601String(),
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> markGrowthPlanJoinBonusAwarded({
    required String appId,
    required DateTime awardedAt,
  }) async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnGrowthPlanJoinBonusAwardedAt:
            awardedAt.toIso8601String(),
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> setUnlockLimitOverride({
    required String appId,
    required int? limitMinutes,
    required String? date,
  }) async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnUnlockLimitOverrideMinutes: limitMinutes,
        AppsTable.columnUnlockLimitOverrideDate: date,
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> removeApp(String appId) async {
    await _databaseHelper.delete(
      AppsTable.tableName,
      where: '${AppsTable.columnId} = ?',
      whereArgs: [appId],
    );
  }

  Future<void> lockAllMonitoredApps() async {
    await _databaseHelper.update(
      AppsTable.tableName,
      {
        AppsTable.columnIsLocked: 1,
        AppsTable.columnUnlockLimitOverrideMinutes: null,
        AppsTable.columnUnlockLimitOverrideDate: null,
        AppsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${AppsTable.columnIsMonitored} = ?',
      whereArgs: [1],
    );
  }
}
