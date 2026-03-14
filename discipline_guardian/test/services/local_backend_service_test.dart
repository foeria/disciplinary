import 'package:discipline_guardian/data/models/app_model.dart';
import 'package:discipline_guardian/data/models/usage_log_model.dart';
import 'package:discipline_guardian/data/repositories/app_repository.dart';
import 'package:discipline_guardian/data/repositories/lock_log_repository.dart';
import 'package:discipline_guardian/data/repositories/usage_log_repository.dart';
import 'package:discipline_guardian/services/local_backend_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppRepository extends AppRepository {
  _FakeAppRepository(this._apps);

  final List<AppModel> _apps;

  @override
  Future<List<AppModel>> getMonitoredApps() async => _apps;
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
  });
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
