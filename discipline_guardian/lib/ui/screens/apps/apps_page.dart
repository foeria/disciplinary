import 'package:flutter/material.dart';
import '../../../core/events/app_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_model.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import '../lock/lock_screen.dart';
import 'add_app_page.dart';
import 'app_settings_page.dart';

/// 应用数据模型
class MonitoredApp {
  final String id;
  final String appName;
  final String packageName;
  final IconData icon;
  final Color iconColor;
  final int usedMinutes;
  final int limitMinutes;
  final bool isLocked;

  const MonitoredApp({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.icon,
    required this.iconColor,
    required this.usedMinutes,
    required this.limitMinutes,
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
    if (!mounted) {
      return;
    }
    setState(() {
      _monitoredApps
        ..clear()
        ..addAll(apps.map(_toMonitoredApp));
      _isLoading = false;
    });
    AppEvents.notifyHomeRefresh();
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
          limitMinutes: app.limitMinutes,
          unlockMethod: UnlockMethod.question,
          titleText: '需要验证',
          reasonText: '$actionLabel前请先完成验证',
          onUnlockSuccess: () async {
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

  void _addApp() {
    final navigator = Navigator.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAppPage(
          onAppSelected: (appName, packageName, limitMinutes) async {
            await _backendService.addMonitoredApp(
              appName: appName,
              packageName: packageName,
              dailyLimitMinutes: limitMinutes,
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
          icon: app.icon,
          iconColor: app.iconColor,
          usedMinutes: app.usedMinutes,
          limitMinutes: app.limitMinutes,
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

  MonitoredApp _toMonitoredApp(AppModel app) {
    final package = app.packageName;
    return MonitoredApp(
      id: app.id,
      appName: app.appName,
      packageName: package,
      icon: _resolveIcon(package),
      iconColor: _resolveColor(package),
      usedMinutes: app.usedMinutesToday,
      limitMinutes: app.dailyLimitMinutes,
      isLocked: app.isLocked,
    );
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
                          Text(
                            app.appName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
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
                      const SizedBox(height: 4),
                      Text(
                        app.packageName,
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
