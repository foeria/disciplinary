import 'package:flutter/material.dart';
import '../../../core/events/app_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/app_list_tile.dart';
import '../settings/theme_page.dart';

/// 首页
class HomePage extends StatefulWidget {
  final Function(int) onSwitchToTab;

  const HomePage({
    super.key,
    required this.onSwitchToTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalBackendService _backendService = LocalBackendService();
  HomeDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    AppEvents.homeRefreshTick.addListener(_onHomeRefreshRequested);
    _loadDashboard();
  }

  @override
  void dispose() {
    AppEvents.homeRefreshTick.removeListener(_onHomeRefreshRequested);
    super.dispose();
  }

  void _onHomeRefreshRequested() {
    if (!mounted) {
      return;
    }
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      await _backendService.syncTodayUsageFromDevice();
      final data = await _backendService.getHomeDashboardData();
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboardData = data;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = '首页数据加载失败，请重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, style: const TextStyle(color: Color(0xFF666666))),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadError = null;
                  });
                  _loadDashboard();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航
            _buildHeader(),
            // 主体内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 环形进度
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    // 今日详情标题
                    _buildSectionTitle('今日详情'),
                    const SizedBox(height: 12),
                    // 应用列表
                    _buildAppList(),
                    const SizedBox(height: 24),
                    // 快捷操作
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '自律守护者',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '保持内心平静，专注当下 ~',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onSwitchToTab(3),
                icon: const Icon(Icons.settings_outlined),
                color: const Color(0xFF666666),
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemePage()),
                  );
                  if (!mounted) {
                    return;
                  }
                  setState(() {});
                },
                icon: const Icon(Icons.palette_outlined),
                color: const Color(0xFF666666),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final apps = _dashboardData?.apps ?? const <HomeAppOverview>[];
    final normal = _dashboardData?.normalCount ?? 0;
    final warning = _dashboardData?.warningCount ?? 0;
    final locked = _dashboardData?.lockedCount ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '应用使用概览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '共 ${apps.length} 个应用',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 状态概要三小卡
          Row(
            children: [
              _buildStatusChip('正常', normal, const Color(0xFF43A047)),
              const SizedBox(width: 10),
              _buildStatusChip('即将触限', warning, const Color(0xFFFF9800)),
              const SizedBox(width: 10),
              _buildStatusChip('已锁定', locked, const Color(0xFFE53935)),
            ],
          ),
          const SizedBox(height: 20),
          // 每个应用独立进度条
          ...apps.map((app) => _buildMiniAppProgress(app)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAppProgress(HomeAppOverview app) {
    final usedMinutes = app.app.usedMinutesToday;
    final limitMinutes = app.app.dailyLimitMinutes;
    final progress = app.progress.clamp(0.0, 1.0);
    final isLocked = app.status == AppHealthStatus.locked;
    final isWarning = app.status == AppHealthStatus.warning;
    final barColor = isLocked
        ? const Color(0xFFE53935)
        : isWarning
            ? const Color(0xFFFF9800)
            : const Color(0xFF43A047);
    final usedH = usedMinutes ~/ 60;
    final usedM = usedMinutes % 60;
    final limH = limitMinutes ~/ 60;
    final limM = limitMinutes % 60;
    final usedStr = usedH > 0 ? '${usedH}h${usedM}m' : '${usedM}m';
    final limStr = limH > 0 ? '${limH}h${limM}m' : '${limM}m';
    final iconColor = _resolveColor(app.app.packageName);
    final icon = _resolveIcon(app.app.packageName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  app.app.appName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Text(
                '$usedStr / $limStr',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLocked ? '已锁定' : isWarning ? '即将触限' : '正常',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
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

  Widget _buildAppList() {
    final apps = _dashboardData?.apps ?? const <HomeAppOverview>[];
    if (apps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          '暂无监控应用，去“应用”页面添加后即可展示统计。',
          style: TextStyle(color: Color(0xFF666666), fontSize: 14),
        ),
      );
    }

    return Column(
      children: apps.map((app) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppListTile(
            appName: app.app.appName,
            packageName: app.app.packageName,
            icon: _resolveIcon(app.app.packageName),
            iconColor: _resolveColor(app.app.packageName),
            usedMinutes: app.app.usedMinutesToday,
            limitMinutes: app.app.dailyLimitMinutes,
            isLocked: app.status == AppHealthStatus.locked,
            onTap: () {
              // TODO: 跳转到应用详情
            },
          ),
        );
      }).toList(),
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
    return const Color(0xFFFF6B9D);
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.bar_chart_outlined,
            label: '统计',
            color: const Color(0xFF7EB8DA),
            onTap: () => widget.onSwitchToTab(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.lock_outline,
            label: '紧急锁定',
            color: const Color(0xFFE53935),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('紧急锁定'),
                  content: const Text('确认要立即锁定所有监控应用吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        await _backendService.lockAllApps();
                        if (!mounted) {
                          return;
                        }
                        navigator.pop();
                        await _loadDashboard();
                        AppEvents.notifyHomeRefresh();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('已锁定所有监控应用'),
                            backgroundColor: Color(0xFFE53935),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
                      child: const Text('锁定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
