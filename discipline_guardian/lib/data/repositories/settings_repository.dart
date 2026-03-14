import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../database/tables/notification_settings_table.dart';
import '../database/tables/schedules_table.dart';
import '../database/tables/settings_table.dart';
import '../database/tables/whitelist_table.dart';
import '../models/notification_settings_model.dart';
import '../models/schedule_settings_model.dart';
import '../models/whitelist_app_model.dart';

/// 系统配置与白名单仓库。
class SettingsRepository {
  SettingsRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  Future<String> getUnlockMethod() async {
    final value = await _getSettingValue(
      key: SettingsTable.keyUnlockMethod,
      fallbackValue: SettingsTable.methodQuestion,
    );
    if (value == SettingsTable.methodQuestion) {
      return value;
    }
    await setUnlockMethod(SettingsTable.methodQuestion);
    return SettingsTable.methodQuestion;
  }

  Future<void> setUnlockMethod(String _) async {
    await _upsertSettingValue(
      SettingsTable.keyUnlockMethod,
      SettingsTable.methodQuestion,
    );
  }

  Future<int> getUnlockQuestionCount() async {
    final value = await _getSettingValue(
      key: SettingsTable.keyUnlockQuestionCount,
      fallbackValue: '3',
    );
    final parsed = int.tryParse(value) ?? 3;
    if (parsed < 3) {
      return 3;
    }
    if (parsed > 100) {
      return 100;
    }
    return parsed;
  }

  Future<void> setUnlockQuestionCount(int count) async {
    final normalized = count.clamp(3, 100);
    await _upsertSettingValue(
      SettingsTable.keyUnlockQuestionCount,
      normalized.toString(),
    );
  }

  Future<void> setPasswordSecret(String value) async {
    await _upsertSettingValue(SettingsTable.keyPasswordHash, value);
  }

  Future<String> getPasswordSecret() async {
    return _getSettingValue(
      key: SettingsTable.keyPasswordHash,
      fallbackValue: '123456',
    );
  }

  Future<int> getDelayMinutes() async {
    final value = await _getSettingValue(
      key: SettingsTable.keyDelayMinutes,
      fallbackValue: '5',
    );
    return int.tryParse(value) ?? 5;
  }

  Future<int> getUnlockExtensionMinutes() async {
    final value = await _getSettingValue(
      key: SettingsTable.keyUnlockExtensionMinutes,
      fallbackValue: '15',
    );
    final parsed = int.tryParse(value) ?? 15;
    if (parsed < 5) {
      return 5;
    }
    if (parsed > 60) {
      return 60;
    }
    return parsed;
  }

  Future<void> setUnlockExtensionMinutes(int minutes) async {
    await _upsertSettingValue(
      SettingsTable.keyUnlockExtensionMinutes,
      minutes.toString(),
    );
  }

  Future<String> getTheme() async {
    return _getSettingValue(
      key: SettingsTable.keyTheme,
      fallbackValue: 'pink',
    );
  }

  Future<void> setTheme(String value) async {
    await _upsertSettingValue(SettingsTable.keyTheme, value);
  }

  Future<bool> getOnboardingCompleted() async {
    final raw = await _getSettingValue(
      key: SettingsTable.keyOnboardingCompleted,
      fallbackValue: '0',
    );
    return raw == '1';
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _upsertSettingValue(
      SettingsTable.keyOnboardingCompleted,
      value ? '1' : '0',
    );
  }

  Future<bool> getWhitelistEnabled() async {
    final raw = await _getSettingValue(
      key: SettingsTable.keyWhitelistEnabled,
      fallbackValue: '0',
    );
    return raw == '1';
  }

  Future<void> setWhitelistEnabled(bool value) async {
    await _upsertSettingValue(
      SettingsTable.keyWhitelistEnabled,
      value ? '1' : '0',
    );
  }

  Future<ScheduleSettingsModel> getScheduleSettings() async {
    final row = await _databaseHelper.queryById(
      SchedulesTable.tableName,
      SchedulesTable.defaultId,
    );
    if (row == null) {
      final defaultRow = SchedulesTable.defaultRow;
      await _databaseHelper.insert(SchedulesTable.tableName, defaultRow);
      return ScheduleSettingsModel.fromMap(defaultRow);
    }
    return ScheduleSettingsModel.fromMap(row);
  }

  Future<void> saveScheduleSettings(ScheduleSettingsModel model) async {
    await _databaseHelper.update(
      SchedulesTable.tableName,
      model.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${SchedulesTable.columnId} = ?',
      whereArgs: [SchedulesTable.defaultId],
    );
  }

  Future<NotificationSettingsModel> getNotificationSettings() async {
    final row = await _databaseHelper.queryById(
      NotificationSettingsTable.tableName,
      NotificationSettingsTable.defaultId,
    );
    if (row == null) {
      final defaultRow = NotificationSettingsTable.defaultRow;
      await _databaseHelper.insert(
        NotificationSettingsTable.tableName,
        defaultRow,
      );
      return NotificationSettingsModel.fromMap(defaultRow);
    }
    return NotificationSettingsModel.fromMap(row);
  }

  Future<void> saveNotificationSettings(NotificationSettingsModel model) async {
    await _databaseHelper.update(
      NotificationSettingsTable.tableName,
      model.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${NotificationSettingsTable.columnId} = ?',
      whereArgs: [NotificationSettingsTable.defaultId],
    );
  }

  Future<List<WhitelistAppModel>> getWhitelistApps() async {
    final rows = await _databaseHelper.queryByCondition(
      WhitelistTable.tableName,
      orderBy: '${WhitelistTable.columnCreatedAt} DESC',
    );
    return rows.map(WhitelistAppModel.fromMap).toList(growable: false);
  }

  Future<void> addWhitelistApp({
    required String appName,
    required String packageName,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _databaseHelper.insert(
      WhitelistTable.tableName,
      {
        WhitelistTable.columnId: _uuid.v4(),
        WhitelistTable.columnAppName: appName,
        WhitelistTable.columnPackageName: packageName,
        WhitelistTable.columnCreatedAt: now,
      },
    );
  }

  Future<void> removeWhitelistApp(String id) async {
    await _databaseHelper.delete(
      WhitelistTable.tableName,
      where: '${WhitelistTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<String> _getSettingValue({
    required String key,
    required String fallbackValue,
  }) async {
    final row = await _databaseHelper.queryById(
      SettingsTable.tableName,
      key,
      idColumn: SettingsTable.columnKey,
    );
    if (row == null) {
      await _upsertSettingValue(key, fallbackValue);
      return fallbackValue;
    }
    return row[SettingsTable.columnValue] as String;
  }

  Future<void> _upsertSettingValue(String key, String value) async {
    final existing = await _databaseHelper.queryById(
      SettingsTable.tableName,
      key,
      idColumn: SettingsTable.columnKey,
    );
    final row = {
      SettingsTable.columnKey: key,
      SettingsTable.columnValue: value,
      SettingsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
    };

    if (existing == null) {
      await _databaseHelper.insert(SettingsTable.tableName, row);
      return;
    }

    await _databaseHelper.update(
      SettingsTable.tableName,
      row,
      where: '${SettingsTable.columnKey} = ?',
      whereArgs: [key],
    );
  }
}
