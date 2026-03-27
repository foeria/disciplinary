import 'package:discipline_guardian/data/models/app_model.dart';
import 'package:discipline_guardian/data/models/growth_app_log_model.dart';
import 'package:discipline_guardian/data/models/growth_daily_log_model.dart';
import 'package:discipline_guardian/data/models/growth_profile_model.dart';
import 'package:discipline_guardian/data/models/lock_log_model.dart';
import 'package:discipline_guardian/data/models/notification_settings_model.dart';
import 'package:discipline_guardian/data/models/plan_model.dart';
import 'package:discipline_guardian/data/models/schedule_settings_model.dart';
import 'package:discipline_guardian/data/models/usage_log_model.dart';
import 'package:discipline_guardian/data/models/whitelist_app_model.dart';
import 'package:discipline_guardian/data/repositories/app_repository.dart';
import 'package:discipline_guardian/data/repositories/growth_repository.dart';
import 'package:discipline_guardian/data/repositories/lock_log_repository.dart';
import 'package:discipline_guardian/data/repositories/plan_repository.dart';
import 'package:discipline_guardian/data/repositories/settings_repository.dart';
import 'package:discipline_guardian/data/repositories/usage_log_repository.dart';
import 'package:discipline_guardian/platform/interception_bridge.dart';
import 'package:discipline_guardian/platform/system_permissions_bridge.dart';
import 'package:discipline_guardian/platform/usage_stats_bridge.dart';
import 'package:discipline_guardian/services/local_backend_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppRepository extends AppRepository {
  _FakeAppRepository(this._apps);

  final List<AppModel> _apps;

  @override
  Future<List<AppModel>> getMonitoredApps() async => _apps;

  @override
  Future<List<AppModel>> getLockedMonitoredApps() async {
    return _apps.where((app) => app.isLocked).toList(growable: false);
  }

  @override
  Future<AppModel?> getAppById(String appId) async {
    for (final app in _apps) {
      if (app.id == appId) {
        return app;
      }
    }
    return null;
  }

  @override
  Future<AppModel?> getAppByPackageName(String packageName) async {
    for (final app in _apps) {
      if (app.packageName == packageName) {
        return app;
      }
    }
    return null;
  }

  @override
  Future<void> updateUsedMinutesToday({
    required String appId,
    required int usedMinutesToday,
  }) async {
    final index = _apps.indexWhere((app) => app.id == appId);
    if (index == -1) {
      return;
    }
    _apps[index] = _apps[index].copyWith(
      usedMinutesToday: usedMinutesToday,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> setLockedState({
    required String appId,
    required bool isLocked,
  }) async {
    final index = _apps.indexWhere((app) => app.id == appId);
    if (index == -1) {
      return;
    }
    _apps[index] = _apps[index].copyWith(
      isLocked: isLocked,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> setUnlockLimitOverride({
    required String appId,
    required int? limitMinutes,
    required String? date,
  }) async {
    final index = _apps.indexWhere((app) => app.id == appId);
    if (index == -1) {
      return;
    }
    _apps[index] = _apps[index].copyWith(
      unlockLimitOverrideMinutes: limitMinutes,
      unlockLimitOverrideDate: date,
      updatedAt: DateTime.now(),
    );
  }
}

class _FakeUsageLogRepository extends UsageLogRepository {
  _FakeUsageLogRepository({
    required this.logs,
    required this.rankingRows,
  });

  final List<UsageLogModel> logs;
  final List<Map<String, dynamic>> rankingRows;

  @override
  Future<List<UsageLogModel>> getLogsByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    return logs;
  }

  @override
  Future<List<Map<String, dynamic>>> getAppRankingByDateRange({
    required String startDate,
    required String endDate,
    int limit = 10,
  }) async {
    return rankingRows;
  }

  @override
  Future<void> saveDailyUsage(UsageLogModel log) async {
    final index = logs.indexWhere(
      (existing) => existing.appId == log.appId && existing.date == log.date,
    );
    if (index >= 0) {
      logs[index] = log;
      return;
    }
    logs.add(log);
  }

  @override
  Future<UsageLogModel?> getLogByAppAndDate({
    required String appId,
    required String date,
  }) async {
    for (final log in logs) {
      if (log.appId == appId && log.date == date) {
        return log;
      }
    }
    return null;
  }

  @override
  Future<List<UsageLogModel>> getLogsByDate(String date) async {
    return logs.where((log) => log.date == date).toList(growable: false);
  }

  @override
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

class _FakeLockLogRepository extends LockLogRepository {
  _FakeLockLogRepository({
    required this.summary,
    required this.averageUnlockMinutes,
  });

  final Map<String, int> summary;
  final int averageUnlockMinutes;
  final List<LockLogModel> lockLogs = <LockLogModel>[];

  @override
  Future<LockLogModel> createLockLog({
    required String appId,
    required String unlockMethod,
  }) async {
    final model = LockLogModel(
      id: 'lock-${lockLogs.length + 1}',
      appId: appId,
      lockedAt: DateTime.now(),
      unlockMethod: unlockMethod,
      isCompleted: false,
    );
    lockLogs.add(model);
    return model;
  }

  @override
  Future<void> markUnlockCompleted({
    required String logId,
  }) async {
    final index = lockLogs.indexWhere((log) => log.id == logId);
    if (index == -1) {
      return;
    }
    final existing = lockLogs[index];
    lockLogs[index] = LockLogModel(
      id: existing.id,
      appId: existing.appId,
      lockedAt: existing.lockedAt,
      unlockedAt: DateTime.now(),
      unlockMethod: existing.unlockMethod,
      isCompleted: true,
    );
  }

  @override
  Future<LockLogModel?> getLatestIncompleteLogByAppId(String appId) async {
    for (final log in lockLogs.reversed) {
      if (log.appId == appId && !log.isCompleted) {
        return log;
      }
    }
    return null;
  }

  @override
  Future<Map<String, int>> getSummaryByLockedDateRange({
    required String startDate,
    required String endDate,
  }) async {
    return summary;
  }

  @override
  Future<int> getAverageUnlockMinutesByLockedDateRange({
    required String startDate,
    required String endDate,
  }) async {
    return averageUnlockMinutes;
  }
}

class _FakeGrowthRepository extends GrowthRepository {
  GrowthProfileModel? profile;
  final List<GrowthDailyLogModel> dailyLogs = <GrowthDailyLogModel>[];
  final List<GrowthAppLogModel> appLogs = <GrowthAppLogModel>[];
  int _nextId = 0;

  @override
  Future<GrowthProfileModel> ensureProfile({
    required String initialRankName,
  }) async {
    profile ??= GrowthProfileModel(
      id: 'primary',
      totalExp: 0,
      currentRankIndex: 1,
      currentRankName: initialRankName,
      guardPoints: 0,
      guardStars: 0,
      currentStreakDays: 0,
      bestStreakDays: 0,
      lastSettlementDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return profile!;
  }

  @override
  Future<void> saveProfile(GrowthProfileModel model) async {
    profile = model;
  }

  @override
  Future<List<GrowthDailyLogModel>> getDailyLogsCreatedOn(String date) async {
    return dailyLogs
        .where((log) => _formatDate(log.createdAt) == date)
        .toList(growable: false);
  }

  @override
  Future<List<GrowthAppLogModel>> getAppLogsCreatedOn(String date) async {
    return appLogs
        .where((log) => _formatDate(log.createdAt) == date)
        .toList(growable: false);
  }

  @override
  Future<void> saveDailyLog(GrowthDailyLogModel model) async {
    dailyLogs.removeWhere((log) => log.date == model.date);
    dailyLogs.add(model);
  }

  @override
  Future<void> replaceAppLogsForDate({
    required String date,
    required List<GrowthAppLogModel> logs,
  }) async {
    appLogs.removeWhere((log) => log.date == date);
    appLogs.addAll(logs);
  }

  @override
  String nextLogId() {
    _nextId += 1;
    return 'growth-log-$_nextId';
  }
}

class _FakeSettingsRepository extends SettingsRepository {
  _FakeSettingsRepository({
    required this.schedule,
    NotificationSettingsModel? notificationSettings,
    this.whitelistEnabled = false,
    List<WhitelistAppModel>? whitelistApps,
  })  : whitelistApps = whitelistApps ?? const <WhitelistAppModel>[],
        _notificationSettings =
            notificationSettings ??
            NotificationSettingsModel(
              id: 'default',
              reminderEnabled: true,
              reminderMinutes: 3,
              liveActivityEnabled: false,
              soundEnabled: true,
              quietHoursStart: null,
              quietHoursEnd: null,
              updatedAt: DateTime.now(),
            );

  final ScheduleSettingsModel schedule;
  final bool whitelistEnabled;
  final List<WhitelistAppModel> whitelistApps;
  final NotificationSettingsModel _notificationSettings;

  @override
  Future<bool> getWhitelistEnabled() async => whitelistEnabled;

  @override
  Future<List<WhitelistAppModel>> getWhitelistApps() async => whitelistApps;

  @override
  Future<ScheduleSettingsModel> getScheduleSettings() async => schedule;

  @override
  Future<NotificationSettingsModel> getNotificationSettings() async =>
      _notificationSettings;

  @override
  Future<String> getUnlockMethod() async => 'question';

  @override
  Future<int> getUnlockQuestionCount() async => 3;

  @override
  Future<int> getUnlockExtensionMinutes() async => 15;
}

class _FakeSystemPermissionsBridge extends SystemPermissionsBridge {
  _FakeSystemPermissionsBridge({
    required this.notificationsEnabled,
  });

  final bool notificationsEnabled;

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;
}

class _FakeInterceptionBridge extends InterceptionBridge {
  List<String> blockedPackages = const <String>[];
  List<Map<String, Object?>> monitoringRules = const <Map<String, Object?>>[];
  bool reminderEnabled = false;
  int reminderMinutes = 0;
  bool notificationsEnabled = false;
  bool soundEnabled = false;
  bool scheduleEnabled = false;
  String workdayStart = '00:00';
  String workdayEnd = '23:59';
  String weekendStart = '00:00';
  String weekendEnd = '23:59';

  @override
  Future<void> setBlockedPackages(List<String> packages) async {
    blockedPackages = List<String>.from(packages);
  }

  @override
  Future<void> syncUsageMonitoringConfig({
    required List<Map<String, Object?>> rules,
    required bool reminderEnabled,
    required int reminderMinutes,
    required bool notificationsEnabled,
    required bool soundEnabled,
    required bool scheduleEnabled,
    required String workdayStart,
    required String workdayEnd,
    required String weekendStart,
    required String weekendEnd,
  }) async {
    monitoringRules = rules
        .map((rule) => Map<String, Object?>.from(rule))
        .toList(growable: false);
    this.reminderEnabled = reminderEnabled;
    this.reminderMinutes = reminderMinutes;
    this.notificationsEnabled = notificationsEnabled;
    this.soundEnabled = soundEnabled;
    this.scheduleEnabled = scheduleEnabled;
    this.workdayStart = workdayStart;
    this.workdayEnd = workdayEnd;
    this.weekendStart = weekendStart;
    this.weekendEnd = weekendEnd;
  }
}

class _FakePlanRepository extends PlanRepository {
  _FakePlanRepository(this._plans);

  final List<PlanModel> _plans;

  @override
  Future<List<PlanModel>> getPlans() async => _plans;

  @override
  Future<PlanModel?> getPlanById(String id) async {
    for (final plan in _plans) {
      if (plan.id == id) {
        return plan;
      }
    }
    return null;
  }
}

class _FakeUsageStatsBridge extends UsageStatsBridge {
  _FakeUsageStatsBridge(this.usageByPackage);

  final Map<String, int> usageByPackage;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<Map<String, int>> getTodayUsageMinutes(List<String> packageNames) async {
    return {
      for (final packageName in packageNames)
        packageName: usageByPackage[packageName] ?? 0,
    };
  }
}

void main() {
  group('LocalBackendService', () {
    test('getHomeDashboardData computes status counts', () async {
      final now = DateTime.now();
      final service = LocalBackendService(
        appRepository: _FakeAppRepository([
          AppModel(
            id: 'a1',
            appName: 'Normal App',
            packageName: 'com.example.normal',
            dailyLimitMinutes: 100,
            usedMinutesToday: 20,
            isMonitored: true,
            isLocked: false,
            createdAt: now,
            updatedAt: now,
          ),
          AppModel(
            id: 'a2',
            appName: 'Warning App',
            packageName: 'com.example.warning',
            dailyLimitMinutes: 100,
            usedMinutesToday: 85,
            isMonitored: true,
            isLocked: false,
            createdAt: now,
            updatedAt: now,
          ),
          AppModel(
            id: 'a3',
            appName: 'Locked App',
            packageName: 'com.example.locked',
            dailyLimitMinutes: 100,
            usedMinutesToday: 100,
            isMonitored: true,
            isLocked: true,
            createdAt: now,
            updatedAt: now,
          ),
        ]),
        planRepository: _FakePlanRepository(const <PlanModel>[]),
        growthRepository: _FakeGrowthRepository(),
      );

      final data = await service.getHomeDashboardData();

      expect(data.normalCount, 1);
      expect(data.warningCount, 1);
      expect(data.lockedCount, 1);
      expect(data.apps.length, 3);
    });

    test('getStatsData aggregates usage and ranking data', () async {
      final now = DateTime.now();
      final today = _formatDate(now);
      final yesterday = _formatDate(now.subtract(const Duration(days: 1)));

      final service = LocalBackendService(
        appRepository: _FakeAppRepository(const []),
        planRepository: _FakePlanRepository(const <PlanModel>[]),
        growthRepository: _FakeGrowthRepository(),
        usageLogRepository: _FakeUsageLogRepository(
          logs: [
            UsageLogModel(
              id: 'u1',
              appId: 'a1',
              date: today,
              usedMinutes: 20,
              openCount: 2,
              unlockCount: 1,
            ),
            UsageLogModel(
              id: 'u2',
              appId: 'a2',
              date: yesterday,
              usedMinutes: 30,
              openCount: 1,
              unlockCount: 0,
            ),
          ],
          rankingRows: const [
            {
              'app_id': 'a1',
              'app_name': 'App A',
              'package_name': 'com.example.a',
              'total_used_minutes': 50,
              'total_open_count': 5,
              'total_unlock_count': 1,
            },
          ],
        ),
        lockLogRepository: _FakeLockLogRepository(
          summary: const {
            'total_lock_count': 3,
            'completed_unlock_count': 2,
          },
          averageUnlockMinutes: 6,
        ),
      );

      final data = await service.getStatsData(period: 'week');

      expect(data.totalUsedMinutes, 50);
      expect(data.maxUsedMinutes, 30);
      expect(data.usageByDate[today], 20);
      expect(data.usageByDate[yesterday], 30);
      expect(data.ranking.length, 1);
      expect(data.ranking.first.appName, 'App A');
      expect(data.ranking.first.totalUsedMinutes, 50);
      expect(data.totalLockCount, 3);
      expect(data.totalUnlockCount, 2);
      expect(data.averageUnlockMinutes, 6);
    });

    test('syncTodayUsageWithRules unlocks apps after daily usage resets', () async {
      final now = DateTime.now();
      final apps = [
        AppModel(
          id: 'a1',
          appName: 'Locked Yesterday',
          packageName: 'com.example.locked',
          dailyLimitMinutes: 60,
          usedMinutesToday: 60,
          isMonitored: true,
          isLocked: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final appRepository = _FakeAppRepository(apps);
      final usageLogRepository = _FakeUsageLogRepository(
        logs: <UsageLogModel>[],
        rankingRows: const [],
      );
      final service = LocalBackendService(
        appRepository: appRepository,
        planRepository: _FakePlanRepository(const <PlanModel>[]),
        growthRepository: _FakeGrowthRepository(),
        lockLogRepository: _FakeLockLogRepository(
          summary: const {},
          averageUnlockMinutes: 0,
        ),
        settingsRepository: _FakeSettingsRepository(
          schedule: ScheduleSettingsModel(
            id: 'default',
            isEnabled: false,
            workdayStart: '00:00',
            workdayEnd: '23:59',
            weekendStart: '00:00',
            weekendEnd: '23:59',
            updatedAt: now,
          ),
        ),
        usageLogRepository: usageLogRepository,
        usageStatsBridge: _FakeUsageStatsBridge(
          const {'com.example.locked': 0},
        ),
      );

      final result = await service.syncTodayUsageWithRules();

      expect(result.success, isTrue);
      expect(result.permissionGranted, isTrue);
      expect(result.newlyLockedApps, isEmpty);
      expect(apps.single.usedMinutesToday, 0);
      expect(apps.single.isLocked, isFalse);
      expect(usageLogRepository.logs, hasLength(1));
      expect(usageLogRepository.logs.single.usedMinutes, 0);
    });

    test('syncTodayUsageWithRules applies 30-minute limit for hundred-day plan apps', () async {
      final now = DateTime.now();
      final plan = PlanModel(
        id: 'p1',
        name: 'Focus Plan',
        durationDays: 100,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final apps = [
        AppModel(
          id: 'a1',
          appName: 'Plan App',
          packageName: 'com.example.plan',
          dailyLimitMinutes: 120,
          usedMinutesToday: 0,
          isMonitored: true,
          isLocked: false,
          isHundredDayPlan: true,
          planId: plan.id,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final service = LocalBackendService(
        appRepository: _FakeAppRepository(apps),
        planRepository: _FakePlanRepository([plan]),
        growthRepository: _FakeGrowthRepository(),
        lockLogRepository: _FakeLockLogRepository(
          summary: const {},
          averageUnlockMinutes: 0,
        ),
        settingsRepository: _FakeSettingsRepository(
          schedule: ScheduleSettingsModel(
            id: 'default',
            isEnabled: false,
            workdayStart: '00:00',
            workdayEnd: '23:59',
            weekendStart: '00:00',
            weekendEnd: '23:59',
            updatedAt: now,
          ),
        ),
        usageLogRepository: _FakeUsageLogRepository(
          logs: <UsageLogModel>[],
          rankingRows: const [],
        ),
        usageStatsBridge: _FakeUsageStatsBridge(
          const {'com.example.plan': 35},
        ),
      );

      final result = await service.syncTodayUsageWithRules();

      expect(result.success, isTrue);
      expect(result.newlyLockedApps, hasLength(1));
      expect(apps.single.isLocked, isTrue);
    });

    test('syncNativeInterceptionRules syncs reminder config and effective limits', () async {
      final now = DateTime.now();
      final today = _formatDate(now);
      final plan = PlanModel(
        id: 'p1',
        name: 'Focus Plan',
        durationDays: 100,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final bridge = _FakeInterceptionBridge();
      final service = LocalBackendService(
        appRepository: _FakeAppRepository([
          AppModel(
            id: 'locked',
            appName: 'Locked App',
            packageName: 'com.example.locked',
            dailyLimitMinutes: 60,
            isMonitored: true,
            isLocked: true,
            createdAt: now,
            updatedAt: now,
          ),
          AppModel(
            id: 'plan',
            appName: 'Plan App',
            packageName: 'com.example.plan',
            dailyLimitMinutes: 90,
            isMonitored: true,
            planId: plan.id,
            createdAt: now,
            updatedAt: now,
          ),
          AppModel(
            id: 'override',
            appName: 'Override App',
            packageName: 'com.example.override',
            dailyLimitMinutes: 45,
            isMonitored: true,
            unlockLimitOverrideMinutes: 55,
            unlockLimitOverrideDate: today,
            createdAt: now,
            updatedAt: now,
          ),
          AppModel(
            id: 'white',
            appName: 'Whitelist App',
            packageName: 'com.example.white',
            dailyLimitMinutes: 30,
            isMonitored: true,
            createdAt: now,
            updatedAt: now,
          ),
        ]),
        planRepository: _FakePlanRepository([plan]),
        growthRepository: _FakeGrowthRepository(),
        settingsRepository: _FakeSettingsRepository(
          schedule: ScheduleSettingsModel(
            id: 'default',
            isEnabled: true,
            workdayStart: '09:00',
            workdayEnd: '18:00',
            weekendStart: '10:00',
            weekendEnd: '16:00',
            updatedAt: now,
          ),
          notificationSettings: NotificationSettingsModel(
            id: 'default',
            reminderEnabled: true,
            reminderMinutes: 3,
            liveActivityEnabled: false,
            soundEnabled: false,
            quietHoursStart: null,
            quietHoursEnd: null,
            updatedAt: now,
          ),
          whitelistEnabled: true,
          whitelistApps: [
            WhitelistAppModel(
              id: 'white-1',
              appName: 'Whitelist App',
              packageName: 'com.example.white',
              createdAt: now,
            ),
          ],
        ),
        systemPermissionsBridge: _FakeSystemPermissionsBridge(
          notificationsEnabled: true,
        ),
        interceptionBridge: bridge,
      );

      await service.syncNativeInterceptionRules();

      expect(bridge.blockedPackages, ['com.example.locked']);
      expect(bridge.reminderEnabled, isTrue);
      expect(bridge.reminderMinutes, 3);
      expect(bridge.notificationsEnabled, isTrue);
      expect(bridge.soundEnabled, isFalse);
      expect(bridge.scheduleEnabled, isTrue);
      expect(bridge.workdayStart, '09:00');
      expect(bridge.workdayEnd, '18:00');
      expect(bridge.weekendStart, '10:00');
      expect(bridge.weekendEnd, '16:00');
      expect(
        bridge.monitoringRules.any(
          (rule) => rule['packageName'] == 'com.example.white',
        ),
        isFalse,
      );

      final planRule = bridge.monitoringRules.singleWhere(
        (rule) => rule['packageName'] == 'com.example.plan',
      );
      expect(planRule['baseLimitMinutes'], 30);

      final overrideRule = bridge.monitoringRules.singleWhere(
        (rule) => rule['packageName'] == 'com.example.override',
      );
      expect(overrideRule['baseLimitMinutes'], 45);
      expect(overrideRule['unlockLimitOverrideMinutes'], 55);
      expect(overrideRule['unlockLimitOverrideDate'], today);
    });
  });
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
