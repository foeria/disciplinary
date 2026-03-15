import '../data/models/app_model.dart';
import '../data/models/notification_settings_model.dart';
import '../data/models/question_model.dart';
import '../data/models/schedule_settings_model.dart';
import '../data/models/usage_log_model.dart';
import '../data/models/whitelist_app_model.dart';
import '../data/repositories/app_repository.dart';
import '../data/repositories/lock_log_repository.dart';
import '../data/repositories/question_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/usage_log_repository.dart';
import '../platform/interception_bridge.dart';
import '../platform/system_permissions_bridge.dart';
import '../platform/usage_stats_bridge.dart';

/// 首页应用状态枚举。
enum AppHealthStatus {
  normal,
  warning,
  locked,
}

/// 一次设备使用时长同步结果。
class UsageSyncResult {
  final bool success;
  final bool permissionGranted;
  final List<AppModel> newlyLockedApps;

  const UsageSyncResult({
    required this.success,
    required this.permissionGranted,
    required this.newlyLockedApps,
  });

  const UsageSyncResult.permissionDenied()
      : success = false,
        permissionGranted = false,
        newlyLockedApps = const [];
}

/// 首页应用概览数据。
class HomeAppOverview {
  final AppModel app;
  final AppHealthStatus status;
  final double progress;

  const HomeAppOverview({
    required this.app,
    required this.status,
    required this.progress,
  });
}

/// 首页聚合数据。
class HomeDashboardData {
  final List<HomeAppOverview> apps;
  final int normalCount;
  final int warningCount;
  final int lockedCount;

  const HomeDashboardData({
    required this.apps,
    required this.normalCount,
    required this.warningCount,
    required this.lockedCount,
  });
}

/// 应用排行条目。
class AppRankingItem {
  final String appId;
  final String appName;
  final String packageName;
  final int totalUsedMinutes;
  final int totalOpenCount;
  final int totalUnlockCount;

  const AppRankingItem({
    required this.appId,
    required this.appName,
    required this.packageName,
    required this.totalUsedMinutes,
    required this.totalOpenCount,
    required this.totalUnlockCount,
  });
}

/// 统计页聚合数据。
class StatsPageData {
  final Map<String, int> usageByDate;
  final int totalUsedMinutes;
  final int maxUsedMinutes;
  final List<AppRankingItem> ranking;
  final int totalLockCount;
  final int totalUnlockCount;
  final int averageUnlockMinutes;

  const StatsPageData({
    required this.usageByDate,
    required this.totalUsedMinutes,
    required this.maxUsedMinutes,
    required this.ranking,
    required this.totalLockCount,
    required this.totalUnlockCount,
    required this.averageUnlockMinutes,
  });
}

/// 系统拦截诊断摘要。
class SystemDiagnosticsData {
  final String? recentInterceptedPackage;
  final String? recentLockAppName;
  final DateTime? recentLockAt;
  final String? recentUnlockAppName;
  final DateTime? recentUnlockAt;

  const SystemDiagnosticsData({
    required this.recentInterceptedPackage,
    required this.recentLockAppName,
    required this.recentLockAt,
    required this.recentUnlockAppName,
    required this.recentUnlockAt,
  });
}

/// 面向前端页面的数据服务聚合层。
///
/// 设计目标：
/// 1. 按页面提供稳定方法，避免页面直接拼 SQL。
/// 2. 将本地 DB 结构与 UI 状态解耦。
class LocalBackendService {
  static const Duration _unlockCooldownWindow = Duration(minutes: 2);
  static final Map<String, DateTime> _unlockCooldownUntil = <String, DateTime>{};

  LocalBackendService({
    AppRepository? appRepository,
    QuestionRepository? questionRepository,
    SettingsRepository? settingsRepository,
    UsageLogRepository? usageLogRepository,
    LockLogRepository? lockLogRepository,
    UsageStatsBridge? usageStatsBridge,
    SystemPermissionsBridge? systemPermissionsBridge,
    InterceptionBridge? interceptionBridge,
  })  : _appRepository = appRepository ?? AppRepository(),
        _questionRepository = questionRepository ?? QuestionRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _usageLogRepository = usageLogRepository ?? UsageLogRepository(),
      _lockLogRepository = lockLogRepository ?? LockLogRepository(),
      _usageStatsBridge = usageStatsBridge ?? UsageStatsBridge(),
      _systemPermissionsBridge =
        systemPermissionsBridge ?? SystemPermissionsBridge(),
      _interceptionBridge = interceptionBridge ?? InterceptionBridge();

