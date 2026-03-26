import 'package:discipline_guardian/data/models/app_model.dart';
import 'package:discipline_guardian/data/models/plan_model.dart';
import 'package:discipline_guardian/data/models/schedule_settings_model.dart';
import 'package:discipline_guardian/data/models/usage_log_model.dart';
import 'package:discipline_guardian/data/repositories/app_repository.dart';
import 'package:discipline_guardian/data/repositories/lock_log_repository.dart';
import 'package:discipline_guardian/data/repositories/plan_repository.dart';
import 'package:discipline_guardian/data/repositories/settings_repository.dart';
import 'package:discipline_guardian/data/repositories/usage_log_repository.dart';
import 'package:discipline_guardian/platform/usage_stats_bridge.dart';
import 'package:discipline_guardian/services/local_backend_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppRepository extends AppRepository {
  _FakeAppRepository(this._apps);

  final List<AppModel> _apps;

  @override
  Future<List<AppModel>> getMonitoredApps() async => _apps;

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
}

class _FakeLockLogRepository extends LockLogRepository {
  _FakeLockLogRepository({
    required this.summary,
    required this.averageUnlockMinutes,
  });

  final Map<String, int> summary;
  final int averageUnlockMinutes;

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

class _FakeSettingsRepository extends SettingsRepository {
  _FakeSettingsRepository({
    required this.schedule,
  });

  final ScheduleSettingsModel schedule;

  @override
  Future<bool> getWhitelistEnabled() async => false;

  @override
  Future<ScheduleSettingsModel> getScheduleSettings() async => schedule;
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
  });
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
