import 'package:flutter/material.dart';
import '../../../core/events/app_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_model.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import '../lock/lock_screen.dart';
import '../settings/system_permissions_page.dart';
import 'add_app_page.dart';
import 'app_settings_page.dart';

/// 应用数据模型
class MonitoredApp {
  final String id;
  final String appName;
  final String packageName;
  final String? planName;
  final IconData icon;
  final Color iconColor;
  final int usedMinutes;
  final int limitMinutes;
  final int effectiveLimitMinutes;
  final bool isHundredDayPlan;
  final bool isLocked;

  const MonitoredApp({
    required this.id,
    required this.appName,
    required this.packageName,
    this.planName,
    required this.icon,
    required this.iconColor,
    required this.usedMinutes,
    required this.limitMinutes,
    required this.effectiveLimitMinutes,
    this.isHundredDayPlan = false,
    this.isLocked = false,
  });
}

/// 应用管理页面
class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  final LocalBackendService _backendService = LocalBackendService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  final List<MonitoredApp> _monitoredApps = <MonitoredApp>[];

  @override
  void initState() {
    super.initState();
    AppEvents.appsRefreshTick.addListener(_onAppsRefreshRequested);
    _loadApps();
  }

  void _onAppsRefreshRequested() {
    if (!mounted) {
      return;
    }
    _loadApps();
  }

  Future<void> _loadApps() async {
    await _backendService.syncTodayUsageFromDevice();
    final apps = await _backendService.getAppsPageData();
    final planStatuses = await _backendService.getPlanStatuses(
      monitoredApps: apps,
    );
    final planStatusById = {
      for (final plan in planStatuses) plan.planId: plan,
    };
    if (!mounted) {
      return;
    }
    setState(() {
      _monitoredApps
        ..clear()
        ..addAll(
          apps.map(
            (app) => _toMonitoredApp(
              app,
              planStatusById: planStatusById,
            ),
          ),
        );
      _isLoading = false;
    });
  }

  List<MonitoredApp> get _filteredApps {
    if (_searchQuery.isEmpty) return _monitoredApps;
    return _monitoredApps
        .where((app) =>
            app.appName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    AppEvents.appsRefreshTick.removeListener(_onAppsRefreshRequested);
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('已监控 (${_monitoredApps.length})'),
              const SizedBox(height: 12),
              ..._filteredApps.map((app) => _buildAppCard(app)),
            ],
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部
            _buildHeader(),
            // 搜索框
            _buildSearchBar(),
            // 应用列表
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addApp,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<bool> _requestManagementAuthorization(
    MonitoredApp app, {
    required String actionLabel,
  }) async {
    if (!_requiresManagementAuthorization(app)) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    var isAuthorized = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          appName: app.appName,
          usedMinutes: app.usedMinutes,
          limitMinutes: app.effectiveLimitMinutes,
          unlockMethod: UnlockMethod.question,
          overrideQuestionCount: app.isHundredDayPlan ? 100 : null,
          titleText: '需要验证',
          reasonText: '$actionLabel前请先完成验证',
          onUnlockSuccess: () async {
            if (!app.isHundredDayPlan) {
              await _backendService.incrementUnlockQuestionCountAfterSuccess();
            }
            if (!mounted) {
              return;
            }
            isAuthorized = true;
            Navigator.of(context).pop();
          },
          onExitRequested: () async {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    return isAuthorized;
  }

  bool _requiresManagementAuthorization(MonitoredApp app) {
    return app.isHundredDayPlan ||
        app.isLocked ||
        app.usedMinutes >= app.effectiveLimitMinutes;
  }

  Future<void> _confirmDelete(MonitoredApp app) async {
    final isAuthorized = await _requestManagementAuthorization(
      app,
      actionLabel: '删除监控应用',
    );
    if (!isAuthorized || !mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除监控'),
        content: Text('确认要删除 ${app.appName} 的监控吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _backendService.removeApp(app.id);
              if (!mounted) {
                return;
              }
              navigator.pop();
              await _loadApps();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureMonitoringPermissionsAssigned() async {
    final hasUsagePermission =
        await _backendService.isUsageStatsPermissionGranted();
    final hasAccessibilityPermission =
        await _backendService.isAccessibilityPermissionGranted();
    final hasOverlayPermission =
        await _backendService.isOverlayPermissionGranted();

    final missingPermissions = <String>[
      if (!hasUsagePermission) '使用统计权限',
      if (!hasAccessibilityPermission) '无障碍权限',
      if (!hasOverlayPermission) '悬浮窗权限',
    ];

    if (missingPermissions.isEmpty) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('请先完成权限配置'),
            content: Text(
              '添加监控应用前，需要先开启以下权限：\n${missingPermissions.map((item) => '• $item').join('\n')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('暂不添加'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('去配置'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldOpenSettings || !mounted) {
      return false;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SystemPermissionsPage()),
    );

    final recheckedUsage = await _backendService.isUsageStatsPermissionGranted();
    final recheckedAccessibility =
        await _backendService.isAccessibilityPermissionGranted();
    final recheckedOverlay = await _backendService.isOverlayPermissionGranted();
    final isReady =
        recheckedUsage && recheckedAccessibility && recheckedOverlay;

    if (!isReady && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('关键权限仍未完成，暂时不能添加监控应用')),
      );
    }
    return isReady;
  }

  Future<bool> _ensureAllPermissionHubItemsReady() async {
    final missingPermissions =
        await _backendService.getMissingSystemPermissionHubItems();
    if (missingPermissions.isEmpty || !mounted) {
      return missingPermissions.isEmpty;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('系统权限中枢仍有未开启项：${missingPermissions.join('、')}'),
        action: SnackBarAction(
          label: '去开启',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SystemPermissionsPage()),
            );
          },
        ),
      ),
    );
    return false;
  }

  Future<void> _addApp() async {
    final permissionsReady = await _ensureMonitoringPermissionsAssigned();
    if (!permissionsReady || !mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAppPage(
          excludedPackages: _monitoredApps
              .map((app) => app.packageName)
              .toSet(),
          onAppSelected: (appName, packageName, limitMinutes, installedAt) async {
            await _backendService.addMonitoredApp(
              appName: appName,
              packageName: packageName,
              dailyLimitMinutes: limitMinutes,
              installedAt: installedAt,
            );
            if (!mounted) {
              return;
            }
            navigator.pop();
            await _loadApps();
          },
        ),
      ),
    );
  }

  Future<void> _openAppSettings(MonitoredApp app) async {
    final permissionsReady = await _ensureAllPermissionHubItemsReady();
    if (!permissionsReady || !mounted) {
      return;
    }
    final isAuthorized = await _requestManagementAuthorization(
      app,
      actionLabel: '编辑监控设置',
    );
    if (!isAuthorized || !mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppSettingsPage(
          appName: app.appName,
          packageName: app.packageName,
          planName: app.planName,
          icon: app.icon,
          iconColor: app.iconColor,
          usedMinutes: app.usedMinutes,
          limitMinutes: app.limitMinutes,
          isHundredDayPlan: app.isHundredDayPlan,
          isLocked: app.isLocked,
          onLimitChanged: (newLimit) async {
            await _backendService.updateAppLimit(
              appId: app.id,
              dailyLimitMinutes: newLimit,
            );
            await _loadApps();
          },
          onUnlock: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final extensionMinutes = await _backendService.unlockApp(app.id);
            await _loadApps();
            if (!mounted) {
              return;
            }
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('解锁成功，已延长 $extensionMinutes 分钟可用时长')),
            );
            navigator.pop();
            final launched =
                await _backendService.launchAppByPackage(app.packageName);
            if (!launched) {
              final sentHome = await _backendService.openHomeScreen();
              if (!sentHome) {
                await _backendService.moveGuardianToBackground();
              }
            }
          },
          onDelete: () async {
            final navigator = Navigator.of(context);
            await _backendService.removeApp(app.id);
            if (!mounted) {
              return;
            }
            navigator.pop();
            await _loadApps();
          },
        ),
      ),
    );
  }

  MonitoredApp _toMonitoredApp(
    AppModel app, {
    required Map<String, HundredDayPlanStatus> planStatusById,
  }) {
    final package = app.packageName;
    final activePlanIds = planStatusById.values
        .where((plan) => plan.isActive)
        .map((plan) => plan.planId)
        .toSet();
    final planName =
        app.planId == null ? null : planStatusById[app.planId!]?.planName;
    return MonitoredApp(
      id: app.id,
      appName: app.appName,
      packageName: package,
      planName: planName,
      icon: _resolveIcon(package),
      iconColor: _resolveColor(package),
      usedMinutes: app.usedMinutesToday,
      limitMinutes: _resolveEffectiveLimitMinutes(
        app,
        activePlanIds: activePlanIds,
      ),
      effectiveLimitMinutes: _resolveEffectiveLimitMinutes(
        app,
        activePlanIds: activePlanIds,
      ),
      isHundredDayPlan: app.planId != null,
      isLocked: app.isLocked,
    );
  }

  int _resolveEffectiveLimitMinutes(
    AppModel app, {
    required Set<String> activePlanIds,
  }) {
    final today = _formatDate(DateTime.now());
    if (
      app.unlockLimitOverrideMinutes != null &&
      app.unlockLimitOverrideDate == today
    ) {
      return app.unlockLimitOverrideMinutes!;
    }
    final planId = app.planId;
    if (planId != null && activePlanIds.contains(planId)) {
      return 30;
    }
    return app.dailyLimitMinutes;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  IconData _resolveIcon(String packageName) {
    if (packageName.contains('tencent') || packageName.contains('game')) {
      return Icons.games_outlined;
    }
    if (packageName.contains('ugc') || packageName.contains('video')) {
      return Icons.smart_display_outlined;
    }
    if (packageName.contains('chat') || packageName.contains('qq')) {
      return Icons.chat_bubble_outline;
    }
    return Icons.apps_outlined;
  }

  Color _resolveColor(String packageName) {
    if (packageName.contains('tencent')) {
      return const Color(0xFFE53935);
    }
    if (packageName.contains('ugc') || packageName.contains('video')) {
      return const Color(0xFF1E88E5);
    }
    if (packageName.contains('chat') || packageName.contains('qq')) {
      return const Color(0xFF43A047);
    }
    return AppTheme.primaryColor;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '监控应用',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          IconButton(
            onPressed: _addApp,
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: '搜索应用...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildAppCard(MonitoredApp app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimeCard(
        onTap: () => _openAppSettings(app),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: app.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(app.icon, color: app.iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          if (app.isHundredDayPlan) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7E57C2)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '100天计划',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7E57C2),
                                ),
                              ),
                            ),
                          ],
                          if (app.isLocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '已锁定',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.isHundredDayPlan
                            ? '自律100天规则生效中：每天30分钟，解锁需答100题'
                            : (app.isLocked ? '已达到限制，点按可查看处理方式' : '点按可查看监控设置'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '今日',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                          Text(
                            _formatTime(app.usedMinutes),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '限制',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                          Text(
                            _formatTime(app.limitMinutes),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: '编辑',
                      onTap: () => _openAppSettings(app),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: '删除',
                      color: const Color(0xFFE53935),
                      onTap: () => _confirmDelete(app),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = const Color(0xFF666666),
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