  final AppRepository _appRepository;
  final QuestionRepository _questionRepository;
  final SettingsRepository _settingsRepository;
  final UsageLogRepository _usageLogRepository;
  final LockLogRepository _lockLogRepository;
  final UsageStatsBridge _usageStatsBridge;
  final SystemPermissionsBridge _systemPermissionsBridge;
  final InterceptionBridge _interceptionBridge;

  Future<bool> isUsageStatsPermissionGranted() {
    return _usageStatsBridge.hasPermission();
  }

  Future<void> openUsageStatsPermissionSettings() {
    return _usageStatsBridge.openPermissionSettings();
  }

  Future<bool> isAccessibilityPermissionGranted() {
    return _systemPermissionsBridge.isAccessibilityEnabled();
  }

  Future<void> openAccessibilityPermissionSettings() {
    return _systemPermissionsBridge.openAccessibilitySettings();
  }

  Future<bool> isOverlayPermissionGranted() {
    return _systemPermissionsBridge.canDrawOverlays();
  }

  Future<void> openOverlayPermissionSettings() {
    return _systemPermissionsBridge.openOverlaySettings();
  }

  Future<bool> areNotificationsEnabled() {
    return _systemPermissionsBridge.areNotificationsEnabled();
  }

  Future<bool> canRequestNotificationPermission() {
    return _systemPermissionsBridge.canRequestNotificationPermission();
  }

  Future<bool> requestNotificationPermission() {
    return _systemPermissionsBridge.requestNotificationPermission();
  }

  Future<void> openNotificationPermissionSettings() {
    return _systemPermissionsBridge.openNotificationSettings();
  }

  Future<bool> isBatteryOptimizationIgnored() {
    return _systemPermissionsBridge.isIgnoringBatteryOptimizations();
  }

  Future<bool> openBatteryOptimizationSettings() {
    return _systemPermissionsBridge.openBatteryOptimizationSettings();
  }

  Future<bool> isKeepAliveEnabled() {
    return _systemPermissionsBridge.isKeepAliveEnabled();
  }

  Future<bool> isKeepAliveRunning() {
    return _systemPermissionsBridge.isKeepAliveRunning();
  }

  Future<void> setKeepAliveEnabled(bool enabled) {
    return _systemPermissionsBridge.setKeepAliveEnabled(enabled);
  }

  Future<void> startKeepAliveService() {
    return _systemPermissionsBridge.startKeepAliveService();
  }

  Future<void> stopKeepAliveService() {
    return _systemPermissionsBridge.stopKeepAliveService();
  }

  Future<void> syncNativeInterceptionRules() async {
    final lockedApps = await _appRepository.getLockedMonitoredApps();
    final packages = lockedApps
        .map((app) => app.packageName)
        .where((pkg) => pkg.trim().isNotEmpty)
        .toList(growable: false);
    await _interceptionBridge.setBlockedPackages(packages);
  }

  Future<void> setNativeInterceptionEnabled(bool enabled) {
    return _interceptionBridge.setInterceptionEnabled(enabled);
  }

  Future<String?> getLastAccessibilityForegroundPackage() {
    return _interceptionBridge.getLastAccessibilityForegroundPackage();
  }

  Future<String?> getLastInterceptedPackage() {
    return _interceptionBridge.getLastInterceptedPackage();
  }

  Future<String?> consumeLastInterceptedPackage() {
    return _interceptionBridge.consumeLastInterceptedPackage();
  }

  Future<String?> consumePromptPackage() {
    return _interceptionBridge.consumePromptPackage();
  }

  Future<void> resetPromptState(String packageName) {
    return _interceptionBridge.resetPromptState(packageName);
  }

  Stream<String> watchPromptSignals() {
    return _interceptionBridge.promptSignals;
  }

