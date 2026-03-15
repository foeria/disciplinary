import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'default_question_bank.dart';
import 'tables/apps_table.dart';
import 'tables/questions_table.dart';
import 'tables/usage_logs_table.dart';
import 'tables/settings_table.dart';
import 'tables/lock_logs_table.dart';
import 'tables/whitelist_table.dart';
import 'tables/schedules_table.dart';
import 'tables/notification_settings_table.dart';

/// SQLite 数据库助手
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _databaseVersion = 6;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('discipline_guardian.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 应用表
    await db.execute(AppsTable.createSql);
    await db.execute(AppsTable.createIndexPackage);

    // 使用记录表
    await db.execute(UsageLogsTable.createSql);
    await db.execute(UsageLogsTable.createIndexDate);
    await db.execute(UsageLogsTable.createIndexApp);

    // 设置表
    await db.execute(SettingsTable.createSql);

    // 题库表
    await db.execute(QuestionsTable.createSql);
    await db.execute(QuestionsTable.createIndexCategory);
    await db.execute(QuestionsTable.createIndexType);

    // 锁定日志表
    await db.execute(LockLogsTable.createSql);
    await db.execute(LockLogsTable.createIndexApp);
    await db.execute(LockLogsTable.createIndexLockedAt);

    // 白名单表
    await db.execute(WhitelistTable.createSql);
    await db.execute(WhitelistTable.createIndexPackage);

    // 监控时段表
    await db.execute(SchedulesTable.createSql);

    // 通知设置表
    await db.execute(NotificationSettingsTable.createSql);

    // 插入默认数据
    await _insertDefaultData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
    if (oldVersion < 5) {
      await _migrateToV5(db);
    }
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
  }

  Future<void> _migrateToV2(Database db) async {
    await db.execute(AppsTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    await db.execute(UsageLogsTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    await db.execute(SettingsTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    await db.execute(QuestionsTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    await db.execute(LockLogsTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    await db.execute(WhitelistTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    await db.execute(SchedulesTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    await db.execute(NotificationSettingsTable.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));

    await _ensureColumn(
      db,
      AppsTable.tableName,
      AppsTable.columnUsedMinutesToday,
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      AppsTable.tableName,
      AppsTable.columnIsLocked,
      'INTEGER NOT NULL DEFAULT 0',
    );

    await _ensureColumn(
      db,
      QuestionsTable.tableName,
      QuestionsTable.columnType,
      "TEXT NOT NULL DEFAULT '${QuestionsTable.typeFill}'",
    );
    await _ensureColumn(
      db,
      QuestionsTable.tableName,
      QuestionsTable.columnOptions,
      'TEXT',
    );
    await _ensureColumn(
      db,
      QuestionsTable.tableName,
      QuestionsTable.columnUpdatedAt,
      'TEXT',
    );

    await _ensureColumn(
      db,
      UsageLogsTable.tableName,
      UsageLogsTable.columnOpenCount,
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      UsageLogsTable.tableName,
      UsageLogsTable.columnUnlockCount,
      'INTEGER NOT NULL DEFAULT 0',
    );

    await _ensureColumn(
      db,
      LockLogsTable.tableName,
      LockLogsTable.columnIsCompleted,
      'INTEGER NOT NULL DEFAULT 0',
    );

    await _createIndexes(db);
    await _ensureDefaultRows(db);
  }

  Future<void> _migrateToV3(Database db) async {
    await _ensureColumn(
      db,
      AppsTable.tableName,
      AppsTable.columnUnlockLimitOverrideMinutes,
      'INTEGER',
    );
    await _ensureColumn(
      db,
      AppsTable.tableName,
      AppsTable.columnUnlockLimitOverrideDate,
      'TEXT',
    );

    await _ensureDefaultRows(db);
    await db.update(
      SettingsTable.tableName,
      {
        SettingsTable.columnValue: SettingsTable.methodQuestion,
        SettingsTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where:
          '${SettingsTable.columnKey} = ? AND ${SettingsTable.columnValue} != ?',
      whereArgs: [
        SettingsTable.keyUnlockMethod,
        SettingsTable.methodQuestion,
      ],
    );
  }

  Future<void> _migrateToV4(Database db) async {
    await _seedPresetQuestions(db);
  }

  Future<void> _migrateToV5(Database db) async {
    await _seedPresetQuestions(db);
  }

  Future<void> _migrateToV6(Database db) async {
    await _seedPresetQuestions(db);
  }

  Future<void> _ensureColumn(
    Database db,
    String tableName,
    String columnName,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = info.any((column) => column['name'] == columnName);
    if (exists) {
      return;
    }
    await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $definition');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_apps_package ON apps (package_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_usage_logs_date ON usage_logs (date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_usage_logs_app ON usage_logs (app_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_questions_category ON questions (category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_questions_type ON questions (type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lock_logs_app ON lock_logs (app_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lock_logs_locked_at ON lock_logs (locked_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_whitelist_package ON whitelist (package_name)');
  }

  Future<void> _ensureDefaultRows(Database db) async {
    for (final row in SettingsTable.defaultRows) {
      await db.insert(
        SettingsTable.tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await db.insert(
      SchedulesTable.tableName,
      SchedulesTable.defaultRow,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.insert(
      NotificationSettingsTable.tableName,
      NotificationSettingsTable.defaultRow,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await _seedPresetQuestions(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    // 默认设置
    for (final row in SettingsTable.defaultRows) {
      await db.insert(SettingsTable.tableName, row);
    }

    // 默认监控时段
    await db.insert(SchedulesTable.tableName, SchedulesTable.defaultRow);

    // 默认通知设置
    await db.insert(
      NotificationSettingsTable.tableName,
      NotificationSettingsTable.defaultRow,
    );
    await _seedPresetQuestions(db);
  }

  Future<void> _seedPresetQuestions(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final seed in presetQuestionSeeds) {
      await db.insert(
        QuestionsTable.tableName,
        {
          QuestionsTable.columnId: seed.id,
          QuestionsTable.columnQuestion: seed.question,
          QuestionsTable.columnAnswer: seed.answer,
          QuestionsTable.columnCategory: seed.category,
          QuestionsTable.columnType: seed.type,
          QuestionsTable.columnOptions: seed.options == null
              ? null
              : jsonEncode(seed.options),
          QuestionsTable.columnCreatedAt: now,
          QuestionsTable.columnUpdatedAt: now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // 通用 CRUD 操作
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<Map<String, dynamic>?> queryById(
    String table,
    String id, {
    String idColumn = 'id',
  }) async {
    final db = await database;
    final results = await db.query(
      table,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> queryByCondition(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