  Future<bool> launchAppByPackage(String packageName) {
    return _interceptionBridge.launchAppByPackage(packageName);
  }

  Future<bool> moveGuardianToBackground() {
    return _interceptionBridge.moveGuardianToBackground();
  }

  Future<bool> openHomeScreen() {
    return _interceptionBridge.openHomeScreen();
  }

  Future<InterceptionStatus> getInterceptionStatus() {
    return _interceptionBridge.getInterceptionStatus();
  }

  Future<AppModel?> getLockedAppByPackageName(String packageName) async {
    final app = await _appRepository.getAppByPackageName(packageName);
    if (app == null || !app.isMonitored || !app.isLocked) {
      return null;
    }
    return app;
  }

  Future<String?> getRecentForegroundPackage() {
    return _usageStatsBridge.getRecentForegroundPackage();
  }

  Future<UsageSyncResult> syncTodayUsageWithRules() async {
    if (!await _usageStatsBridge.isSupported()) {
      return const UsageSyncResult(
        success: false,
        permissionGranted: false,
        newlyLockedApps: [],
      );
    }

    final hasPermission = await _usageStatsBridge.hasPermission();
    if (!hasPermission) {
      return const UsageSyncResult.permissionDenied();
    }

    final apps = await _appRepository.getMonitoredApps();
    if (apps.isEmpty) {
      return const UsageSyncResult(
        success: true,
        permissionGranted: true,
        newlyLockedApps: [],
      );
    }

    final usageByPackage = await _usageStatsBridge.getTodayUsageMinutes(
      apps.map((app) => app.packageName).toList(growable: false),
    );
    final today = _formatDate(DateTime.now());
    final whitelistEnabled = await _settingsRepository.getWhitelistEnabled();
    final whitelistApps = whitelistEnabled
        ? await _settingsRepository.getWhitelistApps()
        : const <WhitelistAppModel>[];
    final whitelistPackages = whitelistApps
        .map((app) => app.packageName)
        .toSet();
    final schedule = await _settingsRepository.getScheduleSettings();
    final now = DateTime.now();
    final isInSchedule = _isInMonitoringSchedule(now, schedule);
    final shouldApplyBySchedule = !schedule.isEnabled || isInSchedule;

    final newlyLockedApps = <AppModel>[];

    for (final app in apps) {
      final usedMinutes = usageByPackage[app.packageName] ?? 0;
      await _appRepository.updateUsedMinutesToday(
        appId: app.id,
        usedMinutesToday: usedMinutes,
      );

      await _usageLogRepository.saveDailyUsage(
        UsageLogModel(
          id: '${app.id}_$today',
          appId: app.id,
          date: today,
          usedMinutes: usedMinutes,
          unlockCount: 0,
        ),
      );

      final isWhitelisted = whitelistPackages.contains(app.packageName);
      final shouldApplyMonitoring = shouldApplyBySchedule && !isWhitelisted;
      if (!shouldApplyMonitoring) {
        continue;
      }

      final cooldownUntil = _unlockCooldownUntil[app.id];
      final isInUnlockCooldown =
          cooldownUntil != null && now.isBefore(cooldownUntil);
      if (isInUnlockCooldown) {
        continue;
      }

      final hasActiveUnlockOverride =
          app.unlockLimitOverrideMinutes != null &&
          app.unlockLimitOverrideDate == today;
      if (
        app.unlockLimitOverrideMinutes != null &&
        app.unlockLimitOverrideDate != today
      ) {
        await _appRepository.setUnlockLimitOverride(
          appId: app.id,
          limitMinutes: null,
          date: null,
        );
      }

      final effectiveLimitMinutes = hasActiveUnlockOverride
          ? app.unlockLimitOverrideMinutes!
          : app.dailyLimitMinutes;

      if (!app.isLocked && usedMinutes >= effectiveLimitMinutes) {
        await _appRepository.setLockedState(appId: app.id, isLocked: true);
        _unlockCooldownUntil.remove(app.id);
        final unlockMethod = await _settingsRepository.getUnlockMethod();
        await _lockLogRepository.createLockLog(
          appId: app.id,
          unlockMethod: unlockMethod,
        );
        newlyLockedApps.add(
          app.copyWith(
            usedMinutesToday: usedMinutes,
            isLocked: true,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    return UsageSyncResult(
      success: true,
      permissionGranted: true,
      newlyLockedApps: newlyLockedApps,
    );
  }

  Future<bool> syncTodayUsageFromDevice() async {
    final result = await syncTodayUsageWithRules();
    return result.success;
  }

  Future<HomeDashboardData> getHomeDashboardData() async {
    final apps = await _appRepository.getMonitoredApps();
    final overview = apps.map(_toHomeOverview).toList(growable: false);

    final normalCount = overview.where((a) => a.status == AppHealthStatus.normal).length;
    final warningCount = overview.where((a) => a.status == AppHealthStatus.warning).length;
    final lockedCount = overview.where((a) => a.status == AppHealthStatus.locked).length;

    return HomeDashboardData(
      apps: overview,
      normalCount: normalCount,
      warningCount: warningCount,
      lockedCount: lockedCount,
    );
  }

  Future<List<AppModel>> getAppsPageData() {
    return _appRepository.getMonitoredApps();
  }

  Future<AppModel> addMonitoredApp({
    required String appName,
    required String packageName,
    String? iconPath,
    required int dailyLimitMinutes,
  }) async {
    final created = await _appRepository.createMonitoredApp(
      appName: appName,
      packageName: packageName,
      iconPath: iconPath,
      dailyLimitMinutes: dailyLimitMinutes,
    );
    await syncTodayUsageWithRules();
    await syncNativeInterceptionRules();
    return await _appRepository.getAppById(created.id) ?? created;
  }

  Future<void> updateAppLimit({
    required String appId,
    required int dailyLimitMinutes,
  }) async {
    await _appRepository.updateDailyLimit(
      appId: appId,
      dailyLimitMinutes: dailyLimitMinutes,
    );
    await syncTodayUsageWithRules();
    await syncNativeInterceptionRules();
  }

  Future<int> unlockApp(String appId) async {
    final extensionMinutes = await _settingsRepository.getUnlockExtensionMinutes();
    final app = await _appRepository.getAppById(appId);
    if (app != null) {
      final baseline = app.usedMinutesToday > app.dailyLimitMinutes
          ? app.usedMinutesToday
          : app.dailyLimitMinutes;
      await _appRepository.setUnlockLimitOverride(
        appId: appId,
        limitMinutes: baseline + extensionMinutes,
        date: _formatDate(DateTime.now()),
      );
    }

    await _appRepository.setLockedState(appId: appId, isLocked: false);
    _unlockCooldownUntil[appId] = DateTime.now().add(_unlockCooldownWindow);
    await syncNativeInterceptionRules();
    final latestIncomplete =
        await _lockLogRepository.getLatestIncompleteLogByAppId(appId);
    if (latestIncomplete == null) {
      return extensionMinutes;
    }
    await _lockLogRepository.markUnlockCompleted(logId: latestIncomplete.id);
    return extensionMinutes;
  }

  Future<void> removeApp(String appId) async {
    final app = await _appRepository.getAppById(appId);
    await _appRepository.removeApp(appId);
    _unlockCooldownUntil.remove(appId);
    if (app != null) {
      await _interceptionBridge.resetPromptState(app.packageName);
    }
    await syncNativeInterceptionRules();
  }

  Future<void> lockAllApps() async {
    await _appRepository.lockAllMonitoredApps();
    final unlockMethod = await _settingsRepository.getUnlockMethod();
    final lockedApps = await _appRepository.getLockedMonitoredApps();
    for (final app in lockedApps) {
      final latestIncomplete =
          await _lockLogRepository.getLatestIncompleteLogByAppId(app.id);
      if (latestIncomplete != null) {
        continue;
      }
      await _lockLogRepository.createLockLog(
        appId: app.id,
        unlockMethod: unlockMethod,
      );
    }
    await syncNativeInterceptionRules();
  }

  Future<List<QuestionModel>> getQuestionBank({
    QuestionType? type,
    String? category,
  }) {
    return _questionRepository.getQuestions(type: type, category: category);
  }

  Future<List<QuestionModel>> getRandomUnlockQuestions({
    required int count,
    QuestionType type = QuestionType.fill,
  }) {
    final normalizedCount = count < 1 ? 1 : count;
    return _questionRepository.getRandomUnlockQuestions(
      count: normalizedCount,
      type: type,
    );
  }

  Future<QuestionModel> addQuestion({
    required String question,
    required String answer,
    required String category,
    QuestionType type = QuestionType.fill,
    List<String>? options,
  }) {
    return _questionRepository.createQuestion(
      question: question,
      answer: answer,
      category: category,
      type: type,
      options: options,
    );
  }

  Future<void> saveQuestion(QuestionModel question) {
    return _questionRepository.saveQuestion(question);
  }

  Future<void> removeQuestion(String questionId) {
    return _questionRepository.removeQuestion(questionId);
  }

  Future<String> getUnlockMethod() {
    return _settingsRepository.getUnlockMethod();
  }

  Future<void> setUnlockMethod(String method) {
    return _settingsRepository.setUnlockMethod(method);
  }

  Future<int> getUnlockQuestionCount() {
    return _settingsRepository.getUnlockQuestionCount();
  }

  Future<void> setUnlockQuestionCount(int count) {
    return _settingsRepository.setUnlockQuestionCount(count);
  }

  Future<int> incrementUnlockQuestionCountAfterSuccess() async {
    final current = await _settingsRepository.getUnlockQuestionCount();
    final next = (current + 1).clamp(3, 100);
    await _settingsRepository.setUnlockQuestionCount(next);
    return next;
  }

  Future<void> setPasswordSecret(String secret) {
    return _settingsRepository.setPasswordSecret(secret);
  }

  Future<String> getPasswordSecret() {
    return _settingsRepository.getPasswordSecret();
  }

  Future<int> getDelayMinutes() {
    return _settingsRepository.getDelayMinutes();
  }

  Future<int> getUnlockExtensionMinutes() {
    return _settingsRepository.getUnlockExtensionMinutes();
  }

  Future<void> setUnlockExtensionMinutes(int minutes) {
    return _settingsRepository.setUnlockExtensionMinutes(minutes);
  }

  Future<String> getTheme() {
    return _settingsRepository.getTheme();
  }

  Future<void> setTheme(String theme) {
    return _settingsRepository.setTheme(theme);
  }

  Future<bool> getOnboardingCompleted() {
    return _settingsRepository.getOnboardingCompleted();
  }

  Future<void> setOnboardingCompleted(bool completed) {
    return _settingsRepository.setOnboardingCompleted(completed);
  }

  Future<ScheduleSettingsModel> getSchedule() {
    return _settingsRepository.getScheduleSettings();
  }

  Future<void> saveSchedule(ScheduleSettingsModel model) {
    return _settingsRepository.saveScheduleSettings(model);
  }

  Future<NotificationSettingsModel> getNotificationSettings() {
    return _settingsRepository.getNotificationSettings();
  }

  Future<void> saveNotificationSettings(NotificationSettingsModel model) {
    return _settingsRepository.saveNotificationSettings(model);
  }

  Future<bool> getWhitelistEnabled() {
    return _settingsRepository.getWhitelistEnabled();
  }

  Future<void> setWhitelistEnabled(bool value) {
    return _settingsRepository.setWhitelistEnabled(value);
  }

  Future<List<WhitelistAppModel>> getWhitelistApps() {
    return _settingsRepository.getWhitelistApps();
  }

  Future<void> addWhitelistApp({
    required String appName,
    required String packageName,
  }) {
    return _settingsRepository.addWhitelistApp(
      appName: appName,
      packageName: packageName,
    );
  }

  Future<void> removeWhitelistApp(String whitelistId) {
    return _settingsRepository.removeWhitelistApp(whitelistId);
  }

  Future<StatsPageData> getStatsData({required String period}) async {
    final now = DateTime.now();
    final int days = period == 'month' ? 30 : 7;
    final start = now.subtract(Duration(days: days - 1));

    final startDate = _formatDate(start);
    final endDate = _formatDate(now);

    final logs = await _usageLogRepository.getLogsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    final usageByDate = <String, int>{};
    for (final log in logs) {
      usageByDate[log.date] = (usageByDate[log.date] ?? 0) + log.usedMinutes;
    }

    final totalUsedMinutes = usageByDate.values.fold<int>(0, (sum, value) => sum + value);
    final maxUsedMinutes = usageByDate.values.isEmpty
        ? 0
        : usageByDate.values.reduce((a, b) => a > b ? a : b);

    final rankingRows = await _usageLogRepository.getAppRankingByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    final ranking = rankingRows.map((row) {
      return AppRankingItem(
        appId: row['app_id'] as String,
        appName: row['app_name'] as String,
        packageName: row['package_name'] as String,
        totalUsedMinutes: (row['total_used_minutes'] as int?) ?? 0,
        totalOpenCount: (row['total_open_count'] as int?) ?? 0,
        totalUnlockCount: (row['total_unlock_count'] as int?) ?? 0,
      );
    }).toList(growable: false);

    final lockSummary = await _lockLogRepository.getSummaryByLockedDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    final avgUnlockMinutes =
        await _lockLogRepository.getAverageUnlockMinutesByLockedDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    return StatsPageData(
      usageByDate: usageByDate,
      totalUsedMinutes: totalUsedMinutes,
      maxUsedMinutes: maxUsedMinutes,
      ranking: ranking,
      totalLockCount: lockSummary['total_lock_count'] ?? 0,
      totalUnlockCount: lockSummary['completed_unlock_count'] ?? 0,
      averageUnlockMinutes: avgUnlockMinutes,
    );
  }

  Future<SystemDiagnosticsData> getSystemDiagnosticsData() async {
    final interceptionStatus = await _interceptionBridge.getInterceptionStatus();
    final logs = await _lockLogRepository.getRecentLogs(limit: 30);

    final recentLockLog = logs.isEmpty ? null : logs.first;
    final recentUnlockLog = logs.where((log) => log.isCompleted).cast<dynamic>().isEmpty
        ? null
        : logs.firstWhere((log) => log.isCompleted);

    final recentLockAppName = await _resolveAppNameById(recentLockLog?.appId);
    final recentUnlockAppName =
        await _resolveAppNameById(recentUnlockLog?.appId);

    return SystemDiagnosticsData(
      recentInterceptedPackage: interceptionStatus.lastInterceptedPackage,
      recentLockAppName: recentLockAppName,
      recentLockAt: recentLockLog?.lockedAt,
      recentUnlockAppName: recentUnlockAppName,
      recentUnlockAt: recentUnlockLog?.unlockedAt,
    );
  }

  HomeAppOverview _toHomeOverview(AppModel app) {
    final ratio = app.dailyLimitMinutes == 0
        ? 1.0
        : app.usedMinutesToday / app.dailyLimitMinutes;

    if (app.isLocked || ratio >= 1.0) {
      return HomeAppOverview(
        app: app,
        status: AppHealthStatus.locked,
        progress: ratio.clamp(0.0, 1.0),
      );
    }

    if (ratio >= 0.8) {
      return HomeAppOverview(
        app: app,
        status: AppHealthStatus.warning,
        progress: ratio.clamp(0.0, 1.0),
      );
    }

    return HomeAppOverview(
      app: app,
      status: AppHealthStatus.normal,
      progress: ratio.clamp(0.0, 1.0),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isInMonitoringSchedule(DateTime now, ScheduleSettingsModel schedule) {
    final minutes = now.hour * 60 + now.minute;
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final start = _timeStringToMinutes(
      isWeekend ? schedule.weekendStart : schedule.workdayStart,
    );
    final end = _timeStringToMinutes(
      isWeekend ? schedule.weekendEnd : schedule.workdayEnd,
    );

    if (start == end) {
      return true;
    }

    if (start < end) {
      return minutes >= start && minutes <= end;
    }

    return minutes >= start || minutes <= end;
  }

  int _timeStringToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return 0;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  Future<String?> _resolveAppNameById(String? appId) async {
    if (appId == null || appId.isEmpty) {
      return null;
    }
    final app = await _appRepository.getAppById(appId);
    return app?.appName;
  }
}
